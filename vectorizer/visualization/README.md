# DISKVOYEUR - Visualization Component

The visualization component transforms vector data into visual representations for analysis and exploration.

## 2D Projections

Convert high-dimensional vectors to 2D for visualization:

```python
from vectorizer.visualization.py.projection import project_to_2d
import numpy as np

# Sample data: 100 files with 20-dimensional vectors
vectors = np.random.rand(100, 20)

# Project using t-SNE (best for visualizing clusters)
coords_tsne = project_to_2d(vectors, method='tsne', perplexity=30)
print(f"Created 2D t-SNE projection with shape {coords_tsne.shape}")

# Project using PCA (faster, preserves global structure)
coords_pca = project_to_2d(vectors, method='pca')
print(f"Created 2D PCA projection with shape {coords_pca.shape}")

# Project using UMAP (balance between local and global structure)
coords_umap = project_to_2d(vectors, method='umap', n_neighbors=15, min_dist=0.1)
print(f"Created 2D UMAP projection with shape {coords_umap.shape}")
```

## Scatter Plots

Generate scatter plots of projected vectors:

```python
from vectorizer.visualization.py.scatter_plot import scatter_plot
import numpy as np

# Sample data: 2D coordinates and optional labels
coords = np.random.rand(100, 2)
labels = np.random.randint(0, 5, 100)  # Cluster assignments

# Basic scatter plot
fig = scatter_plot(coords, title="File Vector Space")

# Colored by cluster label
fig = scatter_plot(coords, labels=labels, title="Clustered Files", 
                  output_file="clusters.png")

# With file paths for reference
paths = [f"/path/to/file_{i}.txt" for i in range(100)]
fig = scatter_plot(coords, labels=labels, paths=paths, 
                  title="Filesystem Vector Space")
```

## Interactive Visualization

Create interactive plots for exploring the data:

```python
from vectorizer.visualization.py.interactive_visualization import interactive_scatter
import numpy as np
import os

# Sample data: 2D coordinates and metadata
coords = np.random.rand(100, 2)
paths = [f"/home/user/docs/file_{i}.txt" for i in range(100)]

# Create metadata for files
metadata = {}
for i, path in enumerate(paths):
    metadata[path] = {
        'size': np.random.randint(1000, 1000000),
        'modified': np.random.randint(1600000000, 1620000000),
        'permissions': 'rw-r--r--',
    }

# Create interactive visualization
fig = interactive_scatter(coords, metadata, output_file="interactive.html")
print("Created interactive visualization with hover data")
```

## Heatmaps

Create heatmaps for similarity matrices:

```python
from vectorizer.visualization.py.heatmap import similarity_heatmap
import numpy as np

# Sample data: vectors and paths
vectors = np.random.rand(100, 20)
paths = [f"/path/to/file_{i}.txt" for i in range(100)]

# Create similarity heatmap
fig = similarity_heatmap(vectors, paths, max_files=50, 
                        output_file="similarity_heatmap.png")
```

## Hierarchical Visualizations

Visualize filesystem hierarchies:

```python
from vectorizer.visualization.py.hierarchy_graph import hierarchy_graph
import numpy as np

# Sample data: files with metadata
filesystem_data = {}
for i in range(50):
    dir_level = np.random.randint(1, 4)
    dir_path = '/'.join([f"dir_{np.random.randint(1, 5)}" for _ in range(dir_level)])
    path = f"/{dir_path}/file_{i}.txt"
    filesystem_data[path] = {
        'size': np.random.randint(1000, 1000000),
        'modified': np.random.randint(1600000000, 1620000000),
    }

# Create hierarchy graph
G, fig = hierarchy_graph(filesystem_data, output_file="filesystem_graph.png")
print(f"Created graph with {G.number_of_nodes()} nodes and {G.number_of_edges()} edges")
```

## Timeline Visualizations

Visualize file changes over time:

```python
from vectorizer.visualization.py.timeline import timeline_visualization
import numpy as np
from datetime import datetime, timedelta

# Sample data: files with timestamps
metadata = {}
base_time = datetime.now().timestamp() - (30 * 86400)  # 30 days ago
for i in range(100):
    days_offset = np.random.randint(0, 30)
    timestamp = base_time + (days_offset * 86400)
    path = f"/path/to/file_{i}.txt"
    metadata[path] = {
        'modified': timestamp,
        'size': np.random.randint(1000, 1000000),
    }

# Create timeline visualization
fig = timeline_visualization(metadata, output_file="timeline.png")
```

## Command Line Visualization

Generate visualizations from the command line:

```bash
# Create a scatter plot of projected vectors
./py/visualize_vectors.sh vectors.csv scatter filesystem_scatter.png

# Create a heatmap of file similarities
./py/visualize_vectors.sh vectors.csv heatmap similarity_heatmap.png

# Create histograms of feature distributions
./py/visualize_vectors.sh vectors.csv histogram feature_histograms.png

# Create a timeline visualization
./py/visualize_vectors.sh vectors.csv timeline timeline.png

# Create a graph visualization of file relationships
./py/visualize_vectors.sh vectors.csv graph relationship_graph.png
```

## Integration

This component integrates with the analysis component to visualize results:

```bash
# Full visualization pipeline example
./collection/py/extended_collection.sh /path | ./extraction/py/extract_features.sh > vectors.csv
./analysis/py/analyze_vectors.sh vectors.csv cluster > clusters.txt
./py/visualize_vectors.sh vectors.csv scatter cluster_visualization.png
```

## Dependencies

- NumPy
- Matplotlib
- Seaborn
- Plotly (for interactive visualizations)
- scikit-learn (for projections)
- NetworkX, python-louvain (for graph visualizations)
- UMAP-learn (optional, for UMAP projections)
- Pandas (for data manipulations)
