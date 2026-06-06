#!/usr/bin/env bash
# kmp-skills one-line bootstrap installer for Mac/Linux
# Usage: curl -fsSL https://raw.githubusercontent.com/iammohdzaki/kmp-skills/main/get.sh | bash

set -e

TARGET="${1:-antigravity}"
INSTALL_DIR="${HOME}/.kmp-skills"
REPO_URL="https://github.com/iammohdzaki/kmp-skills.git"

# Colors
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo ""
echo -e "${CYAN}  ============================================${NC}"
echo -e "${CYAN}   kmp-skills  --  KMP AI Skills Installer   ${NC}"
echo -e "${CYAN}   https://github.com/iammohdzaki/kmp-skills ${NC}"
echo -e "${CYAN}  ============================================${NC}"
echo ""

# 1. Check for git
if ! command -v git &> /dev/null; then
    echo -e "${RED}[ERR] git is not installed. Please install git and retry.${NC}"
    exit 1
fi

# 2. Clone or pull
if [ -d "$INSTALL_DIR/.git" ]; then
    echo -e ">> Updating existing repo at $INSTALL_DIR..."
    cd "$INSTALL_DIR"
    git pull || echo -e "${YELLOW}[WARN] git pull failed. Continuing with local version.${NC}"
else
    echo -e ">> Cloning into $INSTALL_DIR..."
    git clone "$REPO_URL" "$INSTALL_DIR"
fi

# 3. Run the installer
INSTALLER_PATH="$INSTALL_DIR/install.sh"
if [ ! -f "$INSTALLER_PATH" ]; then
    echo -e "${RED}[ERR] install.sh not found. Clone may have failed.${NC}"
    exit 1
fi

chmod +x "$INSTALLER_PATH"
echo -e ">> Running installer (Target: $TARGET)..."
"$INSTALLER_PATH" install "$TARGET"

# 4. Add alias to shell profile
ALIAS_CMD="alias kmp-skills='\"$INSTALLER_PATH\"'"
for profile in "$HOME/.bashrc" "$HOME/.zshrc"; do
    if [ -f "$profile" ]; then
        if ! grep -q "alias kmp-skills" "$profile"; then
            echo -e "\n# kmp-skills alias\n$ALIAS_CMD" >> "$profile"
            echo -e "${GREEN}[OK] Added kmp-skills alias to $profile${NC}"
        fi
    fi
done

echo ""
echo -e "${GREEN}  ============================================${NC}"
echo -e "${GREEN}   Install complete!${NC}"
echo -e "${GREEN}  ============================================${NC}"
echo ""
echo "  Restart your terminal or run: source ~/.bashrc (or ~/.zshrc)"
echo "  Then use 'kmp-skills status' to verify."
echo ""
