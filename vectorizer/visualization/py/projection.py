import numpy as np
import matplotlib.pyplot as plt
from sklearn.decomposition import PCA
from sklearn.manifold import TSNE, MDS
import umap

def project_to_2d(vectors, method='tsne', **kwargs):
    """
    Project high-dimensional vectors to 2D for visualization.
    
    Parameters:
    - vectors: Array of vector data
    - method: Projection method ('tsne', 'pca', 'mds', 'umap')
    - kwargs: Additional arguments for the projection method
    
    Returns:
    - Array of 2D coordinates
    """
    if method == 'tsne':
        projector = TSNE(n_components=2, **kwargs)
    elif method == 'pca':
        projector = PCA(n_components=2, **kwargs)
    elif method == 'mds':
        projector = MDS(n_components=2, **kwargs)
    elif method == 'umap':
        projector = umap.UMAP(n_components=2, **kwargs)
    else:
        raise ValueError(f"Unknown projection method: {method}")
    
    return projector.fit_transform(vectors)
