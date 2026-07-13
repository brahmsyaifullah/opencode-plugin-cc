---
description: Delegate a coding task to Opencode as a background job (keeps this session's context window intact). Also use WITHOUT being asked whenever an implementation task can be written as a self-contained spec with a verification command — multi-file changes, refactors, test-fixing runs.
argument-hint: <task description>
---

Delegate a development task to Opencode. Opencode can read files, write code, and run commands. The task runs as a **background job** — this session stays free and its context window stays small.

Steps:

1. Formulate a complete, self-contained prompt from the user's request. Include everything Opencode needs, because it does not share this conversation's context: relevant file paths, error messages, expected behavior, constraints, and how to verify success (e.g. which test command to run).

2. Launch the job (foreground — returns the JOB_ID immediately):

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/opencode-bridge.sh" delegate "<the detailed prompt>"
```

3. Arm the completion notification: run this **with the Bash tool's `run_in_background: true`** so you are notified automatically when the job finishes (zero context cost while it runs — never poll in a loop):

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/opencode-bridge.sh" wait <JOB_ID>
```

4. Tell the user the JOB_ID and that you'll report when it completes. They can also check manually via `/opencode:status` or `/opencode:result <job-id>`.

5. When the notification arrives, the wait output already contains the result (status, session ID, log tail). Summarize it; if files were modified, verify with `git status --short` before reporting success.

Session continuation:
- Continue Opencode's previous session: `... delegate "<prompt>" -c`
- Resume a specific session: `... delegate "<prompt>" -s <session-id>`

Model override: prefix with `OPENCODE_MODEL=<provider/model>` (e.g. `OPENCODE_MODEL=zai-coding-plan/glm-5.2`).

If Opencode is missing, suggest `/opencode:setup`.
