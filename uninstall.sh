#!/bin/bash

# ==========================================
# ChatBot - Linux Uninstaller
# ==========================================

set -e

APP_NAME="ChatBot"
INSTALL_DIR="/opt/$APP_NAME"
COMMAND_PATH="/usr/bin/$APP_NAME"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

if [[ "$EUID" -eq 0 ]]; then
    echo -e "${RED}Do not run uninstall.sh as root.${NC}"
    echo "Run it normally:"
    echo "./uninstall.sh"
    exit 1
fi

echo
echo "=========================================="
echo "           ChatBot Uninstaller"
echo "=========================================="
echo
echo "This will remove:"
echo "$INSTALL_DIR"
echo "$COMMAND_PATH"
echo

echo -e "${YELLOW}Warning: installed bots and generated files will also be removed.${NC}"
echo

read -r -p "Continue? [y/N]: " answer

if [[ ! "$answer" =~ ^[Yy]$ ]]; then
    echo "Uninstallation cancelled."
    exit 0
fi

echo "Removing global command..."

if [[ -e "$COMMAND_PATH" ]]; then
    sudo rm -f "$COMMAND_PATH"
fi

echo "Removing installed project..."

if [[ -d "$INSTALL_DIR" ]]; then
    sudo rm -rf "$INSTALL_DIR"
fi

echo
echo -e "${GREEN}ChatBot was uninstalled successfully.${NC}"