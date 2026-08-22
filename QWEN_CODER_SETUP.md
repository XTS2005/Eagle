# Qwen 2.5 Coder 7B Setup for Eagle Project

## Overview

This document covers the complete setup and configuration of **Qwen 2.5 Coder 7B (Abliterated/Uncensored)** for the Eagle project.

**Model:** Qwen 2.5 Coder 7B  
**Version:** Abliterated (Uncensored)  
**Framework:** Ollama  
**Status:** Ready for Installation  

## What is Qwen 2.5 Coder?

Qwen 2.5 Coder 7B is a specialized AI model created by Alibaba Cloud for:
- Code generation and completion
- Bug fixing and debugging
- Code review and optimization
- Documentation generation
- Explaining programming concepts

The "Abliterated" version removes content filters for direct, uncensored responses.

## Quick Start (5 minutes)

### Prerequisites
- macOS, Linux, or Windows (WSL2)
- 8GB RAM (16GB recommended)
- ~5GB disk space
- Ollama installed from https://ollama.ai

### Installation

```bash
# 1. Install Ollama from https://ollama.ai

# 2. Run the installation script
bash scripts/model-setup/install-qwen-coder.sh

# 3. Start using it
bash scripts/model-setup/run-qwen-coder.sh
```

That's it! For more details, see the sections below.

## Directory Structure

```
Eagle/
├── models/
│   └── qwen-coder/                    # Model configuration
│       ├── README.md                  # Full documentation
│       ├── QUICKSTART.md              # Quick start guide
│       ├── EXAMPLES.md                # Usage examples
│       ├── config.json                # Configuration file
│       ├── modelfile                  # Ollama model definition
│       ├── .env.example               # Environment variables
│       └── .gitignore                 # Git ignore rules
│
├── scripts/
│   └── model-setup/                   # Setup scripts
│       ├── install-qwen-coder.sh      # Installation script
│       ├── run-qwen-coder.sh          # Interactive/CLI runner
│       └── ollama-service.sh          # Daemon manager
│
└── QWEN_CODER_SETUP.md               # This file
```

## Installation Guide

### Step 1: Install Ollama

Download Ollama from https://ollama.ai

**Supported Platforms:**
- macOS (Intel & Apple Silicon)
- Linux (Ubuntu, Fedora, CentOS, etc.)
- Windows (via WSL2)

### Step 2: Run Installation Script

```bash
cd /path/to/Eagle
bash scripts/model-setup/install-qwen-coder.sh
```

The script will:
1. ✓ Verify Ollama is installed
2. ✓ Start Ollama daemon (if needed)
3. ✓ Download Qwen 2.5 Coder 7B (~4GB)
4. ✓ Test the installation
5. ✓ Display usage information

### Step 3: Verify Installation

```bash
# Check Ollama status
bash scripts/model-setup/ollama-service.sh status

# Test the model
bash scripts/model-setup/run-qwen-coder.sh "Write a hello world function"
```

## Usage

### Interactive Mode

Start an interactive conversation:

```bash
bash scripts/model-setup/run-qwen-coder.sh
```

Then type your questions or prompts. Type `exit` or `quit` to leave.

### Command Line Mode

Query without interactive mode:

```bash
bash scripts/model-setup/run-qwen-coder.sh "Your prompt here"
```

### Direct Ollama

Use Ollama directly:

```bash
ollama run qwen2.5-coder:7b-abliterated "Your prompt"
```

### API Access

The model provides an HTTP API on `http://localhost:11434`

#### cURL Example
```bash
curl -X POST http://localhost:11434/api/generate \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen2.5-coder:7b-abliterated",
    "prompt": "Write a function to check if a string is a palindrome",
    "stream": false
  }'
```

#### Python Example
```python
import requests

response = requests.post(
    'http://localhost:11434/api/generate',
    json={
        'model': 'qwen2.5-coder:7b-abliterated',
        'prompt': 'Write a binary search function',
        'stream': False
    }
)
print(response.json()['response'])
```

## Service Management

### Start Ollama Daemon

```bash
bash scripts/model-setup/ollama-service.sh start
```

### Check Status

```bash
bash scripts/model-setup/ollama-service.sh status
```

### View Logs

```bash
bash scripts/model-setup/ollama-service.sh logs
```

### Stop Daemon

```bash
bash scripts/model-setup/ollama-service.sh stop
```

### Restart

```bash
bash scripts/model-setup/ollama-service.sh restart
```

## Configuration

### Model Parameters

Edit `models/qwen-coder/modelfile` to customize:

```dockerfile
# Temperature: controls randomness (0.0-1.0)
PARAMETER temperature 0.7

# Top-p: nucleus sampling
PARAMETER top_p 0.9

# Max response length
PARAMETER num_predict 2048

# Context window size
PARAMETER num_ctx 4096
```

### Environment Variables

Copy and customize `.env.example`:

```bash
cp models/qwen-coder/.env.example models/qwen-coder/.env
```

Edit `models/qwen-coder/.env` with your settings:

```bash
OLLAMA_HOST=127.0.0.1:11434
MODEL_TEMPERATURE=0.7
USE_GPU=true
```

### Custom System Prompt

Modify the `SYSTEM` block in `models/qwen-coder/modelfile`:

```dockerfile
SYSTEM """You are a specialized coding assistant.
Focus on: security, performance, best practices.
Respond only in the requested programming language."""
```

Then create the custom model:

```bash
ollama create qwen-coder-custom -f models/qwen-coder/modelfile
ollama run qwen-coder-custom "Your prompt"
```

## Example Use Cases

### Code Generation
```
Write a TypeScript interface for authentication with email and password
```

### Bug Fixing
```
Fix this SQL injection vulnerability:
[paste your code]
```

### Code Review
```
Review this code for performance:
[paste your code]
```

### Explanation
```
Explain how closures work in JavaScript
```

### Documentation
```
Generate JSDoc for this function:
[paste your code]
```

For more examples, see `models/qwen-coder/EXAMPLES.md`

## System Requirements

| Item | Minimum | Recommended |
|------|---------|-------------|
| **RAM** | 8GB | 16GB+ |
| **Storage** | 5GB | 10GB |
| **CPU** | 2015+ | Modern multi-core |
| **GPU** | Optional | NVIDIA/AMD/Apple |
| **Internet** | For download | For first-time setup |

## Performance Tips

1. **Use GPU**: Ollama automatically uses GPU if available (NVIDIA/AMD/Apple Silicon)
2. **Close other apps**: Free up RAM for the model
3. **Fast storage**: SSD preferred for model loading
4. **Adequate RAM**: 16GB+ for smooth multi-tasking
5. **Reduce context**: Decrease `num_ctx` if running out of memory

## Troubleshooting

### "Ollama not installed"
```bash
# Download from https://ollama.ai
# Then verify installation
ollama --version
```

### "Model not found"
```bash
# Reinstall the model
bash scripts/model-setup/install-qwen-coder.sh
```

### "Connection refused"
```bash
# Start Ollama daemon
bash scripts/model-setup/ollama-service.sh start
```

### "Out of memory"
```bash
# Reduce context size in modelfile
# Or close other applications
# Or increase system RAM
```

### "Very slow responses"
```bash
# Check if GPU is being used
bash scripts/model-setup/ollama-service.sh status

# Or check logs
bash scripts/model-setup/ollama-service.sh logs
```

## Integration Guide

### With Eagle App

The model setup can be integrated with Eagle's build pipeline:

1. **Pre-build Integration**: Check model availability before building
2. **Runtime Integration**: Use model API for in-app features
3. **Documentation**: Use model to auto-generate docs

### With Development Tools

#### VS Code Extension
- Install "Ollama" extension
- Configure endpoint: `http://localhost:11434`
- Use Ctrl+K + Ctrl+L for inline code completion

#### IDE Integration
- Configure editor to use Ollama API
- Set model to `qwen2.5-coder:7b-abliterated`
- Use for code completion and suggestions

### With CI/CD

```yaml
# Example GitHub Actions
- name: Generate Documentation
  run: |
    bash scripts/model-setup/ollama-service.sh start
    bash scripts/model-setup/run-qwen-coder.sh "Generate README for..."
```

## API Reference

### Generate Endpoint

**URL:** `POST /api/generate`

**Request:**
```json
{
  "model": "qwen2.5-coder:7b-abliterated",
  "prompt": "Your prompt here",
  "stream": false,
  "temperature": 0.7,
  "top_p": 0.9,
  "top_k": 40,
  "num_predict": 2048
}
```

**Response:**
```json
{
  "model": "qwen2.5-coder:7b-abliterated",
  "created_at": "2024-01-01T00:00:00Z",
  "response": "Generated response here...",
  "done": true,
  "context": [/* token IDs */],
  "total_duration": 1234567,
  "load_duration": 456789,
  "prompt_eval_count": 10,
  "eval_count": 50,
  "eval_duration": 777778
}
```

### Tags Endpoint

**URL:** `GET /api/tags`

Lists all available models.

## Development

### Building Custom Models

```bash
# Create custom model
ollama create custom-name -f models/qwen-coder/modelfile

# Run custom model
ollama run custom-name "prompt"
```

### Testing Setup

```bash
# Run installation test
bash scripts/model-setup/install-qwen-coder.sh

# Run CLI test
bash scripts/model-setup/run-qwen-coder.sh "test prompt"

# Check service status
bash scripts/model-setup/ollama-service.sh status
```

## Resources

- **Ollama GitHub**: https://github.com/ollama/ollama
- **Qwen Repository**: https://github.com/QwenLM/Qwen
- **Model Card**: https://huggingface.co/Qwen/Qwen2.5-Coder-7B
- **Documentation**: `models/qwen-coder/README.md`
- **Examples**: `models/qwen-coder/EXAMPLES.md`
- **Quick Start**: `models/qwen-coder/QUICKSTART.md`

## License & Attribution

- **Qwen 2.5 Coder**: Apache 2.0 License - Alibaba Cloud
- **Ollama**: MIT License
- **Setup Scripts**: AGPL-3.0 (same as Eagle)

## Support & Feedback

For issues or questions:
1. Check the troubleshooting section above
2. Review `models/qwen-coder/README.md`
3. Check Ollama documentation: https://ollama.ai
4. Open an issue in the Eagle repository

## Future Enhancements

Potential improvements:
- [ ] GUI for model management
- [ ] VS Code extension integration
- [ ] Model fine-tuning on Eagle-specific tasks
- [ ] Local documentation generation
- [ ] Code analysis pipeline
- [ ] Performance monitoring

---

**Setup Date:** August 22, 2026  
**Status:** Ready for Use  
**Model Version:** Qwen 2.5 Coder 7B (Abliterated)  
**Framework:** Ollama  

Start using it now:
```bash
bash scripts/model-setup/run-qwen-coder.sh
```
