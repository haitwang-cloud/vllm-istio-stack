# Mixtral Configuration

This directory contains specific configurations for deploying Mixtral models with vLLM-Istio stack.

## Quick Start

```bash
# Copy Mixtral configuration
cp examples/mixtral/configmap-mixtral.yaml k8s/configmap.yaml

# Deploy with Mixtral settings (requires GPU-enabled deployment)
cp examples/mixtral/deployment-mixtral.yaml k8s/deployment.yaml
./scripts/deploy.sh
```

## Model Variants

- **Mixtral 8x7B**: `mistralai/Mixtral-8x7B-Instruct-v0.1`
- **Mixtral 8x22B**: `mistralai/Mixtral-8x22B-Instruct-v0.1`

## Resource Requirements

### Mixtral 8x7B
- **GPU**: 2x A100 80GB or 4x V100 32GB
- **CPU**: 16 cores  
- **Memory**: 64GB RAM
- **Tensor Parallelism**: 2-4 GPUs recommended

### Mixtral 8x22B
- **GPU**: 4x A100 80GB or 8x V100 32GB
- **CPU**: 32 cores
- **Memory**: 128GB RAM
- **Tensor Parallelism**: 4-8 GPUs recommended

## Features

- **Mixture of Experts**: Efficient large model architecture
- **Multilingual**: Supports multiple languages
- **High Quality**: State-of-the-art performance
- **Long Context**: Up to 32K tokens

## Performance Tuning

1. **Use multiple GPUs** with tensor parallelism for optimal performance
2. **Increase batch size** for higher throughput
3. **Adjust expert routing** parameters if available