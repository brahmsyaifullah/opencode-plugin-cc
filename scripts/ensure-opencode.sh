#!/usr/bin/env bash
# ensure-opencode.sh — Check Opencode availability and provide setup guidance

set -euo pipefail

# Opencode's default install location is often missing from non-interactive shells
export PATH="$HOME/.opencode/bin:$PATH"

CHECK_SERVER="${1:-false}"

echo "🔍 Checking Opencode installation..."
echo ""

# Check CLI
if command -v opencode &>/dev/null; then
  VERSION=$(opencode --version 2>/dev/null || echo "unknown")
  echo "✅ Opencode CLI: installed ($VERSION) at $(command -v opencode)"
else
  echo "❌ Opencode CLI: not found"
  echo ""
  echo "Install Opencode with one of these methods:"
  echo "  curl -fsSL https://opencode.ai/install | bash"
  echo "  npm i -g opencode-ai@latest"
  echo "  brew install anomalyco/tap/opencode"
  exit 1
fi

# Check auth
echo ""
echo "🔑 Checking authentication..."
if opencode auth list 2>/dev/null | grep -q "credentials"; then
  opencode auth list 2>/dev/null | sed $'s/\033\\[[0-9;]*m//g'
else
  echo "⚠️  Authentication: not configured"
  echo "  Run: opencode auth login"
fi

# Model config
echo ""
echo "🤖 Model:"
if [[ -n "${OPENCODE_MODEL:-}" ]]; then
  echo "  OPENCODE_MODEL=$OPENCODE_MODEL"
else
  echo "  Using Opencode's default. Pin one via OPENCODE_MODEL env or"
  echo "  \"model\": \"provider/model\" in ~/.config/opencode/opencode.jsonc"
  echo "  (list options: opencode models)"
fi

# Check server (optional)
if [[ "$CHECK_SERVER" == "true" ]]; then
  echo ""
  echo "🖥️  Checking headless server..."
  if curl -s --max-time 2 "${OPENCODE_URL:-http://127.0.0.1:4096}/doc" > /dev/null 2>&1; then
    echo "✅ Headless server: running"
  else
    echo "ℹ️  Headless server: not running"
    echo "  (Optional — the plugin uses CLI mode; start with: opencode serve --port 4096)"
  fi
fi

echo ""
echo "🎉 Opencode is ready to use!"
