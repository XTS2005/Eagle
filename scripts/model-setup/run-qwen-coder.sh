#!/bin/bash

# Qwen 2.5 Coder 7B Interactive Shell
# Provides an easy interface to interact with the model

set -e

MODEL_NAME="qwen2.5-coder:7b-abliterated"
API_ENDPOINT="http://localhost:11434"

# Color codes
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check if Ollama is running
check_ollama() {
    if ! curl -s "${API_ENDPOINT}/api/tags" > /dev/null 2>&1; then
        echo -e "${RED}❌ Ollama is not running on ${API_ENDPOINT}${NC}"
        echo "Start Ollama with: ollama serve"
        exit 1
    fi
}

# Check if model is available
check_model() {
    if ! curl -s "${API_ENDPOINT}/api/tags" | grep -q "qwen2.5-coder"; then
        echo -e "${RED}❌ Model ${MODEL_NAME} not found${NC}"
        echo "Install with: bash scripts/model-setup/install-qwen-coder.sh"
        exit 1
    fi
}

# Interactive mode
interactive_mode() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}Qwen 2.5 Coder 7B Interactive${NC}"
    echo -e "${BLUE}================================${NC}"
    echo ""
    echo -e "${GREEN}Model: ${MODEL_NAME}${NC}"
    echo -e "${GREEN}API: ${API_ENDPOINT}${NC}"
    echo ""
    echo "Type your code-related questions or prompts:"
    echo "(Type 'exit' or 'quit' to exit)"
    echo ""

    while true; do
        read -p "You: " -r prompt

        if [[ "$prompt" == "exit" ]] || [[ "$prompt" == "quit" ]]; then
            echo -e "${GREEN}Goodbye!${NC}"
            break
        fi

        if [[ -z "$prompt" ]]; then
            continue
        fi

        echo ""
        echo -e "${BLUE}Qwen:${NC}"
        ollama run "${MODEL_NAME}" "$prompt"
        echo ""
    done
}

# CLI mode - accept prompt as argument
cli_mode() {
    local prompt="$1"
    ollama run "${MODEL_NAME}" "$prompt"
}

# Main
main() {
    check_ollama
    check_model

    if [ $# -eq 0 ]; then
        # Interactive mode
        interactive_mode
    else
        # CLI mode - pass all arguments as prompt
        cli_mode "$*"
    fi
}

main "$@"
