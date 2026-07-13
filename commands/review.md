---
description: Request a code review from Opencode on pending changes (read-only, diff passed via temp file)
argument-hint: [base-ref]
---

Ask Opencode to review code changes. The diff is written to a temp file and attached — it never inflates this session's context or hits shell argument limits.

Execute:

1. If the user provided a base ref (e.g. `main`), pass it; otherwise review uncommitted + staged changes:

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/opencode-bridge.sh" review $ARGUMENTS
```

2. Relay Opencode's findings to the user, ordered by severity. If Opencode flags something you believe is a false positive, say so and explain why.

Notes:
- This is read-only: the review prompt instructs Opencode not to modify files.
- If there are no pending changes, the script reports "No changes found to review."
