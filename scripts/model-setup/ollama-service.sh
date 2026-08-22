#!/bin/bash

# Ollama Service Manager
# Manages starting, stopping, and monitoring the Ollama daemon

set -e

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

OLLAMA_HOST="${OLLAMA_HOST:-127.0.0.1:11434}"
PID_FILE="/tmp/ollama.pid"
LOG_FILE="/tmp/ollama.log"

show_usage() {
    cat << EOF
${BLUE}Ollama Service Manager${NC}

Usage: $0 [COMMAND]

Commands:
    start       Start the Ollama daemon
    stop        Stop the Ollama daemon
    restart     Restart the Ollama daemon
    status      Check Ollama status
    logs        Show Ollama logs
    help        Show this help message

Environment Variables:
    OLLAMA_HOST    Set the host:port (default: 127.0.0.1:11434)

Examples:
    $0 start
    OLLAMA_HOST=0.0.0.0:11434 $0 start
    $0 status
    $0 logs

EOF
}

check_installed() {
    if ! command -v ollama &> /dev/null; then
        echo -e "${RED}❌ Ollama is not installed${NC}"
        echo "Install from: https://ollama.ai"
        return 1
    fi
    return 0
}

start_ollama() {
    echo -e "${BLUE}Starting Ollama daemon...${NC}"

    check_installed || return 1

    if is_running; then
        echo -e "${YELLOW}⚠ Ollama is already running (PID: $(cat $PID_FILE))${NC}"
        return 0
    fi

    # Start in background with output redirection
    nohup ollama serve > "$LOG_FILE" 2>&1 &
    local pid=$!
    echo $pid > "$PID_FILE"

    echo "Waiting for Ollama to be ready..."
    sleep 3

    # Check if service is listening
    if is_ready; then
        echo -e "${GREEN}✓ Ollama started successfully (PID: $pid)${NC}"
        echo -e "${GREEN}Host: $OLLAMA_HOST${NC}"
        return 0
    else
        echo -e "${RED}❌ Ollama failed to start${NC}"
        echo "Check logs: tail -f $LOG_FILE"
        rm -f "$PID_FILE"
        return 1
    fi
}

stop_ollama() {
    echo -e "${BLUE}Stopping Ollama daemon...${NC}"

    if [ ! -f "$PID_FILE" ]; then
        if pgrep -x "ollama" > /dev/null; then
            echo -e "${YELLOW}⚠ Ollama is running but PID file not found, killing process...${NC}"
            pkill -f "ollama serve" || true
            echo -e "${GREEN}✓ Ollama stopped${NC}"
        else
            echo -e "${YELLOW}Ollama is not running${NC}"
        fi
        return 0
    fi

    local pid=$(cat "$PID_FILE")

    if kill $pid 2>/dev/null; then
        echo -e "${GREEN}✓ Ollama stopped (PID: $pid)${NC}"
        rm -f "$PID_FILE"
        sleep 1
    else
        echo -e "${RED}Failed to stop Ollama with PID $pid${NC}"
        return 1
    fi
}

restart_ollama() {
    stop_ollama
    sleep 2
    start_ollama
}

is_running() {
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if kill -0 $pid 2>/dev/null; then
            return 0
        fi
    fi

    if pgrep -x "ollama" > /dev/null; then
        return 0
    fi

    return 1
}

is_ready() {
    curl -s "http://${OLLAMA_HOST}/api/tags" > /dev/null 2>&1
}

show_status() {
    if is_running; then
        echo -e "${GREEN}✓ Ollama is running${NC}"

        if is_ready; then
            echo -e "${GREEN}✓ API is responding${NC}"
            echo -e "${GREEN}✓ Endpoint: http://${OLLAMA_HOST}${NC}"

            # Show available models
            echo ""
            echo -e "${BLUE}Available models:${NC}"
            curl -s "http://${OLLAMA_HOST}/api/tags" | grep -o '"name":"[^"]*"' | cut -d'"' -f4 | while read model; do
                echo "  • $model"
            done
        else
            echo -e "${YELLOW}⚠ API is not responding${NC}"
        fi
    else
        echo -e "${YELLOW}Ollama is not running${NC}"
        echo "Start with: $0 start"
    fi
}

show_logs() {
    if [ -f "$LOG_FILE" ]; then
        echo -e "${BLUE}Ollama logs (tail -f):${NC}"
        tail -f "$LOG_FILE"
    else
        echo -e "${YELLOW}No log file found${NC}"
    fi
}

# Main command handling
case "${1:-status}" in
    start)
        start_ollama
        ;;
    stop)
        stop_ollama
        ;;
    restart)
        restart_ollama
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs
        ;;
    help|--help|-h)
        show_usage
        ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        show_usage
        exit 1
        ;;
esac
