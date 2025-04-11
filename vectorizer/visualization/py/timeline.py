import matplotlib.pyplot as plt
import pandas as pd
import numpy as np
from datetime import datetime
import os

def timeline_visualization(metadata, output_file=None):
    """
    Create a timeline visualization of file changes.
    
    Parameters:
    - metadata: Dictionary mapping file paths to metadata
    - output_file: Output file path (optional)
    
    Returns:
    - Matplotlib figure
    """
    # Extract timestamps
    paths = []
    timestamps = []
    sizes = []
    extensions = []
    
    for path, data in metadata.items():
        if 'modified' in data:
            paths.append(path)
            timestamps.append(data['modified'])
            sizes.append(data.get('size', 0))
            extensions.append(os.path.splitext(path)[1])
    
    # Convert to datetime
    dates = [datetime.fromtimestamp(ts) for ts in timestamps]
    
    # Create dataframe
    df = pd.DataFrame({
        'path': paths,
        'date': dates,
        'size': sizes,
        'extension': extensions
    })
    
    # Group by day
    df['day'] = df['date'].dt.date
    daily_counts = df.groupby('day').size()
    daily_sizes = df.groupby('day')['size'].sum()
    
    # Plot timeline
    fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(14, 10), sharex=True)
    
    # File count by day
    ax1.bar(daily_counts.index, daily_counts.values, alpha=0.7)
    ax1.set_ylabel('Number of Files')
    ax1.set_title('Files by Day')
    ax1.grid(True, alpha=0.3)
    
    # File size by day
    ax2.bar(daily_sizes.index, daily_sizes.values / (1024*1024), alpha=0.7)
    ax2.set_ylabel('Total Size (MB)')
    ax2.set_title('Storage Usage by Day')
    ax2.grid(True, alpha=0.3)
    
    plt.tight_layout()
    
    if output_file:
        plt.savefig(output_file, dpi=300, bbox_inches='tight')
        print(f"Saved timeline to {output_file}")
    
    return plt.gcf()
