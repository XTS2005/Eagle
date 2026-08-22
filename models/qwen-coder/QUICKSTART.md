# Qwen 2.5 Coder 7B - Quick Start Guide

## ⚡ 30 Seconds Setup

### Step 1: Install Ollama
Download from https://ollama.ai and install.

### Step 2: Run Installation Script
```bash
bash scripts/model-setup/install-qwen-coder.sh
```

This will:
- ✓ Check Ollama installation
- ✓ Start Ollama daemon
- ✓ Download the model (~4GB)
- ✓ Verify everything works

### Step 3: Start Asking!
```bash
bash scripts/model-setup/run-qwen-coder.sh
```

Then type your coding questions!

---

## Common Commands

### Start/Stop Ollama
```bash
# Start daemon
bash scripts/model-setup/ollama-service.sh start

# Check status
bash scripts/model-setup/ollama-service.sh status

# Stop daemon
bash scripts/model-setup/ollama-service.sh stop

# View logs
bash scripts/model-setup/ollama-service.sh logs
```

### Use the Model

#### Interactive Mode
```bash
bash scripts/model-setup/run-qwen-coder.sh
```

#### Single Query
```bash
bash scripts/model-setup/run-qwen-coder.sh "Write a hello world in Python"
```

#### Direct Ollama
```bash
ollama run qwen2.5-coder:7b-abliterated "Your prompt here"
```

---

## What You Can Do

✅ **Write Code** - Generate functions, classes, full programs
✅ **Fix Bugs** - Debug and repair broken code
✅ **Review Code** - Get feedback on performance and best practices
✅ **Explain Code** - Understand how code works
✅ **Generate Docs** - Create documentation automatically
✅ **Refactor** - Improve code quality and readability
✅ **Learn** - Understand programming concepts

---

## Example Prompts

### Generate Code
```
Write a Python function to find the longest substring without repeating characters
```

### Fix a Bug
```
This code has a memory leak. Fix it:
[paste your code]
```

### Review Code
```
Review this code for security issues:
[paste your code]
```

### Explain Concept
```
Explain how callbacks and promises work in JavaScript
```

---

## Quick Reference

| Task | Command |
|------|---------|
| Install | `bash scripts/model-setup/install-qwen-coder.sh` |
| Start | `bash scripts/model-setup/ollama-service.sh start` |
| Chat | `bash scripts/model-setup/run-qwen-coder.sh` |
| Query | `bash scripts/model-setup/run-qwen-coder.sh "prompt"` |
| Status | `bash scripts/model-setup/ollama-service.sh status` |
| Stop | `bash scripts/model-setup/ollama-service.sh stop` |

---

## API Usage

The model runs on `http://localhost:11434` by default.

### Simple Query
```bash
curl -X POST http://localhost:11434/api/generate \
  -d '{"model": "qwen2.5-coder:7b-abliterated", "prompt": "def hello():", "stream": false}'
```

### From Python
```python
import requests

response = requests.post(
    'http://localhost:11434/api/generate',
    json={
        'model': 'qwen2.5-coder:7b-abliterated',
        'prompt': 'Write hello world in JavaScript',
        'stream': False
    }
)
print(response.json()['response'])
```

---

## Troubleshooting

### "Ollama is not installed"
→ Download from https://ollama.ai

### "Model not found"
→ Run installation script again: `bash scripts/model-setup/install-qwen-coder.sh`

### "Connection refused"
→ Start Ollama: `bash scripts/model-setup/ollama-service.sh start`

### "Out of memory"
→ Close other apps or use a machine with more RAM (8GB+ recommended)

### "Slow responses"
→ Normal on CPU. Use GPU or larger machine for faster results.

---

## System Requirements

| | Minimum | Recommended |
|---|---|---|
| RAM | 8GB | 16GB+ |
| Storage | 5GB | 10GB |
| CPU | 2015+ | Modern |
| GPU | No | Yes (NVIDIA/AMD) |

---

## File Structure

```
models/qwen-coder/
├── README.md              # Full documentation
├── QUICKSTART.md          # This file
├── EXAMPLES.md            # Usage examples
├── config.json            # Configuration
└── modelfile              # Custom model config

scripts/model-setup/
├── install-qwen-coder.sh  # Installation script
├── run-qwen-coder.sh      # Interactive/CLI runner
└── ollama-service.sh      # Daemon manager
```

---

## Next Steps

1. ✅ Install Ollama
2. ✅ Run installation script
3. ✅ Read [EXAMPLES.md](EXAMPLES.md)
4. ✅ Check full [README.md](README.md)
5. ✅ Build something awesome!

---

## Support

- **Issue with Ollama?** → https://github.com/ollama/ollama
- **Model questions?** → https://github.com/QwenLM/Qwen
- **Need help?** → Check README.md troubleshooting section

---

**Ready to code?** Start with:
```bash
bash scripts/model-setup/run-qwen-coder.sh
```
