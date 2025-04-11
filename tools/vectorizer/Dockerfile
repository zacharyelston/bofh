FROM python:3.9-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    tar \
    gzip \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
RUN pip install --no-cache-dir \
    numpy \
    pandas \
    scikit-learn \
    matplotlib \
    seaborn \
    plotly \
    networkx \
    python-louvain \
    umap-learn

# Copy DISKVOYEUR code
COPY . /app/

# Create directories for input/output and logs
RUN mkdir -p /data/input /data/output /logs

# Install the vectorizer package in development mode
RUN pip install -e .

# Create entrypoint script with logging
RUN echo '#!/bin/bash\n\
LOG_DIR="/logs"\n\
mkdir -p "$LOG_DIR"\n\
TIMESTAMP=$(date +%Y%m%d_%H%M%S)\n\
\n\
if [ "$1" = "analyze" ]; then\n\
  echo "Analyzing files in /data/input..."\n\
  python /app/py/analyze_filesystem.py 2>&1 | tee "$LOG_DIR/analyze_$TIMESTAMP.log"\n\
elif [ "$1" = "visualize" ]; then\n\
  echo "Visualizing results..."\n\
  python /app/py/visualize_results.py 2>&1 | tee "$LOG_DIR/visualize_$TIMESTAMP.log"\n\
else\n\
  echo "Available commands:"\n\
  echo "  analyze - Analyze files in /data/input"\n\
  echo "  visualize - Visualize analysis results"\n\
fi' > /app/entrypoint.sh && chmod +x /app/entrypoint.sh

ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["analyze"]
