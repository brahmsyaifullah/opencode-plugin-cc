#!/usr/bin/env bash
# ensure-opencode.sh — Check Opencode availability and provide setup guidance

set -euo pipefail

CHECK_SERVER="${1:-false}"

echo "🔍 Checking Opencode installation..."
echo ""

# Check CLI
if command -v opencode &>/dev/null; then
  VERSION=$(opencode --version 2>/dev/null || echo "unknown")
  echo "✅ Opencode CLI: installed ($VERSION)"
else
  echo "❌ Opencode CLI: not found"
  echo ""
  echo "Install Opencode with one of these methods:"
  echo "  npm i -g opencode-ai@latest"
  echo "  brew install anomalyco/tap/opencode"
  echo "  curl -fsSL https://opencode.ai/install | bash"
  exit 1
fi

# Check auth
echo ""
echo "🔑 Checking authentication..."
if opencode auth list &>/dev/null; then
  echo "✅ Authentication: configured"
else
  echo "⚠️  Authentication: not configured"
  echo "  Run: opencode auth login"
fi

# Check server (optional)
if [[ "$CHECK_SERVER" == "true" ]]; then
  echo ""
  echo "🖥️  Checking headless server..."
  if curl -s --max-time 2 http://127.0.0.1:4096/doc > /dev/null 2>&1; then
    echo "✅ Headless server: running on port 4096"
  else
    echo "ℹ️  Headless server: not running"
    echo "  Start with: opencode serve"
    echo "  (Optional — CLI mode works without server)"
  fi
fi

echo ""
echo "🎉 Opencode is ready to use!"
