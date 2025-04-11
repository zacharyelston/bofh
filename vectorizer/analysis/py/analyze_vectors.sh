#!/bin/bash
# analyze_vectors.sh - Analyze vector data from the command line

# Parse arguments
vector_file="$1"
analysis_type="$2"
output_format="${3:-text}"

if [ -z "$vector_file" ] || [ -z "$analysis_type" ]; then
    echo "Usage: $0 <vector_file> <analysis_type> [output_format]"
    echo "Analysis types: cluster, duplicates, anomalies, patterns, similar"
    echo "Output formats: text, json, csv"
    exit 1
fi

case "$analysis_type" in
    cluster)
        # Simple clustering based on vector similarity
        python -c "
import numpy as np
import sys
import json
from sklearn.cluster import KMeans

vectors = np.loadtxt('$vector_file', delimiter=',', skiprows=1)
paths = [line.split(',')[0] for line in open('$vector_file').readlines()[1:]]
n_clusters = min(10, len(vectors))

if len(vectors) > 0:
    kmeans = KMeans(n_clusters=n_clusters)
    labels = kmeans.fit_predict(vectors[:, 1:])
    
    clusters = {}
    for path, label in zip(paths, labels):
        if label not in clusters:
            clusters[label] = []
        clusters[label].append(path)
    
    if '$output_format' == 'json':
        print(json.dumps(clusters, indent=2))
    else:
        for label, cluster_paths in clusters.items():
            print(f'Cluster {label} ({len(cluster_paths)} files):')
            for path in cluster_paths[:5]:
                print(f'  {path}')
            if len(cluster_paths) > 5:
                print(f'  ... and {len(cluster_paths) - 5} more')
            print()
else:
    print('No vectors found in file')
"
        ;;
        
    duplicates)
        # Find near-duplicate files
        python -c "
import numpy as np
import sys
import json
from sklearn.metrics.pairwise import cosine_similarity

vectors = np.loadtxt('$vector_file', delimiter=',', skiprows=1)
paths = [line.split(',')[0] for line in open('$vector_file').readlines()[1:]]

duplicates = []
threshold = 0.95

for i in range(len(vectors)):
    for j in range(i+1, len(vectors)):
        similarity = cosine_similarity(vectors[i:i+1, 1:], vectors[j:j+1, 1:])[0][0]
        if similarity >= threshold:
            duplicates.append((paths[i], paths[j], similarity))

if '$output_format' == 'json':
    print(json.dumps(duplicates, indent=2))
else:
    for path1, path2, similarity in duplicates:
        print(f'Similarity: {similarity:.4f}')
        print(f'  {path1}')
        print(f'  {path2}')
        print()
"
        ;;
        
    anomalies)
        # Find anomalous files
        python -c "
import numpy as np
import sys
import json
from sklearn.ensemble import IsolationForest

vectors = np.loadtxt('$vector_file', delimiter=',', skiprows=1)
paths = [line.split(',')[0] for line in open('$vector_file').readlines()[1:]]

if len(vectors) > 10:
    detector = IsolationForest(contamination=0.05)
    labels = detector.fit_predict(vectors[:, 1:])
    
    anomalies = [path for path, label in zip(paths, labels) if label == -1]
    
    if '$output_format' == 'json':
        print(json.dumps(anomalies, indent=2))
    else:
        print(f'Found {len(anomalies)} anomalous files:')
        for path in anomalies:
            print(f'  {path}')
else:
    print('Not enough vectors for anomaly detection')
"
        ;;
        
    patterns)
        # Find patterns in file organization
        python -c "
import numpy as np
import sys
import json
import os
from collections import Counter

vectors = np.loadtxt('$vector_file', delimiter=',', skiprows=1)
paths = [line.split(',')[0] for line in open('$vector_file').readlines()[1:]]

patterns = {}

# Directory patterns
dir_counter = Counter()
for path in paths:
    dir_path = os.path.dirname(path)
    dir_counter[dir_path] += 1

patterns['common_directories'] = dir_counter.most_common(10)

# Extension patterns
ext_counter = Counter()
for path in paths:
    ext = os.path.splitext(path)[1]
    if ext:
        ext_counter[ext] += 1

patterns['common_extensions'] = ext_counter.most_common(10)

if '$output_format' == 'json':
    print(json.dumps(patterns, indent=2))
else:
    print('Common directories:')
    for dir_path, count in patterns['common_directories']:
        print(f'  {dir_path}: {count} files')
    print()
    
    print('Common extensions:')
    for ext, count in patterns['common_extensions']:
        print(f'  {ext}: {count} files')
"
        ;;
        
    similar)
        # Find files similar to a reference file
        echo "Enter reference file path:"
        read ref_path
        
        python -c "
import numpy as np
import sys
import json
from sklearn.metrics.pairwise import cosine_similarity

vectors = np.loadtxt('$vector_file', delimiter=',', skiprows=1)
paths = [line.split(',')[0] for line in open('$vector_file').readlines()[1:]]

ref_path = '$ref_path'
if ref_path not in paths:
    print(f'Reference path not found: {ref_path}')
    sys.exit(1)

ref_index = paths.index(ref_path)
ref_vector = vectors[ref_index, 1:]

similarities = []
for i, path in enumerate(paths):
    if i == ref_index:
        continue
    
    similarity = cosine_similarity(ref_vector.reshape(1, -1), vectors[i, 1:].reshape(1, -1))[0][0]
    similarities.append((path, similarity))

similarities.sort(key=lambda x: x[1], reverse=True)
top_similarities = similarities[:10]

if '$output_format' == 'json':
    print(json.dumps(top_similarities, indent=2))
else:
    print(f'Files similar to {ref_path}:')
    for path, similarity in top_similarities:
        print(f'  {similarity:.4f}: {path}')
"
        ;;
        
    *)
        echo "Unknown analysis type: $analysis_type"
        echo "Available types: cluster, duplicates, anomalies, patterns, similar"
        exit 1
        ;;
esac
