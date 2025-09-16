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

# Test configuration
TEST_MODEL="gpt2"
TEST_PROMPT="Hello, how are you today?"
MAX_TOKENS=50

# Get endpoint URL
get_endpoint() {
    # Try to get external IP from Istio gateway
    EXTERNAL_IP=$(kubectl get svc istio-ingressgateway -n istio-system -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
    
    if [ -z "$EXTERNAL_IP" ]; then
        EXTERNAL_IP=$(kubectl get svc istio-ingressgateway -n istio-system -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
    fi
    
    if [ -z "$EXTERNAL_IP" ]; then
        print_warning "External IP not found. Using port-forward..."
        kubectl port-forward svc/istio-ingressgateway -n istio-system 8080:80 &
        PORT_FORWARD_PID=$!
        sleep 5
        ENDPOINT="http://localhost:8080"
    else
        ENDPOINT="http://${EXTERNAL_IP}"
    fi
    
    echo $ENDPOINT
}

# Test health endpoint
test_health() {
    local endpoint=$1
    print_status "Testing health endpoint..."
    
    if curl -s -f "${endpoint}/health" > /dev/null; then
        print_success "Health check passed"
        return 0
    else
        print_error "Health check failed"
        return 1
    fi
}

# Test metrics endpoint
test_metrics() {
    local endpoint=$1
    print_status "Testing metrics endpoint..."
    
    if curl -s -f "${endpoint}/metrics" | head -5 > /dev/null; then
        print_success "Metrics endpoint accessible"
        return 0
    else
        print_error "Metrics endpoint failed"
        return 1
    fi
}

# Test completions API
test_completions() {
    local endpoint=$1
    print_status "Testing completions API..."
    
    local response=$(curl -s -w "%{http_code}" -X POST "${endpoint}/v1/completions" \
        -H "Content-Type: application/json" \
        -d "{
            \"model\": \"${TEST_MODEL}\",
            \"prompt\": \"${TEST_PROMPT}\",
            \"max_tokens\": ${MAX_TOKENS},
            \"temperature\": 0.7
        }")
    
    local http_code="${response: -3}"
    local body="${response%???}"
    
    if [ "$http_code" = "200" ]; then
        print_success "Completions API test passed"
        echo "Response preview:"
        echo "$body" | jq '.choices[0].text' 2>/dev/null || echo "$body" | head -3
        return 0
    else
        print_error "Completions API test failed (HTTP $http_code)"
        echo "Response: $body"
        return 1
    fi
}

# Test models endpoint
test_models() {
    local endpoint=$1
    print_status "Testing models endpoint..."
    
    local response=$(curl -s -w "%{http_code}" "${endpoint}/v1/models")
    local http_code="${response: -3}"
    local body="${response%???}"
    
    if [ "$http_code" = "200" ]; then
        print_success "Models endpoint test passed"
        echo "Available models:"
        echo "$body" | jq '.data[].id' 2>/dev/null || echo "$body"
        return 0
    else
        print_error "Models endpoint test failed (HTTP $http_code)"
        echo "Response: $body"
        return 1
    fi
}

# Test Kubernetes resources
test_k8s_resources() {
    print_status "Testing Kubernetes resources..."
    
    # Check namespace
    if kubectl get namespace vllm-system &> /dev/null; then
        print_success "Namespace exists"
    else
        print_error "Namespace not found"
        return 1
    fi
    
    # Check deployment
    if kubectl get deployment vllm -n vllm-system &> /dev/null; then
        local ready_replicas=$(kubectl get deployment vllm -n vllm-system -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
        local desired_replicas=$(kubectl get deployment vllm -n vllm-system -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "1")
        
        if [ "$ready_replicas" = "$desired_replicas" ] && [ "$ready_replicas" != "0" ]; then
            print_success "Deployment is ready ($ready_replicas/$desired_replicas replicas)"
        else
            print_warning "Deployment not fully ready ($ready_replicas/$desired_replicas replicas)"
        fi
    else
        print_error "Deployment not found"
        return 1
    fi
    
    # Check service
    if kubectl get service vllm -n vllm-system &> /dev/null; then
        print_success "Service exists"
    else
        print_error "Service not found"
        return 1
    fi
    
    return 0
}

# Test Istio resources
test_istio_resources() {
    print_status "Testing Istio resources..."
    
    # Check gateway
    if kubectl get gateway vllm-gateway -n vllm-system &> /dev/null; then
        print_success "Istio Gateway exists"
    else
        print_error "Istio Gateway not found"
        return 1
    fi
    
    # Check virtual service
    if kubectl get virtualservice vllm -n vllm-system &> /dev/null; then
        print_success "VirtualService exists"
    else
        print_error "VirtualService not found"
        return 1
    fi
    
    # Check destination rule
    if kubectl get destinationrule vllm -n vllm-system &> /dev/null; then
        print_success "DestinationRule exists"
    else
        print_error "DestinationRule not found"
        return 1
    fi
    
    return 0
}

# Cleanup function
cleanup() {
    if [ -n "${PORT_FORWARD_PID:-}" ]; then
        print_status "Stopping port-forward..."
        kill $PORT_FORWARD_PID 2>/dev/null || true
    fi
}

# Performance test
performance_test() {
    local endpoint=$1
    print_status "Running basic performance test..."
    
    print_status "Sending 5 concurrent requests..."
    
    local start_time=$(date +%s)
    
    for i in {1..5}; do
        (
            curl -s -X POST "${endpoint}/v1/completions" \
                -H "Content-Type: application/json" \
                -d "{
                    \"model\": \"${TEST_MODEL}\",
                    \"prompt\": \"Test request $i: ${TEST_PROMPT}\",
                    \"max_tokens\": 20
                }" > /dev/null
        ) &
    done
    
    wait
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    print_success "Performance test completed in ${duration} seconds"
}

# Main test function
main() {
    echo "=== vLLM-Istio Stack Testing ==="
    echo
    
    # Set up cleanup trap
    trap cleanup EXIT
    
    # Test Kubernetes resources first
    if ! test_k8s_resources; then
        print_error "Kubernetes resources test failed"
        exit 1
    fi
    
    # Test Istio resources
    if ! test_istio_resources; then
        print_error "Istio resources test failed"
        exit 1
    fi
    
    # Get endpoint
    print_status "Getting service endpoint..."
    ENDPOINT=$(get_endpoint)
    print_status "Using endpoint: $ENDPOINT"
    
    # Wait a moment for the service to be ready
    print_status "Waiting for service to be ready..."
    sleep 10
    
    # Run API tests
    local test_failures=0
    
    if ! test_health "$ENDPOINT"; then
        ((test_failures++))
    fi
    
    if ! test_metrics "$ENDPOINT"; then
        ((test_failures++))
    fi
    
    if ! test_models "$ENDPOINT"; then
        ((test_failures++))
    fi
    
    if ! test_completions "$ENDPOINT"; then
        ((test_failures++))
    fi
    
    # Run performance test if basic tests pass
    if [ $test_failures -eq 0 ]; then
        performance_test "$ENDPOINT"
    fi
    
    echo
    if [ $test_failures -eq 0 ]; then
        print_success "All tests passed! 🎉"
        echo
        echo "Your vLLM-Istio stack is working correctly."
        echo "Endpoint: $ENDPOINT"
    else
        print_error "$test_failures test(s) failed"
        exit 1
    fi
}

# Run main function
main "$@"