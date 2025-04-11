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
from analysis.py.anomaly_detection import detect_anomalies
from analysis.py.clustering import cluster_files
from analysis.py.duplicate_detection import find_duplicates
from extraction.py.path_features import extract_path_features
from extraction.py.metadata_features import extract_metadata_features
from extraction.py.content_features import extract_content_features
from visualization.py.projection import project_to_2d
from visualization.py.scatter_plot import scatter_plot
from visualization.py.heatmap import similarity_heatmap

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
                'size': float(stats.st_size),
                'modified': float(stats.st_mtime),
                'accessed': float(stats.st_atime),
                'permissions': oct(stats.st_mode)[-3:],
            }
            
            # Extract path features (ensure only numeric values)
            path_features = {}
            raw_path_features = extract_path_features(file_path)
            for key, value in raw_path_features.items():
                if isinstance(value, (int, float)):
                    path_features[key] = float(value)
            
            # Extract metadata features (simplified)
            metadata_features = {
                'size_log': float(np.log1p(stats.st_size)),
                'age_days': float((datetime.now().timestamp() - stats.st_mtime) / (24 * 3600)),
                'depth': float(file_path.count('/')),
                'filename_length': float(len(os.path.basename(file_path))),
                'is_hidden': float(1 if os.path.basename(file_path).startswith('.') else 0),
                'has_extension': float(1 if '.' in os.path.basename(file_path) else 0),
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
    
    # Ensure all columns are numeric
    numeric_cols = df.select_dtypes(include=['float64', 'int64', 'float32', 'int32']).columns.tolist()
    print(f"Using {len(numeric_cols)} numeric features: {numeric_cols}")
    
    # Remove any non-numeric columns
    df = df[numeric_cols]
    
    # Check for NaN values and fill with column means
    if df.isna().any().any():
        print("Warning: NaN values found in data. Filling with column means.")
        df = df.fillna(df.mean())
    
    # Normalize numerical features
    for col in df.columns:
        if col != 'is_hidden':  # Skip binary features
            if df[col].std() > 0:
                df[col] = (df[col] - df[col].mean()) / df[col].std()
            else:
                # If standard deviation is 0, just center the data
                df[col] = df[col] - df[col].mean()
    
    # Convert all values to native Python floats to avoid NumPy types
    df = df.astype(float)
    
    # Create a dictionary mapping file paths to vectors
    vector_data = {str(path): df.loc[path].values.tolist() for path in df.index}
    
    # Print shapes for debugging
    paths = list(vector_data.keys())
    vectors = np.array(list(vector_data.values()))
    print(f"Vector shape: {vectors.shape}")
    
    # 1. Anomaly Detection
    print("Detecting anomalies...")
    if vectors.shape[0] > 1 and vectors.shape[1] > 0:
        try:
            anomalies = detect_anomalies(vector_data, method='isolation_forest', contamination=0.05)
            results['anomalies'] = anomalies
        except Exception as e:
            print(f"Error during anomaly detection: {e}")
            results['anomalies'] = []
    else:
        print("Not enough data for anomaly detection.")
        results['anomalies'] = []
    
    # 2. Clustering
    print("Clustering files...")
    if vectors.shape[0] > 1 and vectors.shape[1] > 0:
        try:
            n_clusters = min(5, len(vector_data))
            clusters = cluster_files(vector_data, method='kmeans', n_clusters=n_clusters)
            results['clusters'] = clusters
        except Exception as e:
            print(f"Error during clustering: {e}")
            results['clusters'] = {"0": paths}
    else:
        print("Not enough data for clustering.")
        results['clusters'] = {"0": paths}
    
    # 3. Duplicate Detection
    print("Finding duplicates...")
    if vectors.shape[0] > 1 and vectors.shape[1] > 0:
        try:
            duplicates = find_duplicates(vector_data, threshold=0.95)
            results['duplicates'] = [list(d) for d in duplicates]  # Convert sets to lists for JSON serialization
        except Exception as e:
            print(f"Error during duplicate detection: {e}")
            results['duplicates'] = []
    else:
        print("Not enough data for duplicate detection.")
        results['duplicates'] = []
    
    # 4. Projection to 2D
    print("Projecting to 2D...")
    if vectors.shape[0] > 1 and vectors.shape[1] > 0:
        try:
            # PCA projection (faster)
            coords_pca = project_to_2d(vectors, method='pca')
            results['coords_pca'] = coords_pca.tolist()
            
            # t-SNE projection (better for visualization, but slower)
            if len(vectors) < 1000 and len(vectors) > 2:  # Only do t-SNE for smaller datasets
                try:
                    # Adjust perplexity based on dataset size
                    perplexity = min(30, len(vectors) - 1)
                    coords_tsne = project_to_2d(vectors, method='tsne', perplexity=perplexity)
                    results['coords_tsne'] = coords_tsne.tolist()
                except Exception as e:
                    print(f"Error with t-SNE projection: {e}")
                    results['coords_tsne'] = coords_pca.tolist()  # Fall back to PCA
            else:
                results['coords_tsne'] = coords_pca.tolist()  # Use PCA results for small datasets
        except Exception as e:
            print(f"Error during projection: {e}")
            # Create dummy projections
            dummy_coords = np.zeros((len(paths), 2))
            results['coords_pca'] = dummy_coords.tolist()
            results['coords_tsne'] = dummy_coords.tolist()
    else:
        print("Not enough data for projection.")
        # Create dummy projections
        dummy_coords = np.zeros((len(paths), 2))
        results['coords_pca'] = dummy_coords.tolist()
        results['coords_tsne'] = dummy_coords.tolist()
    
    # Save paths for reference
    results['paths'] = paths
    
    # Save metadata
    # Convert all keys and values to native Python types to avoid NumPy types
    metadata_safe = {}
    for path, meta in metadata.items():
        metadata_safe[str(path)] = {
            str(k): (float(v) if isinstance(v, (int, float, np.number)) else str(v))
            for k, v in meta.items()
        }
    results['metadata'] = metadata_safe
    
    # Feature importance
    results['feature_names'] = [str(col) for col in df.columns.tolist()]
    
    # Basic statistics
    results['stats'] = {
        'total_files': int(len(vector_data)),
        'total_size': float(sum(metadata[path]['size'] for path in metadata)),
        'anomaly_count': int(len(results.get('anomalies', []))),
        'duplicate_groups': int(len(results.get('duplicates', []))),
        'cluster_count': int(len(results.get('clusters', {}))),
    }
    
    return results

def visualize_results(results, output_dir):
    """Create visualizations from analysis results."""
    print("Creating visualizations...")
    os.makedirs(output_dir, exist_ok=True)
    
    # 1. PCA Scatter Plot
    if 'coords_pca' in results and 'paths' in results:
        try:
            coords = np.array(results['coords_pca'])
            paths = results['paths']
            
            # Color by anomaly status
            labels = np.zeros(len(paths))
            for i, path in enumerate(paths):
                if path in results.get('anomalies', []):
                    labels[i] = 1
            
            plt.figure(figsize=(12, 10))
            scatter_plot(coords, labels=labels, title='File Vector Space (PCA)', 
                        output_file=os.path.join(output_dir, 'pca_scatter.png'))
        except Exception as e:
            print(f"Error creating PCA scatter plot: {e}")
        
    # 2. t-SNE Scatter Plot
    if 'coords_tsne' in results and 'paths' in results:
        try:
            coords = np.array(results['coords_tsne'])
            paths = results['paths']
            
            # Color by cluster
            cluster_labels = np.zeros(len(paths))
            for cluster_id, cluster_paths in results.get('clusters', {}).items():
                for path in cluster_paths:
                    if path in paths:
                        try:
                            cluster_labels[paths.index(path)] = int(cluster_id)
                        except ValueError:
                            # If cluster_id is not convertible to int, use a default value
                            cluster_labels[paths.index(path)] = 0
            
            plt.figure(figsize=(12, 10))
            scatter_plot(coords, labels=cluster_labels, title='File Clusters (t-SNE)', 
                        output_file=os.path.join(output_dir, 'tsne_clusters.png'))
        except Exception as e:
            print(f"Error creating t-SNE scatter plot: {e}")
    
    # 3. Heatmap of similar files
    if 'paths' in results and len(results['paths']) < 100 and 'coords_pca' in results:
        try:
            vectors = np.array(results['coords_pca'])
            similarity_heatmap(vectors, results['paths'], max_files=min(50, len(results['paths'])), 
                            output_file=os.path.join(output_dir, 'similarity_heatmap.png'))
        except Exception as e:
            print(f"Error creating heatmap: {e}")
    
    # 4. File size distribution
    if 'metadata' in results and results['paths']:
        try:
            sizes = [results['metadata'][path]['size'] for path in results['paths']]
            plt.figure(figsize=(12, 6))
            plt.hist(np.log1p(sizes), bins=min(50, len(sizes)), alpha=0.7)
            plt.title('File Size Distribution (log scale)')
            plt.xlabel('Log File Size')
            plt.ylabel('Count')
            plt.tight_layout()
            plt.savefig(os.path.join(output_dir, 'size_distribution.png'))
        except Exception as e:
            print(f"Error creating size distribution plot: {e}")
    
    # 5. File modification time distribution
    if 'metadata' in results and results['paths']:
        try:
            mod_times = [results['metadata'][path]['modified'] for path in results['paths']]
            plt.figure(figsize=(12, 6))
            plt.hist(mod_times, bins=min(50, len(mod_times)), alpha=0.7)
            plt.title('File Modification Time Distribution')
            plt.xlabel('Modification Time (Unix Timestamp)')
            plt.ylabel('Count')
            plt.tight_layout()
            plt.savefig(os.path.join(output_dir, 'mod_time_distribution.png'))
        except Exception as e:
            print(f"Error creating modification time plot: {e}")
    
    # 6. Summary report
    report = {
        'timestamp': datetime.now().isoformat(),
        'stats': results['stats'],
        'anomalies': results.get('anomalies', [])[:10],  # Show top 10 anomalies
        'duplicate_groups': results.get('duplicates', [])[:5],  # Show top 5 duplicate groups
        'clusters': {k: v[:5] for k, v in results.get('clusters', {}).items()},  # Show first 5 files per cluster
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
            {"".join(f"<li>{path}</li>" for path in results.get('anomalies', [])[:20])}
        </ul>
    </div>
    
    <h2>Duplicate File Groups</h2>
    <div class="list">
        {"".join(f"<h3>Group {i+1}</h3><ul>{''.join(f'<li>{path}</li>' for path in group[:5])}</ul>" for i, group in enumerate(results.get('duplicates', [])[:5]))}
    </div>
    
    <h2>File Clusters</h2>
    <div class="list">
        {"".join(f"<h3>Cluster {cluster_id}</h3><ul>{''.join(f'<li>{path}</li>' for path in paths[:5])}</ul>" for cluster_id, paths in results.get('clusters', {}).items())}
    </div>
</body>
</html>
"""
    
    with open(os.path.join(output_dir, 'report.html'), 'w') as f:
        f.write(html_report)
    
    # Create the index.html as a copy of report.html
    with open(os.path.join(output_dir, 'index.html'), 'w') as f:
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
    
    # Save results - Use native Python types for JSON serialization
    results_json = {}
    
    # Convert each element to native Python types
    for key, value in results.items():
        # Handle special cases
        if key == 'paths':
            results_json[key] = [str(p) for p in value]
        elif key == 'anomalies':
            results_json[key] = [str(p) for p in value]
        elif key == 'duplicates':
            results_json[key] = [[str(p) for p in group] for group in value]
        elif key == 'clusters':
            results_json[key] = {str(k): [str(p) for p in v] for k, v in value.items()}
        elif key == 'coords_pca' or key == 'coords_tsne':
            if isinstance(value, np.ndarray):
                results_json[key] = value.tolist()
            else:
                results_json[key] = value
        elif key == 'metadata':
            # Already processed in analyze_data
            results_json[key] = value
        elif key == 'stats':
            results_json[key] = {str(k): float(v) if isinstance(v, (int, float, np.number)) else v 
                                for k, v in value.items()}
        elif key == 'feature_names':
            results_json[key] = [str(name) for name in value]
        else:
            # Default handling
            results_json[key] = value
    
    # Write to file
    with open(os.path.join(output_dir, 'analysis_results.json'), 'w') as f:
        json.dump(results_json, f, indent=2)
    
    # Visualize results
    visualize_results(results, output_dir)
    
    print("Analysis complete. Results saved to output directory.")

if __name__ == "__main__":
    main()
