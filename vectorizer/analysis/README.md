# DISKVOYEUR - Analysis Component

The analysis component provides tools for exploring and analyzing vector representations of filesystem data.

## Features

- **Clustering**: Group similar files based on vector similarity
- **Anomaly Detection**: Identify unusual files that don't fit expected patterns
- **Similarity Search**: Find files similar to a reference file
- **Duplicate Detection**: Identify identical or near-identical files
- **Pattern Mining**: Discover patterns in file organization
- **Time Series Analysis**: Analyze file changes over time

## Python API Usage

### Clustering

Group files into similar clusters:

```python
from vectorizer.analysis.py.clustering import cluster_files

# Example: Cluster files using K-means
clusters = cluster_files(vector_data, method='kmeans', n_clusters=5)

# Example: Use DBSCAN for density-based clustering
clusters = cluster_files(vector_data, method='dbscan', eps=0.3, min_samples=5)

# Example: Use hierarchical clustering
clusters = cluster_files(vector_data, method='hierarchical', n_clusters=8)

# Print cluster assignments
for cluster_id, file_paths in clusters.items():
    print(f"Cluster {cluster_id}: {len(file_paths)} files")
```

### Anomaly Detection

Identify unusual files in your filesystem:

```python
from vectorizer.analysis.py.anomaly_detection import detect_anomalies

# Example: Use isolation forest for anomaly detection
anomalies = detect_anomalies(vector_data, method='isolation_forest', contamination=0.05)

# Example: Use local outlier factor
anomalies = detect_anomalies(vector_data, method='lof', contamination=0.03)

print(f"Found {len(anomalies)} anomalous files")
```

### Similarity Search

Find files similar to a reference file:

```python
from vectorizer.analysis.py.similarity_search import find_similar_files

# Find similar files with cosine similarity
similar_files = find_similar_files('/path/to/reference.txt', vector_data, n=10, metric='cosine')

# Use alternative distance metrics
similar_files = find_similar_files('/path/to/reference.txt', vector_data, n=10, metric='euclidean')

for path, similarity in similar_files:
    print(f"{similarity:.4f}: {path}")
```

### Duplicate Detection

Find duplicate or near-duplicate files:

```python
from vectorizer.analysis.py.duplicate_detection import find_duplicates

# Find duplicates with high similarity threshold
duplicates = find_duplicates(vector_data, threshold=0.99, metric='cosine')

# Print duplicate groups
for i, duplicate_group in enumerate(duplicates):
    print(f"Duplicate group {i+1}: {len(duplicate_group)} files")
    for path in duplicate_group:
        print(f"  {path}")
```

### Pattern Mining

Discover patterns in filesystem organization:

```python
from vectorizer.analysis.py.pattern_mining import mine_patterns

# Extract patterns from filesystem structure
patterns = mine_patterns(vector_data, filesystem_structure)

# Access different types of patterns
dir_communities = patterns['directory_communities']
common_extensions = patterns['common_extensions']
filename_patterns = patterns['filename_patterns']

print(f"Found {len(dir_communities)} directory communities")
print(f"Most common file extensions: {common_extensions[:3]}")
```

### Time Series Analysis

Analyze file changes over time:

```python
from vectorizer.analysis.py.time_series_analysis import analyze_time_series

# Analyze temporal patterns
results = analyze_time_series(vector_data, metadata)

# Access time-based statistics
print(f"Newest file: {results['newest_file']}")
print(f"Oldest file: {results['oldest_file']}")
print(f"Most accessed file: {results['most_accessed_file']}")
```

## Command Line Usage

The analysis component includes command-line tools for quick analysis:

```bash
# Cluster files based on vector similarity
./py/analyze_vectors.sh vectors.csv cluster

# Find duplicate files
./py/analyze_vectors.sh vectors.csv duplicates

# Identify anomalous files
./py/analyze_vectors.sh vectors.csv anomalies

# Find patterns in file organization
./py/analyze_vectors.sh vectors.csv patterns

# Find files similar to a reference
./py/analyze_vectors.sh vectors.csv similar
```

## Integration

This component integrates with the other DISKVOYEUR components:

```bash
# Full analysis pipeline example
./collection/py/extended_collection.sh /path/to/files > raw_data.txt
./extraction/py/extract_features.sh raw_data.txt > vectors.csv
./analysis/py/analyze_vectors.sh vectors.csv cluster > clusters.txt
./visualization/py/visualize_vectors.sh vectors.csv scatter clusters.png
```

## Dependencies

- NumPy
- scikit-learn
- NetworkX
- python-louvain (community module)
- pandas
