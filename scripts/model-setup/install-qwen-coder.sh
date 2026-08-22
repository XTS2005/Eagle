#!/bin/bash

# Qwen 2.5 Coder 7B (Abliterated) Installation Script
# This script sets up and configures Qwen 2.5 Coder 7B locally using Ollama

set -e

echo "================================"
echo "Qwen 2.5 Coder 7B Installer"
echo "================================"
echo ""

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if Ollama is installed
check_ollama() {
    if ! command -v ollama &> /dev/null; then
        echo -e "${RED}❌ Ollama is not installed${NC}"
        echo "Install Ollama from: https://ollama.ai"
        return 1
    fi
    echo -e "${GREEN}✓ Ollama found${NC}"
    return 0
}

# Check if Ollama daemon is running
check_ollama_running() {
    if ! pgrep -x "ollama" > /dev/null; then
        echo -e "${YELLOW}⚠ Ollama daemon is not running${NC}"
        echo "Starting Ollama daemon..."
        ollama serve &
        sleep 2
    fi
    echo -e "${GREEN}✓ Ollama daemon is running${NC}"
}

# Download and configure Qwen 2.5 Coder 7B
install_qwen_coder() {
    echo ""
    echo "Pulling Qwen 2.5 Coder 7B (Abliterated)..."
    echo "This may take a few minutes depending on your connection..."
    echo ""

    # Using the abliterated/uncensored version
    ollama pull qwen2.5-coder:7b-abliterated

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Qwen 2.5 Coder 7B installed successfully${NC}"
    else
        echo -e "${RED}❌ Failed to pull Qwen 2.5 Coder 7B${NC}"
        return 1
    fi
}

# Verify installation
verify_installation() {
    echo ""
    echo "Verifying installation..."

    # Test the model
    echo "Test prompt: 'function hello() {'" | ollama run qwen2.5-coder:7b-abliterated

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Installation verified successfully${NC}"
    else
        echo -e "${RED}❌ Installation verification failed${NC}"
        return 1
    fi
}

# Main execution
main() {
    check_ollama || exit 1
    check_ollama_running
    install_qwen_coder || exit 1
    verify_installation || exit 1

    echo ""
    echo -e "${GREEN}================================${NC}"
    echo -e "${GREEN}Installation Complete! 🎉${NC}"
    echo -e "${GREEN}================================${NC}"
    echo ""
    echo "Model Information:"
    echo "  Name: Qwen 2.5 Coder 7B (Abliterated)"
    echo "  Type: Code Generation & Completion"
    echo "  Size: ~4GB (quantized)"
    echo ""
    echo "To use the model:"
    echo "  1. Keep Ollama running: ollama serve"
    echo "  2. In another terminal: ollama run qwen2.5-coder:7b-abliterated"
    echo "  3. Or use via API: curl http://localhost:11434/api/generate -d '{\"model\": \"qwen2.5-coder:7b-abliterated\", \"prompt\": \"your prompt\"}'"
    echo ""
    echo "API Endpoint: http://localhost:11434"
    echo "Model: qwen2.5-coder:7b-abliterated"
    echo ""
}

main
