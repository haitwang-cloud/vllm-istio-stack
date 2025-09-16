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

# Cleanup function
cleanup_resources() {
    print_status "Cleaning up vLLM-Istio stack..."
    
    # Remove Istio resources
    print_status "Removing Istio resources..."
    kubectl delete -f istio/ --ignore-not-found=true
    
    # Remove monitoring resources
    print_status "Removing monitoring resources..."
    kubectl delete -f monitoring/ --ignore-not-found=true
    
    # Remove Kubernetes resources
    print_status "Removing Kubernetes resources..."
    kubectl delete -f k8s/ --ignore-not-found=true
    
    # Wait a moment for graceful shutdown
    print_status "Waiting for graceful shutdown..."
    sleep 30
    
    # Force delete any remaining pods
    kubectl delete pods --all -n vllm-system --force --grace-period=0 2>/dev/null || true
    
    # Remove namespace
    print_status "Removing namespace..."
    kubectl delete namespace vllm-system --ignore-not-found=true
    
    print_success "Cleanup completed"
}

# Confirmation prompt
confirm_cleanup() {
    echo "=== vLLM-Istio Stack Cleanup ==="
    echo
    print_warning "This will delete all vLLM-Istio stack resources including:"
    echo "  - vLLM deployment and services"
    echo "  - Istio configurations"
    echo "  - Monitoring resources"
    echo "  - vllm-system namespace"
    echo
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Cleanup cancelled"
        exit 0
    fi
}

# Check if resources exist
check_resources() {
    if ! kubectl get namespace vllm-system &> /dev/null; then
        print_warning "vllm-system namespace not found. Nothing to clean up."
        exit 0
    fi
}

# Main cleanup function
main() {
    check_resources
    confirm_cleanup
    cleanup_resources
    
    echo
    print_success "vLLM-Istio stack has been completely removed!"
}

# Run main function
main "$@"