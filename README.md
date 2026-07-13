# opencode-plugin-cc

Use [Opencode](https://opencode.ai) from inside [Claude Code](https://claude.ai/code) to review code, ask questions, or delegate coding tasks to the open source coding agent.

This plugin lets Claude Code delegate work to Opencode **as background jobs**, so your Claude Code session stays responsive and its context window stays small — similar to how [codex-plugin-cc](https://github.com/openai/codex-plugin-cc) integrates OpenAI Codex, but built on Opencode's richer CLI (sessions, export, multi-provider models).

## What You Get

| Command | Description |
|---------|-------------|
| `/opencode:setup` | Verify Opencode is installed, authenticated, and ready |
| `/opencode:ask` | Ask Opencode a question (foreground, inline answer) |
| `/opencode:review` | Code review of pending changes (diff passed via temp file, read-only) |
| `/opencode:delegate` | Hand off a coding task as a **background job** |
| `/opencode:status` | List background jobs + recent Opencode sessions |
| `/opencode:result` | Fetch a job's result (compact: status, session ID, log tail) |
| `/opencode:cancel` | Kill a running background job |
| `/opencode:serve` | Manage the optional headless server (start/stop/status) |

Plus the `opencode-worker` subagent: delegates, polls, **verifies the work** (git diff, tests), and reports back a compact summary.

## Context-Window Strategy

The whole point of this plugin is delegation without context bloat:

1. **Delegate = background job.** `/opencode:delegate` returns a `JOB_ID` immediately; only a few lines enter Claude's context.
2. **Results come back compact.** `/opencode:result` returns status + session ID + the tail of the log, not the full transcript.
3. **Full history stays on disk.** Job logs live in `~/.claude/opencode-jobs/<job-id>/`; complete transcripts via `opencode export <session-id>` — pulled into context only when actually needed.
4. **Diffs never enter context.** `/opencode:review` writes the diff to a temp file and attaches it with `-f`.
5. **Follow-ups reuse Opencode's own memory.** Continue a task with `-s <session-id>` — Opencode remembers its session, so Claude doesn't have to re-explain.

## Requirements

- [Claude Code](https://claude.ai/code) with plugin support
- [Opencode](https://opencode.ai) CLI ≥ 1.17 (`curl -fsSL https://opencode.ai/install | bash`)
- A provider configured in Opencode (`opencode auth login`)

## Install

```
/plugin marketplace add brahmsyaifullah/opencode-plugin-cc
/plugin install opencode@community-opencode
```

Then verify:

```
/opencode:setup
```

## Quick Start

```
/opencode:setup
/opencode:ask How does this project's build system work?
/opencode:review main
/opencode:delegate Fix the failing tests in the auth module
/opencode:status
/opencode:result oc-20260713-171908-5045
```

## Architecture

```
Claude Code
  └─ /opencode:* commands, opencode-worker agent
       └─ scripts/opencode-bridge.sh
            ├─ run      → opencode run --auto "prompt"           (foreground)
            ├─ delegate → background job → ~/.claude/opencode-jobs/<id>/
            │              (pid, prompt.txt, output.log, exit-code)
            ├─ review   → git diff → temp file → opencode run -f diff
            └─ status/result/cancel → job dir + opencode session list/export
       └─ scripts/opencode-serve.sh (optional headless server)
            └─ start/stop/status → opencode serve on 127.0.0.1:4096
```

Each delegated job gets an Opencode session titled with the job ID, so jobs map 1:1 to resumable Opencode sessions.

### Server attach mode (optional)

When a headless server is running (`/opencode:serve start`), every bridge invocation automatically attaches to it (`opencode run --attach <url> --dir <cwd>`): lighter per-call client, shared session state, one warm server process instead of one cold CLI per job. When no server runs, commands fall back to standalone CLI mode transparently — both modes are fully supported.

- The server binds to `127.0.0.1` only and serves all your projects (`--dir` pins each task to the caller's cwd).
- `OPENCODE_ATTACH=off` forces standalone mode; `OPENCODE_ATTACH=<url>` attaches to an external server.
- Caveat: cancelling a job in attach mode kills the local client; the server-side session may still run to completion.

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `OPENCODE_CMD` | `opencode` | Path to the Opencode CLI |
| `OPENCODE_MODEL` | (Opencode default) | Model as `provider/model` (e.g. `zai-coding-plan/glm-5.2`); list with `opencode models` |
| `OPENCODE_JOBS_DIR` | `~/.claude/opencode-jobs` | Where background job state lives |
| `OPENCODE_RESULT_LINES` | `120` | How many log lines `result` returns |
| `OPENCODE_SERVER_PORT` | `4096` | Headless server port |
| `OPENCODE_ATTACH` | (auto) | `off` = force standalone; `<url>` = attach to external server |

To pin a default model for everything Opencode runs, set it in `~/.config/opencode/opencode.jsonc`:

```jsonc
{
  "$schema": "https://opencode.ai/config.json",
  "model": "zai-coding-plan/glm-5.2"
}
```

## License

MIT
