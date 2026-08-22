# Qwen 2.5 Coder 7B (Abliterated / Uncensored)

## Overview

This directory contains configuration for **Qwen 2.5 Coder 7B**, a specialized AI model for code generation, completion, and programming assistance. The "Abliterated" version provides uncensored responses without content restrictions.

**Model Details:**
- **Name:** Qwen 2.5 Coder 7B
- **Creator:** Alibaba Cloud
- **Size:** ~4GB (quantized)
- **License:** Apache 2.0 / Model License
- **Context:** 4K-8K tokens
- **Specialization:** Code generation, completion, debugging, and review

## Installation

### Prerequisites

- **Ollama** - Required for running the model locally
  - Download from: https://ollama.ai
  - Supported on: macOS, Linux, Windows (via WSL2)

### Quick Install

```bash
bash scripts/model-setup/install-qwen-coder.sh
```

The script will:
1. Check for Ollama installation
2. Start Ollama daemon if needed
3. Download the model (~4GB)
4. Verify the installation

### Manual Installation

If you prefer manual installation:

```bash
# Start Ollama daemon
ollama serve

# In another terminal, pull the model
ollama pull qwen2.5-coder:7b-abliterated

# Optional: Build custom model with configuration
ollama create qwen-coder-configured -f models/qwen-coder/modelfile
ollama run qwen-coder-configured
```

## Usage

### Interactive Mode

Launch the interactive shell:

```bash
bash scripts/model-setup/run-qwen-coder.sh
```

Then type your coding questions or prompts.

### Command Line Mode

Query the model directly:

```bash
bash scripts/model-setup/run-qwen-coder.sh "Write a Python function to reverse a string"
```

### Direct Ollama Command

```bash
ollama run qwen2.5-coder:7b-abliterated "Your prompt here"
```

### API Usage

The model is available via HTTP API:

```bash
# Start Ollama daemon (if not running)
ollama serve

# Query via API in another terminal
curl -X POST http://localhost:11434/api/generate \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen2.5-coder:7b-abliterated",
    "prompt": "function fibonacci(n) {",
    "stream": false
  }'
```

### JSON Streaming API

```bash
curl -X POST http://localhost:11434/api/generate \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen2.5-coder:7b-abliterated",
    "prompt": "Write a quick sort algorithm in Python",
    "stream": true
  }' | jq .
```

## Example Prompts

### Code Generation

```
Write a TypeScript interface for a user profile with email, username, and created_at fields
```

### Bug Fixing

```
Fix this code:

function reverseString(str) {
    return str.reverse();
}
```

### Explanation

```
Explain what this code does:

const compose = (...fns) => x => fns.reduceRight((v, f) => f(v), x);
```

### Code Review

```
Review this code for performance and best practices:

const getData = async () => {
    const data1 = await fetch('/api/users');
    const data2 = await fetch('/api/posts');
    return { data1, data2 };
}
```

### Documentation

```
Generate JSDoc for this function:

function calculateFactorial(n) {
    if (n <= 1) return 1;
    return n * calculateFactorial(n - 1);
}
```

## API Endpoints

### Generate Text

**Endpoint:** `POST /api/generate`

```json
{
  "model": "qwen2.5-coder:7b-abliterated",
  "prompt": "string",
  "stream": false,
  "temperature": 0.7,
  "top_p": 0.9
}
```

### List Models

**Endpoint:** `GET /api/tags`

Shows all available models.

## Configuration

### Model Parameters

Edit `models/qwen-coder/modelfile` to customize:

- **temperature** (0.0-1.0): Controls randomness
  - Lower = more deterministic
  - Higher = more creative
- **top_p** (0.0-1.0): Nucleus sampling
- **top_k**: Token pool size
- **num_predict**: Max response length

### Custom System Prompt

Modify the `SYSTEM` block in `modelfile` to change the model's behavior and personality.

## Performance Tips

1. **Memory**: Ensure 8GB+ RAM for smooth operation
2. **GPU Support**: Ollama can use NVIDIA/AMD/Apple GPU if available
3. **Context Size**: Adjust `num_ctx` for longer/shorter contexts
4. **Batch Size**: Larger batches = faster but more memory

## API Integration Examples

### Python

```python
import requests
import json

def query_qwen(prompt):
    response = requests.post(
        'http://localhost:11434/api/generate',
        json={
            'model': 'qwen2.5-coder:7b-abliterated',
            'prompt': prompt,
            'stream': False
        }
    )
    return response.json()['response']

# Usage
print(query_qwen("Write a Hello World in JavaScript"))
```

### Node.js

```javascript
const axios = require('axios');

async function queryQwen(prompt) {
    const response = await axios.post(
        'http://localhost:11434/api/generate',
        {
            model: 'qwen2.5-coder:7b-abliterated',
            prompt: prompt,
            stream: false
        }
    );
    return response.data.response;
}

// Usage
queryQwen("Write a Hello World in JavaScript").then(console.log);
```

### Streaming Response (JavaScript)

```javascript
async function streamQwen(prompt) {
    const response = await fetch('http://localhost:11434/api/generate', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            model: 'qwen2.5-coder:7b-abliterated',
            prompt: prompt,
            stream: true
        })
    });

    const reader = response.body.getReader();
    const decoder = new TextDecoder();

    while (true) {
        const { done, value } = await reader.read();
        if (done) break;
        const text = decoder.decode(value);
        const lines = text.split('\n');
        for (const line of lines) {
            if (line) {
                const json = JSON.parse(line);
                process.stdout.write(json.response);
            }
        }
    }
}
```

## Troubleshooting

### Ollama Not Running

```bash
# macOS/Linux
ollama serve

# Windows (WSL2)
wsl
ollama serve
```

### Model Not Found

```bash
# Reinstall the model
ollama pull qwen2.5-coder:7b-abliterated
```

### Out of Memory

- Reduce `num_ctx` in modelfile
- Close other applications
- Use GPU acceleration if available

### Slow Responses

- Check Ollama is running on GPU (not CPU-only)
- Verify internet connection for first run
- Reduce response length with smaller prompts

## System Requirements

### Minimum
- 8GB RAM
- 5GB disk space
- Modern CPU (2015+)

### Recommended
- 16GB+ RAM
- GPU (NVIDIA/AMD/Apple)
- SSD storage

## Features of Abliterated Version

✓ No content filters
✓ Direct, uncensored responses
✓ Full code generation capabilities
✓ Can discuss any programming topic
✓ No safety restrictions
✓ Complete function/library implementation

## Legal & Safety Notice

This model is for educational and development purposes. The "abliterated" version removes safety filters.

- **Responsibility**: You are responsible for how you use this model
- **Output Quality**: Generated code should be reviewed before use
- **Security**: Don't submit sensitive data to the model
- **Attribution**: Acknowledge when using AI-generated code

## Resources

- **Ollama**: https://ollama.ai
- **Qwen Documentation**: https://github.com/QwenLM/Qwen
- **Model Card**: https://huggingface.co/Qwen/Qwen2.5-Coder-7B
- **Abliterated Versions**: Community-created uncensored variants

## Performance Benchmarks

On Apple Silicon / Intel i7 / NVIDIA RTX 3080:
- **Startup Time**: ~2-5 seconds
- **Throughput**: 50-150 tokens/second (CPU) / 200-500 tokens/second (GPU)
- **Memory Usage**: 4-6GB
- **Typical Response Time**: 5-30 seconds (10-50 tokens)

---

**Status:** Ready for development and integration
**Last Updated:** August 2026
**Maintained By:** Eagle Development Team
