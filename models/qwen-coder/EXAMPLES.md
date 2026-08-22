# Qwen 2.5 Coder 7B - Usage Examples

## Getting Started

### 1. Start Ollama

```bash
bash scripts/model-setup/ollama-service.sh start
```

### 2. Interactive Chat

```bash
bash scripts/model-setup/run-qwen-coder.sh
```

## Example Prompts

### Code Generation

#### Python - Simple Function
```
Write a Python function that calculates the Fibonacci sequence up to n terms
```

**Expected Output:**
```python
def fibonacci(n):
    if n <= 0:
        return []
    elif n == 1:
        return [0]
    
    fib_sequence = [0, 1]
    for i in range(2, n):
        fib_sequence.append(fib_sequence[i-1] + fib_sequence[i-2])
    return fib_sequence
```

#### JavaScript - API Endpoint
```
Create an Express.js route that handles POST requests to /api/users and validates the request body
```

#### TypeScript - React Component
```
Write a TypeScript React component for a reusable Button with variants (primary, secondary, danger)
```

### Code Completion

#### Complete the function
```
def merge_sorted_arrays(arr1, arr2):
    """Merge two sorted arrays"""
    result = []
    i = j = 0
    
    while i < len(arr1) and j < len(arr2):
```

Expected to complete with merge logic.

#### Finish the SQL query
```
SELECT u.id, u.name, COUNT(p.id) as post_count
FROM users u
LEFT JOIN posts p ON u.id = p.user_id
WHERE u.created_at > '2024-01-01'
```

### Bug Fixing

#### Fix Memory Leak
```
Review and fix this code for memory leaks:

let cache = {};

function processLargeData(key, data) {
    cache[key] = data;
    return cache[key];
}

// Called repeatedly in a loop
for(let i = 0; i < 1000000; i++) {
    processLargeData(`key_${i}`, largeDataArray);
}
```

**Expected Fix:** Add cache size limit or cleanup mechanism.

#### Fix Race Condition
```
Fix the race condition in this async code:

let userCount = 0;

async function addUser(name) {
    const id = userCount;
    userCount++;
    await saveUser(id, name);
    return id;
}

// Called multiple times concurrently
Promise.all([
    addUser("Alice"),
    addUser("Bob"),
    addUser("Charlie")
]);
```

### Code Review

#### Performance Review
```
Review this code for performance issues:

function findUser(users, id) {
    for(let user of users) {
        if(user.id === id) return user;
    }
    return null;
}

// Called frequently with large user arrays
```

**Expected:** Suggest using Map or creating indexes.

#### Best Practices Review
```
Review this code for best practices and improvements:

const app = require('express')();
const db = require('./db.js');

app.get('/api/users/:id', async (req, res) => {
    const user = db.query(`SELECT * FROM users WHERE id = ${req.params.id}`);
    res.json(user);
});

app.listen(3000);
```

**Expected:** SQL injection fix, error handling, parameterized queries.

### Documentation Generation

#### Generate JSDoc
```
Generate complete JSDoc documentation for this function:

function calculateCompoundInterest(principal, rate, time, compounds) {
    return principal * Math.pow(1 + rate / (100 * compounds), compounds * time);
}
```

**Expected:**
```javascript
/**
 * Calculates compound interest
 * @param {number} principal - Initial amount
 * @param {number} rate - Annual interest rate (percentage)
 * @param {number} time - Time in years
 * @param {number} compounds - Compounding periods per year
 * @returns {number} Final amount after compound interest
 */
```

#### Generate API Documentation
```
Generate OpenAPI/Swagger documentation for this endpoint:

POST /api/products
Request body: { name, price, category }
Response: { id, name, price, category, created_at }
Errors: 400 (validation), 401 (auth), 500 (server)
```

### Explanation & Learning

#### Explain Algorithm
```
Explain how this quicksort algorithm works:

def quicksort(arr):
    if len(arr) <= 1:
        return arr
    pivot = arr[len(arr) // 2]
    left = [x for x in arr if x < pivot]
    middle = [x for x in arr if x == pivot]
    right = [x for x in arr if x > pivot]
    return quicksort(left) + middle + quicksort(right)
```

#### Explain Design Pattern
```
Explain the Observer design pattern with a real-world example
```

#### Explain Concept
```
Explain what a Closure is in JavaScript with examples
```

### Refactoring

#### Reduce Complexity
```
Refactor this nested function to reduce complexity:

function processUserData(users) {
    const result = [];
    for(let user of users) {
        if(user.active) {
            for(let i = 0; i < user.posts.length; i++) {
                if(user.posts[i].likes > 100) {
                    result.push({
                        name: user.name,
                        post: user.posts[i].title,
                        likes: user.posts[i].likes
                    });
                }
            }
        }
    }
    return result;
}
```

#### Improve Readability
```
Make this code more readable and maintainable:

const u = (s) => s.split('').reduce((a, c) => a + c.charCodeAt(0), 0);
const v = (a, b) => u(a.n) > u(b.n) ? 1 : -1;
const w = (x) => x.sort(v).map(i => i.n);
```

### Real-World Scenarios

#### Build a CLI Tool
```
Write a Node.js CLI tool that reads a CSV file and converts it to JSON
```

#### Create Database Schema
```
Design a database schema for a social media application with users, posts, comments, and likes
```

#### Build Authentication
```
Create a secure authentication system with JWT tokens in Node.js/Express
```

#### API Integration
```
Write a class that integrates with the OpenWeather API to fetch and cache weather data
```

## API Examples

### Using cURL

```bash
# Simple query
curl -X POST http://localhost:11434/api/generate \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen2.5-coder:7b-abliterated",
    "prompt": "def hello():",
    "stream": false
  }'

# Streaming response
curl -X POST http://localhost:11434/api/generate \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen2.5-coder:7b-abliterated",
    "prompt": "Write a Python class for a linked list",
    "stream": true
  }' | jq .
```

### Using Python

```python
import requests
import json

def query_qwen(prompt):
    response = requests.post(
        'http://localhost:11434/api/generate',
        json={
            'model': 'qwen2.5-coder:7b-abliterated',
            'prompt': prompt,
            'stream': False,
            'temperature': 0.7
        },
        timeout=300
    )
    return response.json()['response']

# Example usage
code = query_qwen("Write a function to check if a number is prime")
print(code)
```

### Using JavaScript

```javascript
async function queryQwen(prompt) {
    const response = await fetch('http://localhost:11434/api/generate', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            model: 'qwen2.5-coder:7b-abliterated',
            prompt: prompt,
            stream: false,
            temperature: 0.7
        })
    });
    const data = await response.json();
    return data.response;
}

// Usage
queryQwen("Write a React hook for form validation")
    .then(code => console.log(code));
```

## Advanced Usage

### Custom System Prompt

Create `custom-model.md`:

```
FROM qwen2.5-coder:7b-abliterated

SYSTEM """You are a code review expert. Analyze code for:
- Performance issues
- Security vulnerabilities
- Code style violations
- Best practices
Provide specific, actionable feedback."""

PARAMETER temperature 0.5
```

Build and run:
```bash
ollama create code-reviewer -f custom-model.md
ollama run code-reviewer "Review this code for security issues: ..."
```

### Streaming Response

Process responses token-by-token:

```python
import requests
import json

response = requests.post(
    'http://localhost:11434/api/generate',
    json={
        'model': 'qwen2.5-coder:7b-abliterated',
        'prompt': 'Write a quick sort algorithm',
        'stream': True
    },
    stream=True
)

for line in response.iter_lines():
    if line:
        data = json.loads(line)
        print(data['response'], end='', flush=True)
```

### Batch Processing

```python
prompts = [
    "Write a palindrome checker function",
    "Write a binary search function",
    "Write a merge sort function"
]

for prompt in prompts:
    result = query_qwen(prompt)
    print(f"Prompt: {prompt}")
    print(f"Result: {result}\n")
```

---

**Tips:**
- Be specific in your prompts for better results
- Start simple and add complexity gradually
- Use clear formatting (code blocks, indentation)
- Ask follow-up questions for clarification
- The model responds best to English prompts
