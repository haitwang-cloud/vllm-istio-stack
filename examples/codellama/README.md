# Code Llama Configuration

This directory contains specific configurations for deploying Code Llama models with vLLM-Istio stack.

## Quick Start

```bash
# Copy Code Llama configuration
cp examples/codellama/configmap-codellama.yaml k8s/configmap.yaml

# Deploy with Code Llama settings
./scripts/deploy.sh
```

## Model Variants

- **Code Llama 7B**: `codellama/CodeLlama-7b-Instruct-hf`
- **Code Llama 13B**: `codellama/CodeLlama-13b-Instruct-hf`
- **Code Llama 34B**: `codellama/CodeLlama-34b-Instruct-hf`

## Use Cases

- Code completion and generation
- Code explanation and documentation
- Bug detection and fixing
- Code translation between languages

## Example API Usage

```bash
curl -X POST http://your-endpoint/v1/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "codellama-7b-instruct",
    "prompt": "# Write a Python function to calculate fibonacci numbers\ndef fibonacci(",
    "max_tokens": 200,
    "temperature": 0.1,
    "stop": ["\n\n"]
  }'
```

## Performance Tips

1. **Lower temperature** (0.1-0.3) for more deterministic code generation
2. **Use stop tokens** to prevent over-generation
3. **Larger context** for complex code understanding