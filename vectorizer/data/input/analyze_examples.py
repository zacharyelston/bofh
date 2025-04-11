#!/usr/bin/env python3
"""
Example script to analyze the sample files without Docker
"""
import os
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import json
from datetime import datetime
from sklearn.ensemble import IsolationForest
from sklearn.cluster import KMeans
from sklearn.decomposition import PCA
from sklearn.metrics.pairwise import cosine_similarity

def collect_files(directory):
    """Collect all files in the directory recursively."""
    print(f"Collecting files from {directory}...")
    files = []
    for root, dirs, filenames in os.walk(directory):
        for filename in filenames:
            # Skip this script itself
            if filename == 'analyze_examples.py':
                continue
            files.append(os.path.join(root, filename))
    print(f"Found {len(files)} files")
    return files

def extract_features(files):
    """Extract simple features from files."""
    print("Extracting features...")
    feature_data = {}
    metadata = {}
    
    for file_path in files:
        try:
            stats = os.stat(file_path)
            
            # Create metadata dictionary
            file_metadata = {
                'size': stats.st_size,
                'modified': stats.st_mtime,
                'accessed': stats.st_atime,
                'permissions': oct(stats.st_mode)[-3:],
            }
            
            # Extract features
            features = {
                'size_log': np.log1p(stats.st_size),
                'age_days': (datetime.now().timestamp() - stats.st_mtime) / (24 * 3600),
                'depth': file_path.count('/'),
                'filename_length': len(os.path.basename(file_path)),
                'is_hidden': 1 if os.path.basename(file_path).startswith('.') else 0,
                'path_parts': len(file_path.split('/')),
            }
            
            # Extract extension as numeric value
            _, ext = os.path.splitext(file_path)
            ext_hash = sum(ord(c) for c in ext) if ext else 0
            features['ext_hash'] = ext_hash / 1000  # Normalize
            
            # Content-based features
            try:
                with open(file_path, 'rb') as f:
                    content = f.read(4096)  # Read first 4KB
                    # Calculate entropy
                    if content:
                        hist = np.bincount(np.frombuffer(content, dtype=np.uint8), minlength=256)
                        hist = hist / hist.sum()
                        entropy = -np.sum(hist * np.log2(hist + 1e-10))
                        features['entropy'] = entropy
                    else:
                        features['entropy'] = 0
                    
                    # Text vs binary classification
                    is_text = True
                    for byte in content:
                        if byte == 0 or (byte > 127 and byte < 160):
                            is_text = False
                            break
                    features['is_text'] = 1 if is_text else 0
            except Exception as e:
                print(f"Error reading {file_path}: {e}")
                features['entropy'] = 0
                features['is_text'] = 0
            
            # Store data
            feature_data[file_path] = features
            metadata[file_path] = file_metadata
            
        except Exception as e:
            print(f"Error processing {file_path}: {e}")
    
    print(f"Extracted features for {len(feature_data)} files")
    return feature_data, metadata

def analyze_data(feature_data, metadata):
    """Simple analysis of feature data."""
    print("Analyzing data...")
    results = {}
    
    # Convert features to dataframe
    df = pd.DataFrame.from_dict(feature_data, orient='index')
    
    # Normalize features
    numeric_cols = df.select_dtypes(include=['float64', 'int64']).columns.tolist()
    for col in numeric_cols:
        if col != 'is_hidden' and col != 'is_text':  # Skip binary features
            df[col] = (df[col] - df[col].mean()) / (df[col].std() or 1)
    
    # Create vector data
    vector_data = {path: df.loc[path][numeric_cols].values for path in df.index}
    paths = list(vector_data.keys())
    vectors = np.array(list(vector_data.values()))
    
    # Anomaly detection
    print("Detecting anomalies...")
    detector = IsolationForest(contamination=0.20)  # Set higher to detect more anomalies in small sample
    labels = detector.fit_predict(vectors)
    anomalies = [path for path, label in zip(paths, labels) if label == -1]
    results['anomalies'] = anomalies
    
    # Clustering
    print("Clustering files...")
    n_clusters = min(3, len(vectors))  # Use 3 clusters for the example
    kmeans = KMeans(n_clusters=n_clusters)
    cluster_labels = kmeans.fit_predict(vectors)
    
    clusters = {}
    for path, label in zip(paths, cluster_labels):
        if str(label) not in clusters:
            clusters[str(label)] = []
        clusters[str(label)].append(path)
    results['clusters'] = clusters
    
    # Duplicate detection (simplified)
    print("Finding duplicates...")
    duplicates = []
    for i, path1 in enumerate(paths):
        for j in range(i+1, len(paths)):
            path2 = paths[j]
            # Simple similarity based on feature vectors
            similarity = cosine_similarity([vectors[i]], [vectors[j]])[0][0]
            if similarity > 0.95:  # High threshold for duplicates
                duplicates.append((path1, path2, similarity))
    results['duplicates'] = duplicates
    
    # Basic statistics
    results['stats'] = {
        'total_files': len(vector_data),
        'total_size': sum(metadata[path]['size'] for path in metadata),
        'anomaly_count': len(anomalies),
        'duplicate_pairs': len(duplicates),
        'cluster_count': len(clusters),
    }
    
    # Projection to 2D for visualization
    pca = PCA(n_components=2)
    coords = pca.fit_transform(vectors)
    results['coords'] = coords.tolist()
    
    return results, paths, vectors

def main():
    """Main function."""
    # Directory containing our examples
    directory = '.'
    
    # Collect files
    files = collect_files(directory)
    
    # Extract features
    feature_data, metadata = extract_features(files)
    
    # Analyze data
    results, paths, vectors = analyze_data(feature_data, metadata)
    
    # Display results
    print("\n=== ANALYSIS RESULTS ===\n")
    
    print(f"Total files analyzed: {results['stats']['total_files']}")
    print(f"Total size: {results['stats']['total_size'] / 1024:.2f} KB")
    
    print("\nAnomalies detected:")
    for path in results['anomalies']:
        print(f"  - {os.path.basename(path)}")
    
    print("\nClusters:")
    for cluster_id, cluster_paths in results['clusters'].items():
        print(f"  Cluster {cluster_id} ({len(cluster_paths)} files):")
        for path in cluster_paths:
            print(f"    - {os.path.basename(path)}")
    
    print("\nPotential duplicates:")
    for path1, path2, similarity in results['duplicates']:
        print(f"  {os.path.basename(path1)} and {os.path.basename(path2)}: {similarity:.2f} similarity")
    
    # Save results as JSON
    with open('example_results.json', 'w') as f:
        # Convert any NumPy types to native Python types
        json_results = {
            'anomalies': [os.path.basename(p) for p in results['anomalies']],
            'clusters': {k: [os.path.basename(p) for p in v] for k, v in results['clusters'].items()},
            'duplicates': [(os.path.basename(p1), os.path.basename(p2), float(s)) for p1, p2, s in results['duplicates']],
            'stats': results['stats']
        }
        json.dump(json_results, f, indent=2)
    
    print("\nResults saved to example_results.json")
    
    # Simple visualization
    try:
        # Create scatter plot
        plt.figure(figsize=(10, 8))
        coords = np.array(results['coords'])
        
        # Color points by anomaly status
        colors = ['blue' if path not in results['anomalies'] else 'red' for path in paths]
        
        plt.scatter(coords[:, 0], coords[:, 1], c=colors, alpha=0.7)
        
        # Add file names as labels
        for i, path in enumerate(paths):
            plt.annotate(os.path.basename(path), (coords[i, 0], coords[i, 1]))
        
        plt.title('File Vector Space')
        plt.xlabel('Component 1')
        plt.ylabel('Component 2')
        plt.legend(['Normal', 'Anomaly'])
        plt.tight_layout()
        plt.savefig('example_visualization.png')
        
        print("Visualization saved to example_visualization.png")
    except Exception as e:
        print(f"Error creating visualization: {e}")

if __name__ == "__main__":
    main()
