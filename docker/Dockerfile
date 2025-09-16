FROM nvidia/cuda:12.1-devel-ubuntu22.04

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-dev \
    git \
    wget \
    curl \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user
RUN useradd --create-home --shell /bin/bash vllm
USER vllm
WORKDIR /home/vllm

# Copy requirements and install Python dependencies
COPY --chown=vllm:vllm requirements.txt .
RUN pip3 install --user --no-cache-dir -r requirements.txt

# Set PATH to include user installed packages
ENV PATH="/home/vllm/.local/bin:${PATH}"

# Create directories for models and cache
RUN mkdir -p /home/vllm/models /home/vllm/.cache

# Set default environment variables for vLLM
ENV HF_HOME=/home/vllm/.cache/huggingface
ENV TRANSFORMERS_CACHE=/home/vllm/.cache/transformers
ENV VLLM_WORKER_MULTIPROC_METHOD=spawn

# Expose the default vLLM port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Default command
CMD ["python3", "-m", "vllm.entrypoints.openai.api_server", \
     "--host", "0.0.0.0", \
     "--port", "8000", \
     "--model", "/home/vllm/models"]