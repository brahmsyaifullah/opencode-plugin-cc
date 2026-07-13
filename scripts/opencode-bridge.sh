#!/usr/bin/env bash
# opencode-bridge.sh — Bridge layer between Claude Code and Opencode CLI
#
# Design goals:
#   - Keep Claude Code's context window intact: long-running tasks run as
#     background jobs; only compact summaries/results flow back to Claude.
#   - Full transcripts stay on disk (job logs + `opencode export`).

set -euo pipefail

# --- Configuration ---
# Opencode installs to ~/.opencode/bin which is often missing from
# non-interactive shells (hooks, subagents).
export PATH="$HOME/.opencode/bin:$PATH"

OPENCODE_CMD="${OPENCODE_CMD:-opencode}"
OPENCODE_MODEL="${OPENCODE_MODEL:-}"
JOBS_DIR="${OPENCODE_JOBS_DIR:-$HOME/.claude/opencode-jobs}"
RESULT_TAIL_LINES="${OPENCODE_RESULT_LINES:-120}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# OPENCODE_ATTACH=<url> forces attach mode; OPENCODE_ATTACH=off disables it.
OPENCODE_ATTACH="${OPENCODE_ATTACH:-}"

# --- Helpers ---
log_info() { echo "[opencode-bridge] $*" >&2; }
log_error() { echo "[opencode-bridge] ERROR: $*" >&2; }

strip_ansi() { sed $'s/\033\\[[0-9;]*m//g'; }

MIN_MAJOR=1
MIN_MINOR=17

check_opencode() {
  if ! command -v "$OPENCODE_CMD" &>/dev/null; then
    log_error "Opencode CLI not found. Install it with:"
    log_error "  curl -fsSL https://opencode.ai/install | bash"
    log_error "  npm i -g opencode-ai@latest"
    log_error "  brew install anomalyco/tap/opencode"
    return 1
  fi

  local version major minor
  version=$("$OPENCODE_CMD" --version 2>/dev/null || echo "0.0.0")
  major=${version%%.*}
  minor=${version#*.}; minor=${minor%%.*}
  if (( major < MIN_MAJOR || (major == MIN_MAJOR && minor < MIN_MINOR) )); then
    log_error "Opencode >= $MIN_MAJOR.$MIN_MINOR required (found $version) — needed for --title/--attach/-f."
    log_error "Upgrade: opencode upgrade"
    return 1
  fi
}

attach_url() {
  # Prints the server URL to attach to, if any.
  case "$OPENCODE_ATTACH" in
    off) return 1 ;;
    "")  "$SCRIPT_DIR/opencode-serve.sh" url 2>/dev/null ;;
    *)   echo "$OPENCODE_ATTACH" ;;
  esac
}

build_run_args() {
  # Populates global array RUN_ARGS
  RUN_ARGS=(run --auto)
  if [[ -n "$OPENCODE_MODEL" ]]; then
    RUN_ARGS+=(--model "$OPENCODE_MODEL")
  fi
  # Opportunistic server attach: faster invocations when a headless server
  # is running; standalone CLI otherwise. --dir pins the task to the
  # caller's project, since the server's own cwd is unrelated.
  local url
  if url=$(attach_url) && [[ -n "$url" ]]; then
    RUN_ARGS+=(--attach "$url" --dir "$PWD")
  fi
}

job_session_id() {
  # Session title == job id, so we can map job -> opencode session
  local job_id="$1"
  if command -v jq &>/dev/null; then
    "$OPENCODE_CMD" session list --format json 2>/dev/null \
      | jq -r --arg t "$job_id" 'map(select(.title == $t)) | first | .id // empty'
  else
    "$OPENCODE_CMD" session list 2>/dev/null | strip_ansi \
      | awk -v t="$job_id" '$2 == t { print $1; exit }'
  fi
}

job_status() {
  local job_dir="$1"
  if [[ -f "$job_dir/cancelled" ]]; then
    echo "cancelled"
  elif [[ -f "$job_dir/exit-code" ]]; then
    local code
    code=$(<"$job_dir/exit-code")
    [[ "$code" == "0" ]] && echo "done" || echo "failed($code)"
  elif [[ -f "$job_dir/pid" ]] && kill -0 "$(<"$job_dir/pid")" 2>/dev/null; then
    echo "running"
  elif [[ -f "$job_dir/started" && ! -f "$job_dir/pid" ]]; then
    # delegate forked but the supervisor hasn't written the pid yet
    echo "running"
  else
    echo "dead"
  fi
}

# --- Commands ---

cmd_run() {
  # Foreground run — for short Q&A where the answer should come back inline.
  [[ $# -ge 1 && -n "${1:-}" ]] || { log_error "Usage: run <prompt> [flags]"; exit 1; }
  local prompt="$1"; shift || true
  check_opencode || exit 1
  build_run_args
  # NOTE: message must come BEFORE extra flags — `-f` is an array option and
  # would otherwise swallow the message as a filename.
  "$OPENCODE_CMD" "${RUN_ARGS[@]}" "$prompt" "$@" 2>&1 | strip_ansi
}

cmd_delegate() {
  # Background job — Claude gets a job id back immediately.
  [[ $# -ge 1 && -n "${1:-}" ]] || { log_error "Usage: delegate <prompt> [flags]"; exit 1; }
  local prompt="$1"; shift || true
  check_opencode || exit 1

  cmd_gc 7 > /dev/null 2>&1 || true  # opportunistic cleanup of old jobs

  local job_id="oc-$(date +%Y%m%d-%H%M%S)-$RANDOM"
  local job_dir="$JOBS_DIR/$job_id"
  mkdir -p "$job_dir"
  printf '%s' "$prompt" > "$job_dir/prompt.txt"
  touch "$job_dir/started"

  build_run_args
  RUN_ARGS+=(--title "$job_id")

  (
    # set +e: without it, a non-zero exit from `wait` would kill this
    # supervisor before the exit code is recorded, and failed jobs would
    # show up as "dead" instead of "failed(N)".
    set +e
    # pid file holds the opencode process itself (not this wrapper), so
    # cancel kills the real worker instead of orphaning it.
    "$OPENCODE_CMD" "${RUN_ARGS[@]}" "$(cat "$job_dir/prompt.txt")" "$@" \
      > "$job_dir/output.log" 2>&1 &
    echo $! > "$job_dir/pid"
    wait $!
    echo $? > "$job_dir/exit-code"
  ) 2>/dev/null &
  disown

  echo "JOB_ID: $job_id"
  echo "Task delegated to Opencode in background."
  echo "Check:  opencode-bridge.sh status $job_id"
  echo "Result: opencode-bridge.sh result $job_id"
}

cmd_status() {
  check_opencode || exit 1
  local job_id="${1:-}"

  if [[ -n "$job_id" ]]; then
    local job_dir="$JOBS_DIR/$job_id"
    [[ -d "$job_dir" ]] || { log_error "Unknown job: $job_id"; exit 1; }
    echo "$job_id: $(job_status "$job_dir")"
    return
  fi

  if [[ -d "$JOBS_DIR" ]] && compgen -G "$JOBS_DIR/oc-*" > /dev/null; then
    echo "=== Background Jobs ==="
    local dir
    for dir in "$JOBS_DIR"/oc-*/; do
      local id
      id=$(basename "$dir")
      echo "$id: $(job_status "$dir")"
    done
  else
    echo "No background jobs."
  fi

  echo ""
  echo "=== Server ==="
  "$SCRIPT_DIR/opencode-serve.sh" status

  echo ""
  echo "=== Recent Opencode Sessions ==="
  "$OPENCODE_CMD" session list -n 8 2>/dev/null | strip_ansi || echo "No sessions found"
}

cmd_result() {
  local job_id="${1:-}"
  [[ -n "$job_id" ]] || { log_error "Usage: result <job-id>"; exit 1; }
  local job_dir="$JOBS_DIR/$job_id"
  [[ -d "$job_dir" ]] || { log_error "Unknown job: $job_id"; exit 1; }

  local status
  status=$(job_status "$job_dir")
  echo "STATUS: $status"

  local session_id
  session_id=$(job_session_id "$job_id" || true)
  [[ -n "$session_id" ]] && echo "SESSION: $session_id (resume: opencode run -s $session_id, full log: opencode export $session_id)"

  echo "--- output (last $RESULT_TAIL_LINES lines) ---"
  if [[ -f "$job_dir/output.log" ]]; then
    strip_ansi < "$job_dir/output.log" | tail -n "$RESULT_TAIL_LINES"
  else
    echo "(no output yet)"
  fi
}

cmd_cancel() {
  local job_id="${1:-}"
  [[ -n "$job_id" ]] || { log_error "Usage: cancel <job-id>"; exit 1; }
  local job_dir="$JOBS_DIR/$job_id"
  [[ -d "$job_dir" ]] || { log_error "Unknown job: $job_id"; exit 1; }

  if [[ -f "$job_dir/pid" ]] && kill -0 "$(<"$job_dir/pid")" 2>/dev/null; then
    local pid
    pid=$(<"$job_dir/pid")
    pkill -P "$pid" 2>/dev/null || true   # opencode's own children first
    kill "$pid" 2>/dev/null || true
    touch "$job_dir/cancelled"
    echo "Job $job_id cancelled."
  else
    echo "Job $job_id is not running (status: $(job_status "$job_dir"))."
  fi
}

cmd_wait() {
  # Block until a job reaches a terminal state, then print its result.
  # Meant to run inside a backgrounded shell so the caller gets notified
  # on completion instead of polling.
  local job_id="${1:-}"
  [[ -n "$job_id" ]] || { log_error "Usage: wait <job-id> [timeout-secs]"; exit 1; }
  local timeout_secs="${2:-3600}"
  local job_dir="$JOBS_DIR/$job_id"
  [[ -d "$job_dir" ]] || { log_error "Unknown job: $job_id"; exit 1; }

  local waited=0 interval=5
  while (( waited < timeout_secs )); do
    case "$(job_status "$job_dir")" in
      running) sleep "$interval"; waited=$((waited + interval)) ;;
      *) cmd_result "$job_id"; return ;;
    esac
  done

  log_error "Timed out after ${timeout_secs}s; job still running."
  cmd_result "$job_id"
  exit 1
}

cmd_gc() {
  # Remove job directories older than N days (default 7).
  local days="${1:-7}"
  [[ -d "$JOBS_DIR" ]] || { echo "Nothing to clean."; return 0; }
  local removed=0 dir
  while IFS= read -r dir; do
    # never remove a live job, however old
    [[ "$(job_status "$dir")" == "running" ]] && continue
    rm -rf "$dir"
    removed=$((removed + 1))
  done < <(find "$JOBS_DIR" -maxdepth 1 -type d -name 'oc-*' -mtime "+$days")
  echo "Removed $removed job dir(s) older than $days day(s)."
}

cmd_review() {
  # Diff goes through a temp file (-f attach), never argv — avoids ARG_MAX
  # limits and keeps the huge diff out of Claude's context.
  local base_ref="${1:-}"
  check_opencode || exit 1

  local diff_file
  diff_file=$(mktemp -t opencode-review-XXXXXX.diff)
  # ${diff_file:-} — the trap fires in top-level scope where the local is gone
  trap 'rm -f "${diff_file:-}"' EXIT

  if [[ -n "$base_ref" ]]; then
    git diff "$base_ref"...HEAD > "$diff_file" 2>/dev/null || true
  else
    { git diff; git diff --staged; } > "$diff_file" 2>/dev/null || true
  fi

  if [[ ! -s "$diff_file" ]]; then
    echo "No changes found to review."
    return 0
  fi

  local review_prompt="You are a senior code reviewer. The attached file is a git diff of pending changes in this repository. Review it thoroughly for: bugs and logic errors, security vulnerabilities, performance issues, missing error handling, and edge cases. You may read surrounding files in the repo for context, but DO NOT modify any files. Provide a structured review: each finding gets a severity (CRITICAL/HIGH/MEDIUM/LOW), file:line, one-line problem statement, and a suggested fix. End with a verdict: approve / approve-with-warnings / block."

  build_run_args
  "$OPENCODE_CMD" "${RUN_ARGS[@]}" "$review_prompt" -f "$diff_file" 2>&1 | strip_ansi
}

cmd_check() {
  check_opencode || exit 1
  echo "Opencode: $("$OPENCODE_CMD" --version 2>/dev/null)"
  echo "Model: ${OPENCODE_MODEL:-<opencode default>}"
  local url
  if url=$(attach_url) && [[ -n "$url" ]]; then
    echo "Mode: attached to server at $url"
  else
    echo "Mode: standalone CLI (start a server with /opencode:serve start)"
  fi
  "$OPENCODE_CMD" auth list 2>/dev/null | strip_ansi || echo "Auth: run 'opencode auth login'"
}

# --- Entrypoint ---
main() {
  local action="${1:-help}"
  shift || true

  case "$action" in
    run)      cmd_run "$@" ;;
    delegate) cmd_delegate "$@" ;;
    review)   cmd_review "$@" ;;
    status)   cmd_status "$@" ;;
    result)   cmd_result "$@" ;;
    wait)     cmd_wait "$@" ;;
    cancel)   cmd_cancel "$@" ;;
    gc)       cmd_gc "$@" ;;
    check)    cmd_check ;;
    help)
      echo "Usage: opencode-bridge.sh <action> [args...]"
      echo ""
      echo "Actions:"
      echo "  run <prompt> [flags]     Foreground run (short Q&A)"
      echo "  delegate <prompt> [flags] Background job; returns JOB_ID"
      echo "  review [base-ref]        Review pending changes (or diff vs base-ref)"
      echo "  status [job-id]          Job + session status"
      echo "  result <job-id>          Fetch job result (tail of log + session id)"
      echo "  wait <job-id> [timeout]  Block until job finishes, then print result"
      echo "  cancel <job-id>          Kill a running job"
      echo "  gc [days]                Remove finished job dirs older than N days (default 7)"
      echo "  check                    Verify install + auth"
      ;;
    *)
      log_error "Unknown action: $action"
      exit 1
      ;;
  esac
}

main "$@"
