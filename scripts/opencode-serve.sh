#!/usr/bin/env bash
# opencode-serve.sh — Lifecycle manager for the Opencode headless server
#
# The server is opt-in: the bridge attaches to it opportunistically when it
# is running (faster invocations, shared session state) and falls back to
# standalone CLI mode when it is not.

set -euo pipefail

export PATH="$HOME/.opencode/bin:$PATH"

OPENCODE_CMD="${OPENCODE_CMD:-opencode}"
SERVER_PORT="${OPENCODE_SERVER_PORT:-4096}"
SERVER_HOST="127.0.0.1"
SERVER_URL="http://$SERVER_HOST:$SERVER_PORT"
STATE_DIR="${OPENCODE_SERVER_STATE_DIR:-$HOME/.claude/opencode-server}"
PID_FILE="$STATE_DIR/pid"
LOG_FILE="$STATE_DIR/server.log"
HEALTH_TIMEOUT_SECS=15

log_error() { echo "[opencode-serve] ERROR: $*" >&2; }

is_healthy() {
  curl -s --max-time 2 "$SERVER_URL/doc" > /dev/null 2>&1
}

server_pid() {
  [[ -f "$PID_FILE" ]] && cat "$PID_FILE" || true
}

is_running() {
  local pid
  pid=$(server_pid)
  [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null
}

cmd_start() {
  if ! command -v "$OPENCODE_CMD" &>/dev/null; then
    log_error "Opencode CLI not found. Run /opencode:setup first."
    exit 1
  fi

  if is_healthy; then
    echo "Server already running at $SERVER_URL"
    return 0
  fi

  mkdir -p "$STATE_DIR"
  nohup "$OPENCODE_CMD" serve --port "$SERVER_PORT" --hostname "$SERVER_HOST" \
    > "$LOG_FILE" 2>&1 &
  echo $! > "$PID_FILE"
  disown

  local waited=0
  while (( waited < HEALTH_TIMEOUT_SECS )); do
    if is_healthy; then
      echo "Server started at $SERVER_URL (pid $(server_pid), log: $LOG_FILE)"
      return 0
    fi
    sleep 1
    waited=$((waited + 1))
  done

  log_error "Server did not become healthy within ${HEALTH_TIMEOUT_SECS}s. Log tail:"
  tail -5 "$LOG_FILE" >&2 || true
  exit 1
}

cmd_stop() {
  local pid
  pid=$(server_pid)
  if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
    kill "$pid" 2>/dev/null || true
    rm -f "$PID_FILE"
    echo "Server stopped (pid $pid)."
  elif is_healthy; then
    echo "A server responds at $SERVER_URL but was not started by this script — not touching it."
  else
    rm -f "$PID_FILE"
    echo "No server running."
  fi
}

cmd_status() {
  if is_healthy; then
    local pid
    pid=$(server_pid)
    echo "Server: running at $SERVER_URL${pid:+ (pid $pid)}"
  else
    echo "Server: not running (bridge uses standalone CLI mode)"
    echo "Start with: opencode-serve.sh start"
  fi
}

cmd_url() {
  # Machine-readable: prints the URL iff a healthy server is reachable.
  if is_healthy; then
    echo "$SERVER_URL"
  else
    return 1
  fi
}

main() {
  local action="${1:-status}"
  case "$action" in
    start)  cmd_start ;;
    stop)   cmd_stop ;;
    status) cmd_status ;;
    url)    cmd_url ;;
    *)
      echo "Usage: opencode-serve.sh {start|stop|status|url}"
      exit 1
      ;;
  esac
}

main "$@"
