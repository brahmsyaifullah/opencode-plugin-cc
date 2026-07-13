---
description: Fetch the result of an Opencode background job
argument-hint: <job-id>
---

Fetch a background job's result.

Execute:

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/opencode-bridge.sh" result $ARGUMENTS
```

The output contains:
- `STATUS:` — done / running / failed
- `SESSION:` — the Opencode session ID (usable for resume or full export)
- The tail of the job's output log

Then:
1. Summarize for the user what Opencode did and its final answer. If Opencode modified files, run `git status --short` and list what changed.
2. If the job is still `running`, say so — do not poll in a loop; the user can re-run this command later.
3. If more detail is needed than the log tail shows, the full transcript is available via `opencode export <session-id>` — but only pull it in when actually necessary (it can be large).
4. For follow-up work on the same task, delegate with `-s <session-id>` to continue that Opencode session.
