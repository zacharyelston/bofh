from sklearn.metrics.pairwise import cosine_similarity
import seaborn as sns
import matplotlib.pyplot as plt
import numpy as np

def similarity_heatmap(vectors, paths, max_files=100, output_file=None):
    """
    Create a heatmap of file similarities.
    
    Parameters:
    - vectors: Array of vector data
    - paths: List of file paths
    - max_files: Maximum number of files to include (for readability)
    - output_file: Output file path (optional)
    
    Returns:
    - Matplotlib figure
    """
    # Limit to max_files for readability
    if len(vectors) > max_files:
        indices = np.random.choice(len(vectors), max_files, replace=False)
        vectors = vectors[indices]
        paths = [paths[i] for i in indices]
    
    # Calculate similarity matrix
    sim_matrix = cosine_similarity(vectors)
    
    # Create heatmap
    plt.figure(figsize=(12, 10))
    heatmap = sns.heatmap(sim_matrix, xticklabels=False, yticklabels=False)
    plt.title(f"File Similarity Heatmap ({len(paths)} files)")
    
    if output_file:
        plt.savefig(output_file, dpi=300, bbox_inches='tight')
        print(f"Saved heatmap to {output_file}")
    
    return plt.gcf()
