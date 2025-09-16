#!/bin/bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed or not in PATH"
        exit 1
    fi
    
    # Check cluster connection
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Cannot connect to Kubernetes cluster"
        exit 1
    fi
    
    # Check Istio installation
    if ! kubectl get namespace istio-system &> /dev/null; then
        print_warning "Istio system namespace not found. Please install Istio first."
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    print_success "Prerequisites check completed"
}

# Deploy namespace
deploy_namespace() {
    print_status "Creating namespace..."
    kubectl apply -f k8s/namespace.yaml
    print_success "Namespace created"
}

# Deploy Kubernetes resources
deploy_k8s_resources() {
    print_status "Deploying Kubernetes resources..."
    
    # Deploy ConfigMap
    kubectl apply -f k8s/configmap.yaml
    
    # Deploy Service
    kubectl apply -f k8s/service.yaml
    
    # Deploy Deployment
    kubectl apply -f k8s/deployment.yaml
    
    # Deploy HPA (if metrics server is available)
    if kubectl get apiservice v1beta1.metrics.k8s.io &> /dev/null; then
        kubectl apply -f k8s/hpa.yaml
        print_success "HPA deployed"
    else
        print_warning "Metrics server not found, skipping HPA deployment"
    fi
    
    print_success "Kubernetes resources deployed"
}

# Deploy Istio resources
deploy_istio_resources() {
    print_status "Deploying Istio resources..."
    
    # Deploy Gateway
    kubectl apply -f istio/gateway.yaml
    
    # Deploy VirtualService
    kubectl apply -f istio/virtualservice.yaml
    
    # Deploy DestinationRule
    kubectl apply -f istio/destinationrule.yaml
    
    # Deploy PeerAuthentication
    kubectl apply -f istio/peerauthentication.yaml
    
    # Deploy AuthorizationPolicy
    kubectl apply -f istio/authorizationpolicy.yaml
    
    print_success "Istio resources deployed"
}

# Deploy monitoring resources
deploy_monitoring() {
    print_status "Deploying monitoring resources..."
    
    # Check if Prometheus operator is installed
    if kubectl get crd servicemonitors.monitoring.coreos.com &> /dev/null; then
        kubectl apply -f monitoring/servicemonitor.yaml
        print_success "ServiceMonitor deployed"
    else
        print_warning "Prometheus operator not found, skipping ServiceMonitor deployment"
    fi
    
    # Deploy Jaeger (if Jaeger operator is available)
    if kubectl get crd jaegers.jaegertracing.io &> /dev/null; then
        kubectl apply -f monitoring/jaeger.yaml
        print_success "Jaeger deployed"
    else
        print_warning "Jaeger operator not found, skipping Jaeger deployment"
    fi
}

# Wait for deployment
wait_for_deployment() {
    print_status "Waiting for deployment to be ready..."
    
    kubectl wait --for=condition=available --timeout=300s deployment/vllm -n vllm-system
    
    print_success "Deployment is ready"
}

# Get access information
get_access_info() {
    print_status "Getting access information..."
    
    # Get Istio gateway external IP
    EXTERNAL_IP=$(kubectl get svc istio-ingressgateway -n istio-system -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
    
    if [ -z "$EXTERNAL_IP" ]; then
        EXTERNAL_IP=$(kubectl get svc istio-ingressgateway -n istio-system -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
    fi
    
    if [ -z "$EXTERNAL_IP" ]; then
        print_warning "External IP not found. Using port-forward for testing:"
        echo "kubectl port-forward svc/istio-ingressgateway -n istio-system 8080:80"
        EXTERNAL_IP="localhost:8080"
    fi
    
    echo
    print_success "vLLM is deployed and accessible at:"
    echo "  Health check: http://${EXTERNAL_IP}/health"
    echo "  API endpoint: http://${EXTERNAL_IP}/v1/completions"
    echo "  Metrics: http://${EXTERNAL_IP}/metrics"
    echo
    echo "Test with:"
    echo "curl -X POST http://${EXTERNAL_IP}/v1/completions \\"
    echo "  -H \"Content-Type: application/json\" \\"
    echo "  -d '{\"model\": \"gpt2\", \"prompt\": \"Hello world\", \"max_tokens\": 50}'"
}

# Main deployment function
main() {
    echo "=== vLLM-Istio Stack Deployment ==="
    echo
    
    check_prerequisites
    
    echo
    print_status "Starting deployment..."
    
    deploy_namespace
    deploy_k8s_resources
    deploy_istio_resources
    deploy_monitoring
    wait_for_deployment
    get_access_info
    
    echo
    print_success "Deployment completed successfully!"
}

# Run main function
main "$@"