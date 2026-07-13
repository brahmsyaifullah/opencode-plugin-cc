# opencode-plugin-cc

Use [Opencode](https://opencode.ai) from inside [Claude Code](https://claude.ai/code): delegate coding tasks as **background jobs**, get second-model code reviews, and ask questions — without inflating your Claude Code context window.

Inspired by [codex-plugin-cc](https://github.com/openai/codex-plugin-cc), built on Opencode's richer CLI: resumable sessions, transcript export, multi-provider models (Anthropic, OpenAI, Google, Z.AI, local, …), and an optional headless server.

## Why

Claude Code is great at orchestrating work — but every long task it runs inline burns its own context window. This plugin hands the heavy lifting to Opencode:

- **Your session stays free.** Delegation returns a job ID in three lines; Claude is notified automatically when the job finishes.
- **Your context stays small.** Results come back as a compact summary (status + session ID + log tail). Full transcripts stay on disk until you actually need them.
- **A second model's perspective.** Run reviews and implementations on a different model than the one orchestrating, on your own Opencode provider setup.

## Commands

| Command | Description |
|---------|-------------|
| `/opencode:setup` | Verify Opencode is installed, authenticated, and ready |
| `/opencode:ask` | Ask Opencode a question (foreground, inline answer) |
| `/opencode:review` | Code review of pending changes (read-only; diff via temp file) |
| `/opencode:delegate` | Hand off a coding task as a background job with auto-notification |
| `/opencode:status` | List background jobs + recent Opencode sessions |
| `/opencode:result` | Fetch a job's result (status, session ID, log tail) |
| `/opencode:cancel` | Kill a running background job |
| `/opencode:serve` | Manage the optional headless server (start/stop/status) |

Plus the `opencode-worker` subagent: delegates, waits, **verifies the work** (git diff, tests), and reports back compactly.

## Requirements

- [Claude Code](https://claude.ai/code) with plugin support
- [Opencode](https://opencode.ai) CLI **≥ 1.17** — `curl -fsSL https://opencode.ai/install | bash`
- A provider configured in Opencode — `opencode auth login`
- macOS or Linux (bash, git; `jq` optional but recommended)

## Install

```
/plugin marketplace add brahmsyaifullah/opencode-plugin-cc
/plugin install opencode@opencode-marketplace
```

Then verify:

```
/opencode:setup
```

## Usage

```
/opencode:ask How does this project's build system work?
/opencode:review main
/opencode:delegate Fix the failing tests in src/auth — run `npm test` to verify
```

A delegation looks like this:

```
> /opencode:delegate Refactor the database pool to use lazy connections

  JOB_ID: oc-20260713-231632-18274
  Task delegated to Opencode in background.

  I'll report back when it completes. (Claude's context stays free —
  the job's full transcript never enters the conversation.)

  … later, automatically …

  Opencode finished: pool.ts and config.ts modified, `npm test` passing.
  Session ses_0a3bb… available for follow-ups.
```

Follow-up work continues Opencode's own session (`-s <session-id>`), so nothing needs re-explaining.

## Automatic Delegation (no slash command)

The worker agent and delegate skill carry proactive trigger descriptions, so orchestrator models can delegate on their own. The decision rule they encode:

> Can the task be written as a **self-contained spec** — files to touch, expected behavior, and a verification command? If yes, delegate; if it needs iterative judgment or conversation context, keep it inline.

For near-deterministic routing, add the same rule to your `CLAUDE.md`:

```markdown
## Opencode delegation policy
Before starting implementation work, ask: can I write a SELF-CONTAINED spec for it —
files to touch, expected behavior, and a verification command?
- YES → delegate to the opencode-worker agent instead of implementing inline.
- NO (needs iterative judgment or conversation context) → keep inline.
Keep orchestration, review, and verification in the main session.
```

LLM routing is never 100% guaranteed, but a binary yes/no rule like this gets very high compliance.

## Context-Window Strategy

1. **Delegate = background job.** `/opencode:delegate` returns a `JOB_ID` immediately; a backgrounded `wait` notifies Claude when the job finishes. No polling, zero context cost while it runs.
2. **Results come back compact.** Status + session ID + log tail — not the full transcript.
3. **Full history stays on disk.** Job logs in `~/.claude/opencode-jobs/<job-id>/`; complete transcripts via `opencode export <session-id>`, pulled into context only when needed.
4. **Diffs never enter context.** `/opencode:review` writes the diff to a temp file and attaches it with `-f`.
5. **Follow-ups reuse Opencode's memory.** Resume with `-s <session-id>` instead of re-explaining.

## Architecture

```
Claude Code
  └─ /opencode:* commands, opencode-worker agent
       ├─ scripts/opencode-bridge.sh
       │    ├─ run      → opencode run --auto "prompt"           (foreground)
       │    ├─ delegate → background job → ~/.claude/opencode-jobs/<id>/
       │    │              (pid, prompt.txt, output.log, exit-code)
       │    ├─ review   → git diff → temp file → opencode run -f diff
       │    ├─ wait     → blocks until job done, prints result (notification hook)
       │    └─ status/result/cancel/gc → job dir + opencode session list/export
       └─ scripts/opencode-serve.sh (optional headless server)
            └─ start/stop/status → opencode serve on 127.0.0.1:4096
```

Each job's ID doubles as its Opencode session title — jobs map 1:1 to resumable sessions.

### Server attach mode (optional)

With a headless server running (`/opencode:serve start`), every bridge call attaches automatically (`opencode run --attach <url> --dir <cwd>`): lighter per-call client, shared session state, one warm server instead of a cold CLI per job. No server → transparent fallback to standalone CLI. Both modes fully supported.

- Binds to `127.0.0.1` only; serves all projects (`--dir` pins each task to the caller's cwd).
- Caveat: cancelling in attach mode kills the local client; the server-side session may run to completion.

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `OPENCODE_CMD` | `opencode` | Path to the Opencode CLI |
| `OPENCODE_MODEL` | (Opencode default) | Model as `provider/model`; list with `opencode models` |
| `OPENCODE_JOBS_DIR` | `~/.claude/opencode-jobs` | Background job state |
| `OPENCODE_RESULT_LINES` | `120` | Log lines returned by `result` |
| `OPENCODE_SERVER_PORT` | `4096` | Headless server port |
| `OPENCODE_ATTACH` | (auto) | `off` = force standalone; `<url>` = attach to external server |

Pin a default model for everything Opencode runs in `~/.config/opencode/opencode.jsonc`:

```jsonc
{
  "$schema": "https://opencode.ai/config.json",
  "model": "zai-coding-plan/glm-5.2"
}
```

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `Opencode CLI not found` | Install (see Requirements); the bridge already checks `~/.opencode/bin` |
| `Opencode >= 1.17 required` | `opencode upgrade` |
| Job stuck `running` | `/opencode:cancel <job-id>`, inspect `~/.claude/opencode-jobs/<id>/output.log` |
| Job `failed(N)` | `/opencode:result <job-id>` shows the error tail; auth/model issues surface here |
| Empty answers / auth errors | `opencode auth login`, then `/opencode:setup` |
| Old jobs piling up | Automatic GC removes finished jobs after 7 days; manual: `opencode-bridge.sh gc [days]` |

## Uninstall

```
/plugin uninstall opencode@opencode-marketplace
/plugin marketplace remove opencode-marketplace
```

Job state lives in `~/.claude/opencode-jobs/`, server state in `~/.claude/opencode-server/` — delete them if you want a clean sweep. Opencode itself is untouched.

## Contributing

Issues and PRs welcome at [brahmsyaifullah/opencode-plugin-cc](https://github.com/brahmsyaifullah/opencode-plugin-cc). Validate before submitting:

```
claude plugin validate .
bash -n scripts/*.sh
```

## License

[MIT](LICENSE)
