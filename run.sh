#!/bin/bash

# ==========================================
# ChatBot - Development Runner
# ==========================================

set -u

# ==========================================
# Project Paths
# ==========================================

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"
APP_DIR="$PROJECT_DIR/app"
APP_FILE="$APP_DIR/streamlit_app.py"

# Local project virtual environment
VENV="$PROJECT_DIR/.venv"

# Logs
OLLAMA_LOG="/tmp/chatbot-ollama.log"
STREAMLIT_LOG="/tmp/chatbot-streamlit.log"

OLLAMA_PID=""
STREAMLIT_PID=""

# ==========================================
# Colors
# ==========================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ==========================================
# Functions
# ==========================================

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

cleanup() {
    echo
    print_info "Stopping ChatBot..."

    if [[ -n "$STREAMLIT_PID" ]] && \
       kill -0 "$STREAMLIT_PID" 2>/dev/null; then
        echo "Stopping Streamlit..."
        kill "$STREAMLIT_PID" 2>/dev/null || true
    fi

    if [[ -n "$OLLAMA_PID" ]] && \
       kill -0 "$OLLAMA_PID" 2>/dev/null; then
        echo "Stopping Ollama..."
        kill "$OLLAMA_PID" 2>/dev/null || true
    fi

    if [[ -n "$STREAMLIT_PID" ]]; then
        wait "$STREAMLIT_PID" 2>/dev/null || true
    fi

    if [[ -n "$OLLAMA_PID" ]]; then
        wait "$OLLAMA_PID" 2>/dev/null || true
    fi

    if [[ -n "${VIRTUAL_ENV:-}" ]]; then
        deactivate 2>/dev/null || true
    fi

    print_success "ChatBot stopped."
    exit 0
}

check_command() {
    if ! command -v "$1" >/dev/null 2>&1; then
        print_error "Required command not found: $1"
        exit 1
    fi
}

# ==========================================
# Signal Handling
# ==========================================

trap cleanup SIGINT SIGTERM EXIT

# ==========================================
# Startup
# ==========================================

clear

echo "=========================================="
echo "              ChatBot"
echo "=========================================="
echo

print_info "Starting ChatBot..."
echo "Project directory: $PROJECT_DIR"

# ==========================================
# Validation
# ==========================================

if [[ ! -d "$PROJECT_DIR" ]]; then
    print_error "Project directory does not exist."
    exit 1
fi

if [[ ! -f "$APP_FILE" ]]; then
    print_error "Streamlit application not found:"
    echo "$APP_FILE"
    exit 1
fi

if [[ ! -f "$VENV/bin/activate" ]]; then
    print_error "Virtual environment not found:"
    echo "$VENV"

    echo
    echo "Create it with:"
    echo "python -m venv .venv"
    echo "source .venv/bin/activate"
    echo "pip install -r requirements.txt"

    exit 1
fi

check_command ollama

# ==========================================
# Virtual Environment
# ==========================================

source "$VENV/bin/activate"

print_success "Virtual environment activated."

echo "Python: $(command -v python)"
echo "Streamlit: $(command -v streamlit)"
echo

# ==========================================
# Ollama
# ==========================================

print_info "Checking Ollama..."

if pgrep -x "ollama" >/dev/null 2>&1; then
    print_warning "Ollama is already running."
else
    print_info "Starting Ollama server..."

    ollama serve >"$OLLAMA_LOG" 2>&1 &
    OLLAMA_PID=$!

    sleep 2

    if ! kill -0 "$OLLAMA_PID" 2>/dev/null; then
        print_error "Ollama failed to start."
        echo
        cat "$OLLAMA_LOG"
        exit 1
    fi

    print_success "Ollama started."
    echo "Ollama PID: $OLLAMA_PID"
fi

# ==========================================
# Streamlit
# ==========================================

print_info "Starting Streamlit..."

cd "$APP_DIR" || {
    print_error "Could not enter app directory."
    exit 1
}

streamlit run "$APP_FILE" \
    >"$STREAMLIT_LOG" 2>&1 &

STREAMLIT_PID=$!

sleep 3

if ! kill -0 "$STREAMLIT_PID" 2>/dev/null; then
    print_error "Streamlit failed to start."
    echo
    cat "$STREAMLIT_LOG"
    exit 1
fi

print_success "Streamlit started."
echo "Streamlit PID: $STREAMLIT_PID"

# ==========================================
# Running Information
# ==========================================

echo
echo "=========================================="
echo "            ChatBot Running"
echo "=========================================="
echo
echo "Project:       $PROJECT_DIR"
echo "Ollama PID:    $OLLAMA_PID"
echo "Streamlit PID: $STREAMLIT_PID"
echo
echo "Streamlit log: $STREAMLIT_LOG"
echo "Ollama log:    $OLLAMA_LOG"
echo
echo "Press Ctrl+C to stop."
echo "Type q and press Enter to stop."
echo

# ==========================================
# Wait for User Command
# ==========================================

while true; do
    read -r command

    case "$command" in
        q|Q|quit|exit)
            cleanup
            ;;
        *)
            echo "Unknown command."
            echo "Use q or Ctrl+C to stop."
            ;;
    esac
done