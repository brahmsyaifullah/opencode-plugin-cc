---
description: Ask Opencode a question about the codebase or any coding topic (foreground, answer returns inline)
argument-hint: <question>
---

Ask Opencode a question. Opencode has access to the current working directory and can read files, search code, and answer in detail.

Execute:

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/opencode-bridge.sh" run "$ARGUMENTS"
```

Then relay Opencode's answer to the user. Add your own assessment only if you disagree or can add something material.

Notes:
- Use this for questions with short-to-medium answers. For large multi-step coding tasks use `/opencode:delegate` instead (it runs in the background and keeps this session's context small).
- If the command fails with "Opencode CLI not found", tell the user to run `/opencode:setup`.
