---
description: Show status of Opencode background jobs and recent sessions
argument-hint: [job-id]
---

Show job and session status.

Execute:

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/opencode-bridge.sh" status $ARGUMENTS
```

Present the output to the user:
- Background jobs with state: `running`, `done`, `failed(N)`, or `dead`
- Recent Opencode sessions (ID, title, updated)

For any `done` job the user cares about, offer `/opencode:result <job-id>`.
