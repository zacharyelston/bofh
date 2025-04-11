import plotly.express as px
import plotly.graph_objects as go
import pandas as pd
import numpy as np
import os

def interactive_scatter(coords, metadata, output_file=None):
    """
    Create an interactive scatter plot with file metadata.
    
    Parameters:
    - coords: 2D coordinates
    - metadata: Dictionary mapping file paths to metadata
    - output_file: Output HTML file path (optional)
    
    Returns:
    - Plotly figure
    """
    paths = list(metadata.keys())
    
    # Create a dataframe for plotly
    df = pd.DataFrame({
        'x': coords[:, 0],
        'y': coords[:, 1],
        'path': paths,
        'size': [metadata[p].get('size', 1000) for p in paths],
        'modified': [metadata[p].get('modified', 0) for p in paths],
        'permissions': [metadata[p].get('permissions', '') for p in paths],
        'extension': [os.path.splitext(p)[1] for p in paths]
    })
    
    # Create size column that's log-scaled for visualization
    df['size_log'] = np.log1p(df['size'])
    
    # Create the interactive plot
    fig = px.scatter(
        df, x='x', y='y',
        hover_data=['path', 'size', 'modified', 'permissions'],
        color='extension',
        size='size_log',
        title='Filesystem Vector Space'
    )
    
    fig.update_layout(
        xaxis_title="Dimension 1",
        yaxis_title="Dimension 2",
        legend_title="File Extension"
    )
    
    if output_file:
        fig.write_html(output_file)
        print(f"Saved interactive plot to {output_file}")
    
    return fig
