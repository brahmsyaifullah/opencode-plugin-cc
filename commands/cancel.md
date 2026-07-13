---
description: Cancel a running Opencode background job
argument-hint: <job-id>
---

Cancel a running background job.

Execute:

1. If a job ID was provided:

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/opencode-bridge.sh" cancel $ARGUMENTS
```

2. If no job ID was given, list jobs first so the user can pick:

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/opencode-bridge.sh" status
```

Confirm the outcome to the user. Note: this kills the local job process; the partial Opencode session remains on disk and can be inspected with `/opencode:status`.
