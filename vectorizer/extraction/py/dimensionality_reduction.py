from sklearn.decomposition import PCA
from sklearn.manifold import TSNE

def reduce_dimensions(feature_matrix, method='pca', dimensions=50):
    """
    Reduce dimensionality of feature matrix.
    
    Parameters:
    - feature_matrix: Matrix of feature vectors
    - method: Reduction method ('pca', 'tsne')
    - dimensions: Number of dimensions to reduce to
    
    Returns:
    - Reduced feature matrix
    """
    if method == 'pca':
        reducer = PCA(n_components=dimensions)
    elif method == 'tsne':
        reducer = TSNE(n_components=dimensions, perplexity=30)
    else:
        raise ValueError(f"Unknown reduction method: {method}")
    
    reduced = reducer.fit_transform(feature_matrix)
    return reduced
