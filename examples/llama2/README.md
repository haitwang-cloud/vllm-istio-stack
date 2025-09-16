# Llama 2 Configuration

This directory contains specific configurations for deploying Llama 2 models with vLLM-Istio stack.

## Quick Start

```bash
# Copy Llama 2 configuration
cp examples/llama2/configmap-llama2.yaml k8s/configmap.yaml

# Deploy with Llama 2 settings
./scripts/deploy.sh
```

## Model Variants

- **Llama 2 7B**: `meta-llama/Llama-2-7b-chat-hf`
- **Llama 2 13B**: `meta-llama/Llama-2-13b-chat-hf` 
- **Llama 2 70B**: `meta-llama/Llama-2-70b-chat-hf`

## Resource Requirements

### Llama 2 7B
- **GPU**: 1x A100 40GB or 1x V100 32GB
- **CPU**: 8 cores
- **Memory**: 32GB RAM

### Llama 2 13B  
- **GPU**: 1x A100 80GB or 2x V100 32GB
- **CPU**: 16 cores
- **Memory**: 64GB RAM

### Llama 2 70B
- **GPU**: 4x A100 80GB or 8x V100 32GB  
- **CPU**: 32 cores
- **Memory**: 128GB RAM

## Performance Tuning

For optimal performance with Llama 2:

1. **Tensor Parallelism**: Use multiple GPUs for larger models
2. **Batch Size**: Increase `max_num_batched_tokens` for higher throughput
3. **Context Length**: Adjust `max_model_len` based on your use case