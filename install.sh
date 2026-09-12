#!/bin/bash

# ==========================================
# ChatBot - Linux Installer
# ==========================================

set -e

# ==========================================
# Configuration
# ==========================================

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

APP_NAME="ChatBot"
INSTALL_DIR="/opt/$APP_NAME"
VENV_DIR="$INSTALL_DIR/.venv"
COMMAND_PATH="/usr/bin/$APP_NAME"

PYTHON_BIN="python3"

# ==========================================
# Colors
# ==========================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_error() {
    echo -e "${RED}Error:${NC} $1"
}

print_success() {
    echo -e "${GREEN}$1${NC}"
}

print_info() {
    echo -e "${BLUE}$1${NC}"
}

print_warning() {
    echo -e "${YELLOW}$1${NC}"
}

# ==========================================
# Root Check
# ==========================================

if [[ "$EUID" -eq 0 ]]; then
    print_error "Do not run this installer as root."
    echo "Run it normally:"
    echo "./install.sh"
    exit 1
fi

# ==========================================
# Required Commands
# ==========================================

for command in "$PYTHON_BIN" sudo cp mkdir rm chmod; do
    if ! command -v "$command" >/dev/null 2>&1; then
        print_error "Required command not found: $command"
        exit 1
    fi
done

# ==========================================
# Project Validation
# ==========================================

if [[ ! -f "$SCRIPT_DIR/requirements.txt" ]]; then
    print_error "requirements.txt was not found."
    exit 1
fi

if [[ ! -f "$SCRIPT_DIR/app/streamlit_app.py" ]]; then
    print_error "app/streamlit_app.py was not found."
    exit 1
fi

# ==========================================
# Installation Confirmation
# ==========================================

echo
echo "=========================================="
echo "          ChatBot Installation"
echo "=========================================="
echo
echo "Source directory:"
echo "$SCRIPT_DIR"
echo
echo "Install directory:"
echo "$INSTALL_DIR"
echo
echo "Command:"
echo "$APP_NAME"
echo

read -r -p "Continue installation? [y/N]: " answer

if [[ ! "$answer" =~ ^[Yy]$ ]]; then
    echo "Installation cancelled."
    exit 0
fi

# ==========================================
# Create Installation Directory
# ==========================================

print_info "Creating installation directory..."

sudo mkdir -p "$INSTALL_DIR"

# ==========================================
# Copy Project Files
# ==========================================

print_info "Copying project files..."

sudo cp -r "$SCRIPT_DIR/app" "$INSTALL_DIR/"
sudo cp -r "$SCRIPT_DIR/src" "$INSTALL_DIR/" 2>/dev/null || true
sudo cp -r "$SCRIPT_DIR/bots" "$INSTALL_DIR/" 2>/dev/null || true
sudo cp -r "$SCRIPT_DIR/generated" "$INSTALL_DIR/" 2>/dev/null || true

sudo cp "$SCRIPT_DIR/requirements.txt" "$INSTALL_DIR/"

if [[ -f "$SCRIPT_DIR/.env.example" ]]; then
    sudo cp "$SCRIPT_DIR/.env.example" "$INSTALL_DIR/"
fi

# ==========================================
# Python Virtual Environment
# ==========================================

print_info "Creating Python virtual environment..."

if [[ ! -f "$VENV_DIR/bin/activate" ]]; then
    sudo "$PYTHON_BIN" -m venv "$VENV_DIR"
fi

VENV_PYTHON="$VENV_DIR/bin/python"
VENV_PIP="$VENV_DIR/bin/pip"

print_info "Installing Python dependencies..."

sudo "$VENV_PIP" install --upgrade pip
sudo "$VENV_PIP" install -r "$INSTALL_DIR/requirements.txt"

# ==========================================
# Permissions
# ==========================================

print_info "Configuring permissions..."

sudo chown -R root:root "$INSTALL_DIR"
sudo chmod -R a+rX "$INSTALL_DIR"

# Allow the current user to write runtime folders
if [[ -d "$INSTALL_DIR/bots" ]]; then
    sudo chown -R "$USER:$USER" "$INSTALL_DIR/bots"
fi

if [[ -d "$INSTALL_DIR/generated" ]]; then
    sudo chown -R "$USER:$USER" "$INSTALL_DIR/generated"
fi

# ==========================================
# Create Global Launcher
# ==========================================

print_info "Creating global command: $APP_NAME"

sudo tee "$COMMAND_PATH" >/dev/null <<EOF
#!/bin/bash

set -u

INSTALL_DIR="$INSTALL_DIR"
VENV_PYTHON="\$INSTALL_DIR/.venv/bin/python"
STREAMLIT_APP="\$INSTALL_DIR/app/streamlit_app.py"

OLLAMA_LOG="/tmp/chatbot-ollama.log"
STREAMLIT_LOG="/tmp/chatbot-streamlit.log"

OLLAMA_PID=""
STREAMLIT_PID=""

cleanup() {
    echo
    echo "Stopping ChatBot..."

    if [[ -n "\$STREAMLIT_PID" ]] && kill -0 "\$STREAMLIT_PID" 2>/dev/null; then
        kill "\$STREAMLIT_PID" 2>/dev/null || true
    fi

    if [[ -n "\$OLLAMA_PID" ]] && kill -0 "\$OLLAMA_PID" 2>/dev/null; then
        kill "\$OLLAMA_PID" 2>/dev/null || true
    fi

    wait "\$STREAMLIT_PID" 2>/dev/null || true
    wait "\$OLLAMA_PID" 2>/dev/null || true

    echo "ChatBot stopped."
    exit 0
}

trap cleanup SIGINT SIGTERM EXIT

if [[ ! -x "\$VENV_PYTHON" ]]; then
    echo "Python virtual environment not found:"
    echo "\$VENV_PYTHON"
    exit 1
fi

if ! command -v ollama >/dev/null 2>&1; then
    echo "Ollama is not installed or not available in PATH."
    exit 1
fi

cd "\$INSTALL_DIR" || exit 1

echo "Starting Ollama..."

if pgrep -x "ollama" >/dev/null 2>&1; then
    echo "Ollama is already running."
else
    ollama serve >"\$OLLAMA_LOG" 2>&1 &
    OLLAMA_PID=\$!

    sleep 2

    if ! kill -0 "\$OLLAMA_PID" 2>/dev/null; then
        echo "Ollama failed to start."
        cat "\$OLLAMA_LOG"
        exit 1
    fi
fi

echo "Starting Streamlit..."

"\$VENV_PYTHON" -m streamlit run "\$STREAMLIT_APP" \
    >"\$STREAMLIT_LOG" 2>&1 &

STREAMLIT_PID=\$!

sleep 3

if ! kill -0 "\$STREAMLIT_PID" 2>/dev/null; then
    echo "Streamlit failed to start."
    cat "\$STREAMLIT_LOG"
    exit 1
fi

echo
echo "======================================"
echo "          ChatBot Running"
echo "======================================"
echo
echo "Streamlit log: \$STREAMLIT_LOG"
echo "Ollama log:    \$OLLAMA_LOG"
echo
echo "Press Ctrl+C to quit."
echo "Type q and press Enter to quit."
echo

while true; do
    read -r command

    case "\$command" in
        q|Q|quit|exit)
            cleanup
            ;;
        *)
            echo "Unknown command. Use q or Ctrl+C."
            ;;
    esac
done
EOF

sudo chmod +x "$COMMAND_PATH"

# ==========================================
# Finished
# ==========================================

echo
print_success "ChatBot installed successfully."
echo
echo "Installed at:"
echo "$INSTALL_DIR"
echo
echo "Run it with:"
echo "$APP_NAME"
echo
echo "To uninstall:"
echo "./uninstall.sh"