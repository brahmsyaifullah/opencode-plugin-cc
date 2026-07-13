#!/usr/bin/env bash
# opencode-bridge.sh — Bridge layer between Claude Code and Opencode CLI
# This script translates Claude Code plugin commands into Opencode CLI invocations.

set -euo pipefail

# --- Configuration ---
OPENCODE_CMD="${OPENCODE_CMD:-opencode}"
OPENCODE_SERVER_URL="${OPENCODE_URL:-http://127.0.0.1:4096}"
OPENCODE_MODEL="${OPENCODE_MODEL:-}"

# --- Helper Functions ---
log_info() { echo "[opencode-bridge] $*" >&2; }
log_error() { echo "[opencode-bridge] ERROR: $*" >&2; }

check_opencode() {
  if ! command -v "$OPENCODE_CMD" &>/dev/null; then
    log_error "Opencode CLI not found. Install it with:"
    log_error "  npm i -g opencode-ai@latest"
    log_error "  brew install anomalyco/tap/opencode"
    log_error "  curl -fsSL https://opencode.ai/install | bash"
    return 1
  fi
}

check_server() {
  curl -s --max-time 2 "$OPENCODE_SERVER_URL/doc" > /dev/null 2>&1
}

# --- Main Commands ---
cmd_run() {
  local prompt="$1"
  shift
  local extra_args=("$@")

  check_opencode || exit 1

  local args=(run --auto)

  if [[ -n "$OPENCODE_MODEL" ]]; then
    args+=(--model "$OPENCODE_MODEL")
  fi

  args+=("${extra_args[@]}" "$prompt")

  log_info "Executing: $OPENCODE_CMD ${args[*]}"
  "$OPENCODE_CMD" "${args[@]}"
}

cmd_review() {
  local base_ref="${1:-}"
  local diff_content

  if [[ -n "$base_ref" ]]; then
    diff_content=$(git diff "$base_ref"...HEAD 2>/dev/null || echo "No diff available")
  else
    diff_content="$(git diff 2>/dev/null)$(git diff --staged 2>/dev/null)"
  fi

  if [[ -z "$diff_content" ]]; then
    echo "No changes found to review."
    return 0
  fi

  local review_prompt="You are a senior code reviewer. Review the following code changes thoroughly.
Look for: bugs, security vulnerabilities, performance issues, code style problems, missing error handling, edge cases.
Provide a structured review with severity levels (critical/warning/suggestion) for each finding.

Changes to review:
$diff_content"

  cmd_run "$review_prompt"
}

cmd_status() {
  check_opencode || exit 1

  echo "=== Opencode Sessions ==="
  "$OPENCODE_CMD" session list 2>/dev/null || echo "No sessions found"

  echo ""
  echo "=== Server Status ==="
  if check_server; then
    echo "Headless server running at $OPENCODE_SERVER_URL"
  else
    echo "No headless server running (CLI mode active)"
  fi
}

cmd_export() {
  local session_id="${1:-}"
  check_opencode || exit 1

  if [[ -n "$session_id" ]]; then
    "$OPENCODE_CMD" export "$session_id" 2>/dev/null
  else
    "$OPENCODE_CMD" export 2>/dev/null || echo "No session results available"
  fi
}

# --- Entrypoint ---
main() {
  local action="${1:-help}"
  shift || true

  case "$action" in
    run)      cmd_run "$@" ;;
    review)   cmd_review "$@" ;;
    status)   cmd_status ;;
    export)   cmd_export "$@" ;;
    check)    check_opencode && echo "Opencode is available: $($OPENCODE_CMD --version 2>/dev/null)" ;;
    help)
      echo "Usage: opencode-bridge.sh <action> [args...]"
      echo ""
      echo "Actions:"
      echo "  run <prompt> [flags]   Run a prompt through Opencode"
      echo "  review [base-ref]      Review code changes"
      echo "  status                 Show session and server status"
      echo "  export [session-id]    Export session results"
      echo "  check                  Verify Opencode installation"
      ;;
    *)
      log_error "Unknown action: $action"
      exit 1
      ;;
  esac
}

main "$@"
