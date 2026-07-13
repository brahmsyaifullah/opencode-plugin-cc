---
description: Verify Opencode is installed, authenticated, and ready
---

Run the diagnostic:

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/ensure-opencode.sh" true
```

Then report to the user what is ready and what needs attention.

If Opencode is NOT installed, offer these options:
- **curl (recommended)**: `curl -fsSL https://opencode.ai/install | bash`
- **npm**: `npm i -g opencode-ai@latest`
- **Homebrew**: `brew install anomalyco/tap/opencode`

If authentication is missing, the user must run `opencode auth login` themselves (interactive — suggest they type `! opencode auth login` in the prompt).

Optional configuration to mention:
- Default model: set `"model": "provider/model"` in `~/.config/opencode/opencode.jsonc` (list available models with `opencode models`), or export `OPENCODE_MODEL` in the shell.
