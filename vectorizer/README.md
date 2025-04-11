# DISKVOYEUR - Multi-Dimensional Filesystem Analysis

DISKVOYEUR is a toolkit for creating multi-dimensional views of filesystems through vector tables. It allows you to analyze, explore, and visualize your filesystem in ways that traditional tools cannot.

## Overview

Traditional filesystem tools like `ls`, `find`, and `du` provide only flat, one-dimensional views of your data. DISKVOYEUR expands this by creating vector representations across multiple dimensions including:

- File metadata (size, permissions, timestamps)
- Content fingerprints
- Directory structure relationships
- Content-based features
- Access patterns
- Namespace clustering

## Components

The DISKVOYEUR toolkit consists of several specialized components:

1. **Data Collection** - Tools for gathering raw filesystem data
2. **Feature Extraction** - Converting filesystem properties into vectors
3. **Analysis Tools** - Finding patterns and relationships
4. **Visualization** - Multi-dimensional visualization of filesystem properties

See individual components' README files for detailed documentation.

## Quick Start Examples

### Basic Usage

```bash
# Generate basic vector representation of a filesystem
./collection/py/basic_collection.sh /home/user/documents > raw_data.txt
./extraction/py/extract_features.sh raw_data.txt > vectors.csv
```

### Finding Similar Files

```python
from vectorizer.analysis.py.similarity_search import find_similar_files
from vectorizer.extraction.py.content_features import extract_content_features
import pandas as pd

# Load vector data
vectors_df = pd.read_csv('vectors.csv')
vector_data = {row['path']: row[1:].values for _, row in vectors_df.iterrows()}

# Find similar files to a reference file
similar_files = find_similar_files('/home/user/documents/report.pdf', vector_data)

# Print the most similar files
for path, similarity in similar_files:
    print(f"{similarity:.4f}: {path}")
```

### Detecting Duplicate Files

```python
from vectorizer.analysis.py.duplicate_detection import find_duplicates

# Find duplicate files with 99% similarity threshold
duplicates = find_duplicates(vector_data, threshold=0.99)

# Print duplicate groups
for i, duplicate_group in enumerate(duplicates):
    print(f"Duplicate group {i+1}:")
    for path in duplicate_group:
        print(f"  {path}")
```

### Clustering Files

```python
from vectorizer.analysis.py.clustering import cluster_files

# Cluster files using K-means with 5 clusters
clusters = cluster_files(vector_data, method='kmeans', n_clusters=5)

# Print cluster assignments
for cluster_id, file_paths in clusters.items():
    print(f"Cluster {cluster_id} ({len(file_paths)} files):")
    for path in file_paths[:5]:  # Show first 5 files in each cluster
        print(f"  {path}")
    if len(file_paths) > 5:
        print(f"  ... and {len(file_paths) - 5} more files")
```

### Detecting Anomalous Files

```python
from vectorizer.analysis.py.anomaly_detection import detect_anomalies

# Find unusual files using isolation forest
anomalies = detect_anomalies(vector_data, method='isolation_forest', contamination=0.05)

# Print anomalous files
print(f"Found {len(anomalies)} anomalous files:")
for path in anomalies:
    print(f"  {path}")
```

### Visualizing the Vector Space

```python
from vectorizer.visualization.py.projection import project_to_2d
from vectorizer.visualization.py.scatter_plot import scatter_plot
import numpy as np

# Project vectors to 2D
vectors = np.array(list(vector_data.values()))
coords = project_to_2d(vectors, method='tsne')

# Create scatter plot
paths = list(vector_data.keys())
scatter_plot(coords, title='File Vector Space', output_file='vector_space.png')
```

### Command Line Analysis Pipeline

```bash
# Full analysis pipeline example
./collection/py/extended_collection.sh /home/user/documents > raw_data.txt
./extraction/py/extract_features.sh raw_data.txt > vectors.csv
./analysis/py/analyze_vectors.sh vectors.csv cluster > clusters.txt
./visualization/py/visualize_vectors.sh vectors.csv scatter visualization.png
```

## Use Cases

- Identifying duplicate or near-duplicate files
- Finding related content across different directories
- Detecting anomalous files that don't match their context
- Optimizing storage based on content relationships
- Discovering hidden patterns in filesystem organization

## Component Documentation

- [Data Collection](./collection/README.md)
- [Feature Extraction](./extraction/README.md)
- [Analysis Tools](./analysis/README.md)
- [Visualization](./visualization/README.md)

## Installation

No installation is required - just clone the repository and make the shell scripts executable:

```bash
git clone https://github.com/yourusername/diskvoyeur.git
cd diskvoyeur
chmod +x */*.sh
```

Dependencies:
- Python 3.6+
- NumPy, Pandas
- scikit-learn
- Matplotlib, Seaborn
- Plotly (for interactive visualizations)
- NetworkX, python-louvain
- UMAP-learn (optional)

## Warning

DISKVOYEUR can be resource-intensive on large filesystems. For best performance:
1. Start with smaller directories
2. Adjust dimensionality settings
3. Use sampling for initial analysis
