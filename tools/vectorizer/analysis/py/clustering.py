from sklearn.cluster import KMeans, DBSCAN, AgglomerativeClustering
import numpy as np

def cluster_files(vector_data, method='kmeans', n_clusters=10, **kwargs):
    """
    Cluster files based on their vector representations.
    
    Parameters:
    - vector_data: A dictionary mapping file paths to vector representations
    - method: Clustering method ('kmeans', 'dbscan', 'hierarchical')
    - n_clusters: Number of clusters (for kmeans and hierarchical)
    - kwargs: Additional arguments for the clustering method
    
    Returns:
    - Dictionary mapping cluster IDs to lists of file paths
    """
    # Input validation
    if not vector_data:
        return {"0": list(vector_data.keys())}
    
    try:
        paths = list(vector_data.keys())
        vectors_list = list(vector_data.values())
        
        # Handle case where vectors might be lists instead of arrays
        vectors = np.array([np.array(v, dtype=float) if isinstance(v, list) else v for v in vectors_list])
        
        # Check for NaN or infinity values
        if np.isnan(vectors).any() or np.isinf(vectors).any():
            print("Warning: NaN or infinity values found in vectors. Replacing with zeros.")
            vectors = np.nan_to_num(vectors)
            
        # Ensure consistent dimensionality
        if len(vectors.shape) != 2:
            raise ValueError(f"Expected 2D array of vectors, got shape {vectors.shape}")
            
        # Ensure we have enough samples for the requested number of clusters
        if method in ['kmeans', 'hierarchical'] and n_clusters > len(vectors):
            print(f"Warning: Requested {n_clusters} clusters but only have {len(vectors)} samples.")
            n_clusters = max(2, min(n_clusters, len(vectors)))
            
    except Exception as e:
        print(f"Error preparing vectors for clustering: {e}")
        return {"0": paths}
    
    try:
        # Select clustering algorithm
        if method == 'kmeans':
            # Add random_state for reproducibility
            clusterer = KMeans(n_clusters=n_clusters, random_state=42, **kwargs)
        elif method == 'dbscan':
            # Use more conservative defaults for DBSCAN
            eps = kwargs.get('eps', 0.5)
            min_samples = kwargs.get('min_samples', max(5, int(len(vectors) * 0.1)))
            clusterer = DBSCAN(eps=eps, min_samples=min_samples, **kwargs)
        elif method == 'hierarchical':
            clusterer = AgglomerativeClustering(n_clusters=n_clusters, **kwargs)
        else:
            raise ValueError(f"Unknown clustering method: {method}")
        
        # Fit the clustering model
        labels = clusterer.fit_predict(vectors)
        
        # Group files by cluster
        clusters = {}
        for path, label in zip(paths, labels):
            label_str = str(label)
            if label_str not in clusters:
                clusters[label_str] = []
            clusters[label_str].append(path)
            
        # Check if any clusters are empty (shouldn't happen but just in case)
        if not clusters:
            clusters = {"0": paths}
            
        return clusters
        
    except Exception as e:
        print(f"Error in clustering: {e}")
        return {"0": paths}
