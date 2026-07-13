---
description: Delegate a coding task to Opencode as a background job (keeps this session's context window intact)
argument-hint: <task description>
---

Delegate a development task to Opencode. Opencode can read files, write code, and run commands. The task runs as a **background job** — this session stays free and its context window stays small.

Steps:

1. Formulate a complete, self-contained prompt from the user's request. Include everything Opencode needs, because it does not share this conversation's context: relevant file paths, error messages, expected behavior, constraints, and how to verify success (e.g. which test command to run).

2. Launch the job:

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/opencode-bridge.sh" delegate "<the detailed prompt>"
```

3. Report the `JOB_ID` to the user and tell them the result can be fetched with `/opencode:result <job-id>` (or `/opencode:status` to check progress). Do NOT busy-wait or poll in a loop.

4. If the user asked to wait for the result, check once after a reasonable interval using the status action, then fetch the result.

Session continuation:
- To continue Opencode's previous session, append `-c` after the prompt: `... delegate "<prompt>" -c`
- To resume a specific session: `... delegate "<prompt>" -s <session-id>`

Model override: prefix with `OPENCODE_MODEL=<provider/model>` (e.g. `OPENCODE_MODEL=zai-coding-plan/glm-5.2`).

If Opencode is missing, suggest `/opencode:setup`.
