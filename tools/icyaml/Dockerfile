# Platform-specific Dockerfile for Apple Silicon
# Using a multi-platform approach

FROM python:3.9-slim

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    graphviz \
    && rm -rf /var/lib/apt/lists/*

# Set up working directory
WORKDIR /app

# Copy requirements first for better layer caching
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy all scripts and tools
COPY *.py *.sh *.md /app/

# Make scripts executable
RUN chmod +x *.sh

# Set default command to display Python version and verify installation
CMD ["python3", "--version"]
