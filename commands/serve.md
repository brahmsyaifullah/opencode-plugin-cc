---
description: Manage the Opencode headless server (start/stop/status) for faster delegation
argument-hint: start | stop | status
---

Manage the optional Opencode headless server. When it runs, all plugin commands automatically attach to it (faster invocations, shared session state); when it does not, they fall back to standalone CLI mode. Both modes are fully functional.

Execute (default action is `status`):

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/opencode-serve.sh" $ARGUMENTS
```

Report the outcome to the user.

Notes:
- The server binds to 127.0.0.1 only. Port defaults to 4096 (`OPENCODE_SERVER_PORT` to change).
- Server log: `~/.claude/opencode-server/server.log`.
- Caveat: cancelling a job in attach mode kills the local client; the server-side session may finish on its own. Check `/opencode:status` afterwards if that matters.
- `OPENCODE_ATTACH=off` forces standalone CLI mode; `OPENCODE_ATTACH=<url>` attaches to an external server.
