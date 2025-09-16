# vLLM-Istio Stack

A comprehensive solution for integrating [vLLM](https://github.com/vllm-project/vllm) with [Istio](https://istio.io/) for production-grade Large Language Model (LLM) hosting in Kubernetes.

## Overview

This repository provides everything you need to deploy vLLM as a scalable, production-ready LLM serving framework using Istio service mesh for advanced traffic management, security, and observability.

## Features

- 🚀 **Production-ready vLLM deployment** with Kubernetes manifests
- 🌐 **Istio integration** for advanced traffic management and load balancing
- 🔒 **Security configurations** including mTLS and authentication policies
- 📊 **Observability** with metrics, logging, and distributed tracing
- 🎛️ **Traffic management** with request routing and circuit breaking
- ⚡ **Auto-scaling** configurations for high availability
- 🐳 **Docker configurations** for custom vLLM images

## Prerequisites

- Kubernetes cluster (v1.20+)
- Istio installed and configured (v1.15+)
- kubectl configured to access your cluster
- Docker (for building custom images)

## Quick Start

1. **Clone this repository:**
   ```bash
   git clone https://github.com/haitwang-cloud/vllm-istio-stack.git
   cd vllm-istio-stack
   ```

2. **Deploy vLLM with Istio:**
   ```bash
   # Deploy the vLLM service
   kubectl apply -f k8s/
   
   # Configure Istio traffic management
   kubectl apply -f istio/
   ```

3. **Access your LLM endpoint:**
   ```bash
   # Get the Istio gateway external IP
   kubectl get svc istio-ingressgateway -n istio-system
   
   # Test the endpoint
   curl -X POST http://<EXTERNAL-IP>/v1/completions \
     -H "Content-Type: application/json" \
     -d '{"model": "gpt2", "prompt": "Hello world", "max_tokens": 50}'
   ```

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Client        │───▶│  Istio Gateway  │───▶│   vLLM Service  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                              │
                              ▼
                       ┌─────────────────┐
                       │ Traffic Policies│
                       │ • Load Balancing│
                       │ • Circuit Break │
                       │ • Rate Limiting │
                       │ • mTLS          │
                       └─────────────────┘
```

## Directory Structure

```
vllm-istio-stack/
├── README.md                 # This file
├── docker/                   # Docker configurations
│   ├── Dockerfile           # Custom vLLM image
│   └── requirements.txt     # Python dependencies
├── k8s/                     # Kubernetes manifests
│   ├── namespace.yaml       # Namespace configuration
│   ├── deployment.yaml      # vLLM deployment
│   ├── service.yaml         # Kubernetes service
│   ├── configmap.yaml       # Configuration files
│   └── hpa.yaml            # Horizontal Pod Autoscaler
├── istio/                   # Istio configurations
│   ├── gateway.yaml         # Istio Gateway
│   ├── virtualservice.yaml  # Traffic routing rules
│   ├── destinationrule.yaml # Load balancing policies
│   ├── peerauthentication.yaml # mTLS configuration
│   └── authorizationpolicy.yaml # Access control
├── monitoring/              # Observability configs
│   ├── servicemonitor.yaml  # Prometheus monitoring
│   ├── grafana-dashboard.json # Grafana dashboard
│   └── jaeger.yaml         # Distributed tracing
├── scripts/                 # Deployment scripts
│   ├── deploy.sh           # Full deployment script
│   ├── cleanup.sh          # Cleanup script
│   └── test.sh             # Testing script
└── examples/               # Example configurations
    ├── llama2/             # Llama 2 specific configs
    ├── codellama/          # Code Llama configs
    └── mixtral/            # Mixtral configs
```

## Configuration

### Model Configuration

Edit `k8s/configmap.yaml` to configure your model:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: vllm-config
data:
  model: "meta-llama/Llama-2-7b-chat-hf"  # Change this to your model
  tensor_parallel_size: "1"
  max_model_len: "4096"
```

### Scaling Configuration

Adjust `k8s/hpa.yaml` for auto-scaling:

```yaml
spec:
  minReplicas: 1
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70
```

### Traffic Management

Configure load balancing in `istio/destinationrule.yaml`:

```yaml
spec:
  trafficPolicy:
    loadBalancer:
      simple: LEAST_CONN  # Options: ROUND_ROBIN, LEAST_CONN, RANDOM
```

## Advanced Features

### Circuit Breaker

Enable circuit breaking to prevent cascade failures:

```yaml
# In destinationrule.yaml
spec:
  trafficPolicy:
    outlierDetection:
      consecutiveErrors: 3
      interval: 30s
      baseEjectionTime: 30s
```

### Rate Limiting

Configure rate limiting for API protection:

```yaml
# Custom rate limit configuration
apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  name: rate-limit-filter
spec:
  configPatches:
  - applyTo: HTTP_FILTER
    match:
      listener:
        filterChain:
          filter:
            name: "envoy.filters.network.http_connection_manager"
    patch:
      operation: INSERT_BEFORE
      value:
        name: envoy.filters.http.local_ratelimit
```

### GPU Support

For GPU-enabled deployments, update the deployment manifest:

```yaml
spec:
  template:
    spec:
      containers:
      - name: vllm
        resources:
          limits:
            nvidia.com/gpu: "1"
          requests:
            nvidia.com/gpu: "1"
```

## Monitoring

Access monitoring dashboards:

1. **Prometheus**: `http://<CLUSTER-IP>/prometheus`
2. **Grafana**: `http://<CLUSTER-IP>/grafana`
3. **Jaeger**: `http://<CLUSTER-IP>/jaeger`
4. **Kiali**: `http://<CLUSTER-IP>/kiali`

## Troubleshooting

### Common Issues

1. **Pod not starting**: Check GPU availability and model download
   ```bash
   kubectl describe pod -l app=vllm -n vllm-system
   ```

2. **Traffic not routing**: Verify Istio gateway configuration
   ```bash
   kubectl get gateway,vs,dr -n vllm-system
   ```

3. **High latency**: Check resource allocation and scaling policies
   ```bash
   kubectl top pods -n vllm-system
   ```

### Logs

View logs for debugging:

```bash
# vLLM service logs
kubectl logs -f deployment/vllm -n vllm-system

# Istio proxy logs
kubectl logs -f deployment/vllm -c istio-proxy -n vllm-system
```

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Commit your changes: `git commit -m 'Add amazing feature'`
4. Push to the branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

## Support

- 📖 [Documentation](https://github.com/haitwang-cloud/vllm-istio-stack/wiki)
- 🐛 [Report Issues](https://github.com/haitwang-cloud/vllm-istio-stack/issues)
- 💬 [Discussions](https://github.com/haitwang-cloud/vllm-istio-stack/discussions)

## Acknowledgments

- [vLLM Project](https://github.com/vllm-project/vllm) for the excellent LLM serving framework
- [Istio Community](https://istio.io/) for the powerful service mesh platform
- [Kubernetes](https://kubernetes.io/) for container orchestration