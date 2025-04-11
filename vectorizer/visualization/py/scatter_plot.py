import matplotlib.pyplot as plt
import numpy as np

def scatter_plot(coords, labels=None, paths=None, title=None, output_file=None):
    """
    Create a scatter plot of 2D coordinates.
    
    Parameters:
    - coords: 2D coordinates
    - labels: Cluster labels or categories (optional)
    - paths: File paths corresponding to points (optional)
    - title: Plot title (optional)
    - output_file: Output file path (optional)
    
    Returns:
    - Matplotlib figure
    """
    plt.figure(figsize=(12, 10))
    
    if labels is not None:
        # Color points by label
        unique_labels = np.unique(labels)
        colors = plt.cm.tab20(np.linspace(0, 1, len(unique_labels)))
        
        for i, label in enumerate(unique_labels):
            mask = labels == label
            plt.scatter(coords[mask, 0], coords[mask, 1], 
                        c=[colors[i]], label=f'Cluster {label}',
                        alpha=0.7, s=50)
        
        plt.legend()
    else:
        plt.scatter(coords[:, 0], coords[:, 1], alpha=0.7, s=50)
    
    if title:
        plt.title(title)
    
    plt.tight_layout()
    
    if output_file:
        plt.savefig(output_file, dpi=300, bbox_inches='tight')
        print(f"Saved plot to {output_file}")
    
    return plt.gcf()
