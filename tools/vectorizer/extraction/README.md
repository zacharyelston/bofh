# DISKVOYEUR - Feature Extraction Component

This component transforms raw filesystem data into vector representations across multiple dimensions.

## Feature Types

### Path-Based Features

Features derived from the file path structure:

```python
from vectorizer.extraction.py.path_features import extract_path_features

# Extract path-based features
features = extract_path_features('/home/user/documents/report.pdf')

# Example features
print(f"Directory depth: {features['depth']}")
print(f"Filename length: {features['filename_length']}")
print(f"Has extension: {features['has_extension']}")
print(f"Is hidden: {features['is_hidden']}")
```

Key path features include:
- Directory depth
- Filename length
- Extension presence
- Hidden file status
- Path part analysis

### Metadata Features

Features based on file metadata:

```python
from vectorizer.extraction.py.metadata_features import extract_metadata_features

# Sample metadata from stat
stat_data = {
    'size': 1024,
    'modified': 1625678901,
    'atime': 1625678950,
    'permissions': 'rw-r--r--'
}

# Extract metadata features
features = extract_metadata_features(stat_data)

# Example features
print(f"Log size: {features['size']}")
print(f"Age in days: {features['age']}")
print(f"User read permission: {features['user_r']}")
```

Key metadata features include:
- Size (log-scaled)
- Age and access recency
- Permission bits (one-hot encoded)

### Content-Based Features

Features derived from file content:

```python
from vectorizer.extraction.py.content_features import extract_content_features, calculate_entropy

# Sample content and hash
content_sample = b'\x89PNG\r\n\x1a\n\x00\x00\x00'
content_hash = 'a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6'

# Extract content features
features = extract_content_features('/path/to/image.png', content_hash, content_sample)

# Example features
print(f"Hash prefix: {features['hash_prefix']}")
print(f"Is text file: {features['is_text']}")
print(f"Is image: {features['is_image']}")
```

Key content features include:
- Hash-based features
- Content entropy
- Text vs binary classification
- MIME type features

### Relationship Features

Features based on filesystem relationships:

```python
from vectorizer.extraction.py.relationship_features import extract_relationship_features

# Sample filesystem data (list of all files)
filesystem_data = [
    '/home/user/docs/report.pdf',
    '/home/user/docs/data.csv',
    '/home/user/docs/image.png',
    '/home/user/pics/vacation.jpg'
]

# Extract relationship features
features = extract_relationship_features('/home/user/docs/report.pdf', filesystem_data)

# Example features
print(f"Sibling count: {features['sibling_count']}")
print(f"Directory size ratio: {features['dir_size_ratio']}")
print(f"Same-extension siblings: {features['same_ext_siblings']}")
```

Key relationship features include:
- Directory sibling count
- Directory size relative to parent
- Extension siblings

## Dimensionality Reduction

For high-dimensional data, apply dimensionality reduction:

```python
from vectorizer.extraction.py.dimensionality_reduction import reduce_dimensions
import numpy as np

# Sample feature matrix
feature_matrix = np.random.rand(100, 20)  # 100 files, 20 features

# Reduce dimensions with PCA
reduced_pca = reduce_dimensions(feature_matrix, method='pca', dimensions=5)
print(f"Reduced from {feature_matrix.shape} to {reduced_pca.shape}")

# Reduce dimensions with t-SNE
reduced_tsne = reduce_dimensions(feature_matrix, method='tsne', dimensions=2)
print(f"Reduced to 2D for visualization: {reduced_tsne.shape}")
```

## Feature Normalization

Normalize features to ensure proper weighting:

```python
from vectorizer.extraction.py.feature_normalization import normalize_features

# Normalize using StandardScaler (zero mean, unit variance)
normalized_standard = normalize_features(feature_matrix, method='standard')

# Normalize using MinMaxScaler (0-1 range)
normalized_minmax = normalize_features(feature_matrix, method='minmax')
```

## Feature Selection

Select most informative features:

```python
from vectorizer.extraction.py.feature_selection import select_features

# Select features based on variance
selected_variance = select_features(feature_matrix, method='variance')

# Select features using supervised method (if you have labels)
labels = np.random.randint(0, 3, 100)  # Example labels for files
selected_kbest = select_features(feature_matrix, target=labels, method='kbest', k=10)
```

## Text Extraction

For text-based content, extract semantic features:

```python
from vectorizer.extraction.py.text_extraction import extract_text_features

# Extract TF-IDF features from text file
text_features = extract_text_features('/path/to/document.txt', max_features=100)
```

## Command Line Extraction

Extract features from the command line:

```bash
# Basic feature extraction from raw metadata
./py/extract_features.sh raw_metadata.txt > feature_vectors.csv

# Pipe directly from collection component
./collection/py/basic_collection.sh /path | ./py/extract_features.sh > vectors.csv
```

## Integration

This component connects to both the data collection and analysis components:

```bash
# Full pipeline example
./collection/py/extended_collection.sh /path | ./py/extract_features.sh | ./analysis/py/analyze_vectors.sh cluster
```

## Dependencies

- NumPy
- scikit-learn
- Pandas (for some operations)
