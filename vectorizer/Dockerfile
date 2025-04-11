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

# Create directories for input/output
RUN mkdir -p /data/input /data/output

# Create entrypoint script
RUN echo '#!/bin/bash\n\
if [ "$1" = "analyze" ]; then\n\
  echo "Analyzing files in /data/input..."\n\
  python /app/py/analyze_filesystem.py\n\
elif [ "$1" = "visualize" ]; then\n\
  echo "Visualizing results..."\n\
  python /app/py/visualize_results.py\n\
else\n\
  echo "Available commands:"\n\
  echo "  analyze - Analyze files in /data/input"\n\
  echo "  visualize - Visualize analysis results"\n\
fi' > /app/entrypoint.sh && chmod +x /app/entrypoint.sh

ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["analyze"]
