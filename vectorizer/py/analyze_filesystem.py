#!/usr/bin/env python3
"""
DISKVOYEUR filesystem analyzer

This script analyzes files in the /data/input directory and outputs results to /data/output.
"""

import os
import json
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from datetime import datetime
from sklearn.ensemble import IsolationForest
from sklearn.cluster import KMeans
from sklearn.metrics.pairwise import cosine_similarity
from sklearn.decomposition import PCA
from sklearn.manifold import TSNE

# Import DISKVOYEUR modules
from vectorizer.analysis.py.anomaly_detection import detect_anomalies
from vectorizer.analysis.py.clustering import cluster_files
from vectorizer.analysis.py.duplicate_detection import find_duplicates
from vectorizer.extraction.py.path_features import extract_path_features
from vectorizer.extraction.py.metadata_features import extract_metadata_features
from vectorizer.extraction.py.content_features import extract_content_features
from vectorizer.visualization.py.projection import project_to_2d
from vectorizer.visualization.py.scatter_plot import scatter_plot
from vectorizer.visualization.py.heatmap import similarity_heatmap

def collect_files(directory):
    """Collect all files in the directory recursively."""
    print(f"Collecting files from {directory}...")
    files = []
    for root, dirs, filenames in os.walk(directory):
        for filename in filenames:
            files.append(os.path.join(root, filename))
    print(f"Found {len(files)} files")
    return files

def extract_features(files):
    """Extract features from files."""
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
            
            # Extract path features
            path_features = extract_path_features(file_path)
            
            # Extract metadata features (simplified)
            metadata_features = {
                'size_log': np.log1p(stats.st_size),
                'age_days': (datetime.now().timestamp() - stats.st_mtime) / (24 * 3600),
                'depth': file_path.count('/'),
                'filename_length': len(os.path.basename(file_path)),
                'is_hidden': 1 if os.path.basename(file_path).startswith('.') else 0,
            }
            
            # Combine features
            features = {**metadata_features, **path_features}
            
            # Store data
            feature_data[file_path] = features
            metadata[file_path] = file_metadata
            
        except Exception as e:
            print(f"Error processing {file_path}: {e}")
    
    print(f"Extracted features for {len(feature_data)} files")
    return feature_data, metadata

def analyze_data(feature_data, metadata):
    """Analyze the feature data."""
    print("Analyzing data...")
    results = {}
    
    # Convert features to dataframe for easier manipulation
    df = pd.DataFrame.from_dict(feature_data, orient='index')
    
    # Normalize numerical features
    numeric_cols = df.select_dtypes(include=['float64', 'int64']).columns.tolist()
    for col in numeric_cols:
        if col != 'is_hidden':  # Skip binary features
            df[col] = (df[col] - df[col].mean()) / (df[col].std() or 1)
    
    # Create a dictionary mapping file paths to vectors
    vector_data = {path: df.loc[path].values for path in df.index}
    
    # 1. Anomaly Detection
    print("Detecting anomalies...")
    anomalies = detect_anomalies(vector_data, method='isolation_forest', contamination=0.05)
    results['anomalies'] = anomalies
    
    # 2. Clustering
    print("Clustering files...")
    n_clusters = min(10, len(vector_data))
    clusters = cluster_files(vector_data, method='kmeans', n_clusters=n_clusters)
    results['clusters'] = clusters
    
    # 3. Duplicate Detection
    print("Finding duplicates...")
    duplicates = find_duplicates(vector_data, threshold=0.95)
    results['duplicates'] = [list(d) for d in duplicates]  # Convert sets to lists for JSON serialization
    
    # 4. Projection to 2D
    print("Projecting to 2D...")
    vectors = np.array(list(vector_data.values()))
    paths = list(vector_data.keys())
    
    # PCA projection (faster)
    coords_pca = project_to_2d(vectors, method='pca')
    results['coords_pca'] = coords_pca.tolist()
    
    # t-SNE projection (better for visualization, but slower)
    if len(vectors) < 1000:  # Only do t-SNE for smaller datasets
        try:
            coords_tsne = project_to_2d(vectors, method='tsne')
            results['coords_tsne'] = coords_tsne.tolist()
        except Exception as e:
            print(f"Error with t-SNE projection: {e}")
    
    # Save paths for reference
    results['paths'] = paths
    
    # Save metadata
    results['metadata'] = metadata
    
    # Feature importance
    results['feature_names'] = df.columns.tolist()
    
    # Basic statistics
    results['stats'] = {
        'total_files': len(vector_data),
        'total_size': sum(metadata[path]['size'] for path in metadata),
        'anomaly_count': len(anomalies),
        'duplicate_groups': len(duplicates),
        'cluster_count': len(clusters),
    }
    
    return results

def visualize_results(results, output_dir):
    """Create visualizations from analysis results."""
    print("Creating visualizations...")
    os.makedirs(output_dir, exist_ok=True)
    
    # 1. PCA Scatter Plot
    if 'coords_pca' in results and 'paths' in results:
        coords = np.array(results['coords_pca'])
        paths = results['paths']
        
        # Color by anomaly status
        labels = np.zeros(len(paths))
        for i, path in enumerate(paths):
            if path in results['anomalies']:
                labels[i] = 1
        
        plt.figure(figsize=(12, 10))
        scatter_plot(coords, labels=labels, title='File Vector Space (PCA)', 
                    output_file=os.path.join(output_dir, 'pca_scatter.png'))
        
    # 2. t-SNE Scatter Plot
    if 'coords_tsne' in results and 'paths' in results:
        coords = np.array(results['coords_tsne'])
        paths = results['paths']
        
        # Color by cluster
        cluster_labels = np.zeros(len(paths))
        for cluster_id, cluster_paths in results['clusters'].items():
            for path in cluster_paths:
                if path in paths:
                    cluster_labels[paths.index(path)] = int(cluster_id)
        
        plt.figure(figsize=(12, 10))
        scatter_plot(coords, labels=cluster_labels, title='File Clusters (t-SNE)', 
                    output_file=os.path.join(output_dir, 'tsne_clusters.png'))
    
    # 3. Heatmap of similar files
    if 'paths' in results and len(results['paths']) < 100:
        vectors = np.array([np.array(results['coords_pca'])[i] for i in range(len(results['paths']))])
        similarity_heatmap(vectors, results['paths'], max_files=50, 
                          output_file=os.path.join(output_dir, 'similarity_heatmap.png'))
    
    # 4. File size distribution
    if 'metadata' in results:
        sizes = [results['metadata'][path]['size'] for path in results['paths']]
        plt.figure(figsize=(12, 6))
        plt.hist(np.log1p(sizes), bins=50, alpha=0.7)
        plt.title('File Size Distribution (log scale)')
        plt.xlabel('Log File Size')
        plt.ylabel('Count')
        plt.tight_layout()
        plt.savefig(os.path.join(output_dir, 'size_distribution.png'))
    
    # 5. File modification time distribution
    if 'metadata' in results:
        mod_times = [results['metadata'][path]['modified'] for path in results['paths']]
        plt.figure(figsize=(12, 6))
        plt.hist(mod_times, bins=50, alpha=0.7)
        plt.title('File Modification Time Distribution')
        plt.xlabel('Modification Time (Unix Timestamp)')
        plt.ylabel('Count')
        plt.tight_layout()
        plt.savefig(os.path.join(output_dir, 'mod_time_distribution.png'))
    
    # 6. Summary report
    report = {
        'timestamp': datetime.now().isoformat(),
        'stats': results['stats'],
        'anomalies': results['anomalies'][:10],  # Show top 10 anomalies
        'duplicate_groups': results['duplicates'][:5],  # Show top 5 duplicate groups
        'clusters': {k: v[:5] for k, v in results['clusters'].items()},  # Show first 5 files per cluster
    }
    
    with open(os.path.join(output_dir, 'summary_report.json'), 'w') as f:
        json.dump(report, f, indent=2)
    
    # Create HTML report
    html_report = f"""<!DOCTYPE html>
<html>
<head>
    <title>DISKVOYEUR Analysis Report</title>
    <style>
        body {{ font-family: Arial, sans-serif; margin: 20px; }}
        h1, h2 {{ color: #333; }}
        .stats {{ display: flex; flex-wrap: wrap; }}
        .stat-box {{ background: #f5f5f5; border-radius: 5px; padding: 15px; margin: 10px; min-width: 200px; }}
        .list {{ max-height: 300px; overflow-y: auto; }}
        img {{ max-width: 100%; border: 1px solid #ddd; margin: 10px 0; }}
    </style>
</head>
<body>
    <h1>DISKVOYEUR Analysis Report</h1>
    <p>Analysis completed: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}</p>
    
    <h2>Statistics</h2>
    <div class="stats">
        <div class="stat-box">
            <h3>Total Files</h3>
            <p>{results['stats']['total_files']}</p>
        </div>
        <div class="stat-box">
            <h3>Total Size</h3>
            <p>{results['stats']['total_size'] / (1024*1024):.2f} MB</p>
        </div>
        <div class="stat-box">
            <h3>Anomalies</h3>
            <p>{results['stats']['anomaly_count']}</p>
        </div>
        <div class="stat-box">
            <h3>Duplicate Groups</h3>
            <p>{results['stats']['duplicate_groups']}</p>
        </div>
    </div>
    
    <h2>Visualizations</h2>
    <div>
        <h3>File Vector Space (PCA)</h3>
        <img src="pca_scatter.png" alt="PCA Scatter Plot" />
        
        <h3>File Clusters (t-SNE)</h3>
        <img src="tsne_clusters.png" alt="t-SNE Clusters" />
        
        <h3>File Similarity Heatmap</h3>
        <img src="similarity_heatmap.png" alt="Similarity Heatmap" />
        
        <h3>File Size Distribution</h3>
        <img src="size_distribution.png" alt="Size Distribution" />
        
        <h3>File Modification Time Distribution</h3>
        <img src="mod_time_distribution.png" alt="Modification Time Distribution" />
    </div>
    
    <h2>Anomalous Files</h2>
    <div class="list">
        <ul>
            {"".join(f"<li>{path}</li>" for path in results['anomalies'][:20])}
        </ul>
    </div>
    
    <h2>Duplicate File Groups</h2>
    <div class="list">
        {"".join(f"<h3>Group {i+1}</h3><ul>{''.join(f'<li>{path}</li>' for path in group[:5])}</ul>" for i, group in enumerate(results['duplicates'][:5]))}
    </div>
    
    <h2>File Clusters</h2>
    <div class="list">
        {"".join(f"<h3>Cluster {cluster_id}</h3><ul>{''.join(f'<li>{path}</li>' for path in paths[:5])}</ul>" for cluster_id, paths in results['clusters'].items())}
    </div>
</body>
</html>
"""
    
    with open(os.path.join(output_dir, 'report.html'), 'w') as f:
        f.write(html_report)
    
    print(f"Visualizations saved to {output_dir}")

def main():
    """Main function."""
    input_dir = '/data/input'
    output_dir = '/data/output'
    
    print(f"DISKVOYEUR Analysis")
    print(f"==================")
    
    # Make sure output directory exists
    os.makedirs(output_dir, exist_ok=True)
    
    # Collect files
    files = collect_files(input_dir)
    
    # If no files found, exit
    if not files:
        print("No files found in input directory.")
        return
    
    # Extract features
    feature_data, metadata = extract_features(files)
    
    # Analyze data
    results = analyze_data(feature_data, metadata)
    
    # Save results
    with open(os.path.join(output_dir, 'analysis_results.json'), 'w') as f:
        # Convert NumPy arrays to lists for JSON serialization
        for key in results:
            if isinstance(results[key], np.ndarray):
                results[key] = results[key].tolist()
        json.dump(results, f)
    
    # Visualize results
    visualize_results(results, output_dir)
    
    print("Analysis complete. Results saved to output directory.")

if __name__ == "__main__":
    main()
