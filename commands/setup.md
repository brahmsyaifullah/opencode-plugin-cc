Verify that Opencode is installed and ready to use.

Run this diagnostic check:

1. Check if `opencode` CLI is available:
   ```bash
   command -v opencode && opencode --version
   ```

2. If Opencode is NOT installed, show the user these installation options:
   - **npm**: `npm i -g opencode-ai@latest`
   - **Homebrew (macOS/Linux)**: `brew install anomalyco/tap/opencode`
   - **curl**: `curl -fsSL https://opencode.ai/install | bash`
   - **scoop (Windows)**: `scoop install opencode`

3. If Opencode IS installed, check if a headless server is running:
   ```bash
   curl -s http://127.0.0.1:4096/doc > /dev/null 2>&1 && echo "Opencode server running on port 4096" || echo "No Opencode server running (optional - CLI mode will be used)"
   ```

4. Check authentication status:
   ```bash
   opencode auth list 2>/dev/null || echo "Run 'opencode auth login' to configure API keys"
   ```

5. Report the overall status to the user with a summary of what's ready and what needs setup.
