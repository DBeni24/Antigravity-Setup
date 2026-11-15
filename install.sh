#!/usr/bin/env bash
# ==============================================================================
# Antigravity SOTA Toolkit - Automatikus Telepítő Szkript (Linux / macOS / WSL)
# ==============================================================================
# Használat:
#   chmod +x ./install.sh && ./install.sh
# ==============================================================================

set -euo pipefail

echo -e "\033[1;36m=====================================================================\033[0m"
echo -e "\033[1;36m  🚀 Antigravity SOTA Toolkit Telepítése és Konfigurálása (POSIX)\033[0m"
echo -e "\033[1;36m=====================================================================\033[0m"

CONFIG_DIR="$HOME/.gemini/config"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 1. Célkönyvtárak
echo -e "\n\033[1;33m[1/5] Célkönyvtárak előkészítése ($CONFIG_DIR)...\033[0m"
mkdir -p "$CONFIG_DIR/skills" "$CONFIG_DIR/rules" "$CONFIG_DIR/hooks"

# 2. uv ellenőrzése
echo -e "\n\033[1;33m[2/5] 'uv' ellenőrzése...\033[0m"
if ! command -v uv &> /dev/null; then
    echo "  -> 'uv' telepítése..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.local/bin:$PATH"
else
    echo "  -> 'uv' elérhető: $(uv --version)"
fi

# 3. Node.js ellenőrzése
echo -e "\n\033[1;33m[3/5] Node.js ellenőrzése...\033[0m"
if ! command -v node &> /dev/null; then
    echo -e "\033[1;31m  -> Node.js nem található! Kérlek telepítsd a csomagkezelőddel (pl. nvm, apt, brew).\033[0m"
else
    echo "  -> Node.js elérhető: $(node -v)"
fi

# 4. MCP eszközök telepítése
echo -e "\n\033[1;33m[4/5] MCP Szerverek és Kódintelligencia csomagok...\033[0m"
if command -v npm &> /dev/null; then
    npm install -g @blackwell-systems/agent-lsp || true
fi

if command -v uv &> /dev/null; then
    uv tool install code-index-mcp --python 3.12 --force || true
    uv tool install mcp-server-tree-sitter --python 3.12 --with "mcp<2" --force || true
fi

# 5. Fájlok másolása
echo -e "\n\033[1;33m[5/5] Skillek, Szabályok és MCP konfig másolása...\033[0m"
cp -r "$SCRIPT_DIR/config/skills/"* "$CONFIG_DIR/skills/"
cp -r "$SCRIPT_DIR/config/rules/"* "$CONFIG_DIR/rules/"

# MCP JSON generálása POSIX elérési utakkal
cat <<EOF > "$CONFIG_DIR/mcp_config.json"
{
  "mcpServers": {
    "agent-lsp": {
      "command": "agent-lsp",
      "args": [],
      "env": {
        "AGENT_LSP_LOG_LEVEL": "warn"
      }
    },
    "code-index": {
      "command": "$HOME/.local/bin/code-index-mcp",
      "args": []
    },
    "tree-sitter": {
      "command": "$HOME/.local/bin/mcp-server-tree-sitter",
      "args": []
    },
    "playwright": {
      "command": "npx",
      "args": ["-y", "@playwright/mcp@latest", "--headless"]
    }
  }
}
EOF

echo -e "\n\033[1;32m=====================================================================\033[0m"
echo -e "\033[1;32m  🎉 SIKERES TELEPÍTÉS (POSIX)!\033[0m"
echo -e "\033[1;32m=====================================================================\033[0m"
