import numpy as np
import matplotlib.pyplot as plt
from sklearn.decomposition import PCA
from sklearn.manifold import TSNE, MDS
import warnings

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
    # Input validation
    if vectors is None or len(vectors) == 0:
        raise ValueError("Cannot project empty vector array")
    
    # Handle small datasets
    if len(vectors) < 2:
        # For a single vector, return a single point at the origin
        return np.zeros((len(vectors), 2))
    
    # Convert to numpy array and handle lists
    if isinstance(vectors, list):
        vectors = np.array(vectors, dtype=float)
    
    # Check for NaN or infinity values
    if np.isnan(vectors).any() or np.isinf(vectors).any():
        print("Warning: NaN or infinity values found in vectors. Replacing with zeros.")
        vectors = np.nan_to_num(vectors)
    
    # Default to PCA for very small datasets
    if len(vectors) < 4 and method == 'tsne':
        print("Too few samples for t-SNE. Using PCA instead.")
        method = 'pca'
    
    # For t-SNE, ensure perplexity is valid
    if method == 'tsne':
        # Adjust perplexity if needed (must be less than n_samples - 1)
        max_perplexity = max(1, len(vectors) - 1)
        perplexity = kwargs.get('perplexity', 30)
        
        if perplexity >= max_perplexity:
            perplexity = max(1, max_perplexity // 2)
            print(f"Perplexity adjusted to {perplexity} for {len(vectors)} samples")
            kwargs['perplexity'] = perplexity
    
    try:
        # Select projection method with appropriate defaults
        with warnings.catch_warnings():
            warnings.simplefilter("ignore")
            
            if method == 'tsne':
                # Add random_state for reproducibility
                projector = TSNE(n_components=2, random_state=42, **kwargs)
            elif method == 'pca':
                projector = PCA(n_components=2, random_state=42, **kwargs)
            elif method == 'mds':
                projector = MDS(n_components=2, random_state=42, **kwargs)
            elif method == 'umap':
                try:
                    import umap
                    projector = umap.UMAP(n_components=2, random_state=42, **kwargs)
                except ImportError:
                    print("UMAP not installed. Using PCA instead.")
                    projector = PCA(n_components=2, random_state=42)
            else:
                raise ValueError(f"Unknown projection method: {method}")
        
        # Perform the projection
        return projector.fit_transform(vectors)
        
    except Exception as e:
        print(f"Error in {method} projection: {e}")
        # Fall back to PCA for any errors
        try:
            print("Falling back to PCA projection")
            projector = PCA(n_components=2, random_state=42)
            return projector.fit_transform(vectors)
        except:
            print("PCA fallback failed. Returning random 2D positions.")
            # Last resort: random positions
            return np.random.rand(len(vectors), 2)
