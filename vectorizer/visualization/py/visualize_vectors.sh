#!/bin/bash
# visualize_vectors.sh - Generate visualizations from vector data

# Parse arguments
vector_file="$1"
visualization_type="$2"
output_file="${3:-visualization.png}"

if [ -z "$vector_file" ] || [ -z "$visualization_type" ]; then
    echo "Usage: $0 <vector_file> <visualization_type> [output_file]"
    echo "Visualization types: scatter, heatmap, histogram, timeline, graph"
    echo "Default output file: visualization.png"
    exit 1
fi

case "$visualization_type" in
    scatter)
        # Create a scatter plot of 2D projected vectors
        python -c "
import numpy as np
import matplotlib.pyplot as plt
from sklearn.decomposition import PCA
import os

# Load vector data
vectors = np.loadtxt('$vector_file', delimiter=',', skiprows=1)
paths = [line.split(',')[0] for line in open('$vector_file').readlines()[1:]]

# Project to 2D
if vectors.shape[1] > 3:  # Need at least 3 columns (path, x, y)
    pca = PCA(n_components=2)
    coords = pca.fit_transform(vectors[:, 1:])
    
    # Create scatter plot
    plt.figure(figsize=(12, 10))
    
    # Color by file extension
    extensions = [os.path.splitext(path)[1] if '.' in os.path.basename(path) else 'no_ext' for path in paths]
    unique_exts = list(set(extensions))
    colors = plt.cm.tab20(np.linspace(0, 1, len(unique_exts)))
    ext_to_color = {ext: colors[i] for i, ext in enumerate(unique_exts)}
    
    for ext in unique_exts:
        mask = [e == ext for e in extensions]
        if any(mask):
            plt.scatter(coords[mask, 0], coords[mask, 1], 
                        color=ext_to_color[ext], label=ext,
                        alpha=0.7, s=50)
    
    plt.legend(title='File Extension')
    plt.title('Filesystem Vector Space')
    plt.tight_layout()
    plt.savefig('$output_file', dpi=300, bbox_inches='tight')
    print(f'Saved scatter plot to $output_file')
else:
    print('Not enough dimensions in vector data for scatter plot')
"
        ;;
        
    heatmap)
        # Create a heatmap of file similarities
        python -c "
import numpy as np
import matplotlib.pyplot as plt
from sklearn.metrics.pairwise import cosine_similarity
import seaborn as sns

# Load vector data
vectors = np.loadtxt('$vector_file', delimiter=',', skiprows=1)
paths = [line.split(',')[0] for line in open('$vector_file').readlines()[1:]]

# Limit number of files for readability
max_files = 100
if len(vectors) > max_files:
    indices = np.random.choice(len(vectors), max_files, replace=False)
    vectors = vectors[indices]
    paths = [paths[i] for i in indices]

# Calculate similarity matrix
sim_matrix = cosine_similarity(vectors[:, 1:])

# Create heatmap
plt.figure(figsize=(12, 10))
heatmap = sns.heatmap(sim_matrix, xticklabels=False, yticklabels=False)
plt.title(f'File Similarity Heatmap ({len(paths)} files)')
plt.tight_layout()
plt.savefig('$output_file', dpi=300, bbox_inches='tight')
print(f'Saved heatmap to $output_file')
"
        ;;
        
    histogram)
        # Create histograms of vector dimensions
        python -c "
import numpy as np
import matplotlib.pyplot as plt

# Load vector data
data = np.loadtxt('$vector_file', delimiter=',', skiprows=1)
header = open('$vector_file').readline().strip().split(',')

# Skip the path column
data = data[:, 1:]
header = header[1:]

# Calculate number of rows and columns for subplots
n_dims = min(16, data.shape[1])  # Limit to 16 dimensions for readability
n_cols = 4
n_rows = (n_dims + n_cols - 1) // n_cols

plt.figure(figsize=(15, 10))
for i in range(n_dims):
    plt.subplot(n_rows, n_cols, i+1)
    plt.hist(data[:, i], bins=20, alpha=0.7)
    if i < len(header):
        plt.title(header[i], fontsize=10)
    plt.tick_params(axis='both', which='major', labelsize=8)

plt.tight_layout()
plt.savefig('$output_file', dpi=300, bbox_inches='tight')
print(f'Saved histograms to $output_file')
"
        ;;
        
    timeline)
        # Create a timeline visualization
        python -c "
import numpy as np
import matplotlib.pyplot as plt
import pandas as pd
from datetime import datetime
import os

# Load vector data
data = np.loadtxt('$vector_file', delimiter=',', skiprows=1)
header = open('$vector_file').readline().strip().split(',')
paths = [line.split(',')[0] for line in open('$vector_file').readlines()[1:]]

# Find timestamp column
time_col = -1
for i, col in enumerate(header):
    if 'time' in col.lower() or 'date' in col.lower() or 'modified' in col.lower():
        time_col = i
        break

if time_col >= 0:
    # Create dataframe
    df = pd.DataFrame({
        'path': paths,
        'timestamp': data[:, time_col],
        'extension': [os.path.splitext(path)[1] if '.' in path else '' for path in paths]
    })
    
    # Convert timestamp to datetime
    df['date'] = df['timestamp'].apply(lambda x: datetime.fromtimestamp(x))
    
    # Group by day
    df['day'] = df['date'].dt.date
    daily_counts = df.groupby('day').size()
    
    # Group by extension
    ext_counts = df.groupby('extension').size().sort_values(ascending=False)
    
    # Create plot
    fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(12, 10))
    
    # Timeline
    ax1.bar(daily_counts.index, daily_counts.values, alpha=0.7)
    ax1.set_title('Files by Day')
    ax1.set_ylabel('Number of Files')
    ax1.grid(True, alpha=0.3)
    
    # Extension distribution
    top_n = 10
    ext_counts_top = ext_counts.head(top_n)
    ax2.bar(ext_counts_top.index, ext_counts_top.values, alpha=0.7)
    ax2.set_title(f'Top {top_n} File Extensions')
    ax2.set_ylabel('Number of Files')
    ax2.grid(True, alpha=0.3)
    
    plt.tight_layout()
    plt.savefig('$output_file', dpi=300, bbox_inches='tight')
    print(f'Saved timeline to $output_file')
else:
    print('No timestamp column found in vector data')
"
        ;;
        
    graph)
        # Create a graph visualization of file relationships
        python -c "
import numpy as np
import matplotlib.pyplot as plt
import networkx as nx
from sklearn.metrics.pairwise import cosine_similarity
import os

# Load vector data
vectors = np.loadtxt('$vector_file', delimiter=',', skiprows=1)
paths = [line.split(',')[0] for line in open('$vector_file').readlines()[1:]]

# Limit number of files for readability
max_files = 50
if len(vectors) > max_files:
    indices = np.random.choice(len(vectors), max_files, replace=False)
    vectors = vectors[indices]
    paths = [paths[i] for i in indices]

# Calculate similarity matrix
sim_matrix = cosine_similarity(vectors[:, 1:])

# Create graph
G = nx.Graph()

# Add nodes
for i, path in enumerate(paths):
    G.add_node(i, path=path, extension=os.path.splitext(path)[1])

# Add edges for similar files (threshold = 0.8)
threshold = 0.8
for i in range(len(paths)):
    for j in range(i+1, len(paths)):
        if sim_matrix[i, j] > threshold:
            G.add_edge(i, j, weight=sim_matrix[i, j])

# Spring layout
pos = nx.spring_layout(G, seed=42)

# Color by extension
extensions = [G.nodes[n]['extension'] for n in G.nodes()]
unique_exts = list(set(extensions))
colors = plt.cm.tab20(np.linspace(0, 1, len(unique_exts)))
ext_to_color = {ext: colors[i] for i, ext in enumerate(unique_exts)}
node_colors = [ext_to_color[G.nodes[n]['extension']] for n in G.nodes()]

# Plot
plt.figure(figsize=(12, 10))
nx.draw_networkx(G, pos, 
                node_color=node_colors,
                node_size=100,
                with_labels=False,
                width=[G[u][v]['weight'] * 3 for u, v in G.edges()],
                alpha=0.7)

# Add legend
for ext, color in ext_to_color.items():
    plt.scatter([], [], color=color, label=ext)
plt.legend(title='File Extension')

plt.title('File Similarity Graph')
plt.axis('off')
plt.tight_layout()
plt.savefig('$output_file', dpi=300, bbox_inches='tight')
print(f'Saved graph to $output_file')
"
        ;;
        
    *)
        echo "Unknown visualization type: $visualization_type"
        echo "Available types: scatter, heatmap, histogram, timeline, graph"
        exit 1
        ;;
esac
