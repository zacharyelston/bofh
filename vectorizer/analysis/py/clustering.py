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
    paths = list(vector_data.keys())
    vectors = np.array(list(vector_data.values()))
    
    # Select clustering algorithm
    if method == 'kmeans':
        clusterer = KMeans(n_clusters=n_clusters, **kwargs)
    elif method == 'dbscan':
        clusterer = DBSCAN(eps=0.5, min_samples=5, **kwargs)
    elif method == 'hierarchical':
        clusterer = AgglomerativeClustering(n_clusters=n_clusters, **kwargs)
    else:
        raise ValueError(f"Unknown clustering method: {method}")
    
    # Fit the clustering model
    labels = clusterer.fit_predict(vectors)
    
    # Group files by cluster
    clusters = {}
    for path, label in zip(paths, labels):
        if label not in clusters:
            clusters[label] = []
        clusters[label].append(path)
    
    return clusters
