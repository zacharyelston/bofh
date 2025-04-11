#!/usr/bin/env python3
"""
DISKVOYEUR results visualizer

This script creates interactive visualizations from analysis results.
"""

import os
import json
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import plotly.express as px
import plotly.graph_objects as go
from datetime import datetime

def load_results(results_file):
    """Load analysis results from JSON file."""
    print(f"Loading results from {results_file}...")
    with open(results_file, 'r') as f:
        results = json.load(f)
    return results

def create_interactive_scatter(results, output_dir):
    """Create an interactive scatter plot of file vectors."""
    print("Creating interactive scatter plot...")
    
    if 'coords_pca' not in results or 'paths' not in results:
        print("Missing required data for scatter plot.")
        return
    
    # Get coordinates and paths
    coords = np.array(results['coords_pca'])
    paths = results['paths']
    
    # Create a dataframe for plotly
    df = pd.DataFrame({
        'x': coords[:, 0],
        'y': coords[:, 1],
        'path': [os.path.basename(p) for p in paths],
        'full_path': paths,
    })
    
    # Add metadata if available
    if 'metadata' in results:
        df['size'] = [results['metadata'][p]['size'] for p in paths]
        df['size_log'] = np.log1p(df['size'])
        df['modified'] = [datetime.fromtimestamp(results['metadata'][p]['modified']).strftime('%Y-%m-%d %H:%M:%S') for p in paths]
        df['extension'] = [os.path.splitext(p)[1] or 'none' for p in paths]
    
    # Add anomaly status
    df['is_anomaly'] = ['Yes' if p in results.get('anomalies', []) else 'No' for p in paths]
    
    # Add cluster assignment
    df['cluster'] = ['None'] * len(paths)
    for cluster_id, cluster_paths in results.get('clusters', {}).items():
        for path in cluster_paths:
            if path in paths:
                df.loc[df['full_path'] == path, 'cluster'] = f"Cluster {cluster_id}"
    
    # Create interactive scatter plot
    fig = px.scatter(
        df, x='x', y='y',
        hover_data=['full_path', 'size', 'modified'],
        color='cluster' if 'cluster' in df.columns else 'extension',
        symbol='is_anomaly',
        size='size_log' if 'size_log' in df.columns else None,
        title='Interactive File Vector Space',
        labels={'x': 'Component 1', 'y': 'Component 2'},
        height=800
    )
    
    # Highlight anomalies
    anomaly_indices = [i for i, p in enumerate(paths) if p in results.get('anomalies', [])]
    if anomaly_indices:
        anomaly_coords = coords[anomaly_indices]
        fig.add_trace(go.Scatter(
            x=anomaly_coords[:, 0],
            y=anomaly_coords[:, 1],
            mode='markers',
            marker=dict(
                size=15,
                color='rgba(255, 0, 0, 0.5)',
                line=dict(width=2, color='red')
            ),
            name='Anomalies',
            hoverinfo='skip'
        ))
    
    # Save as HTML
    output_file = os.path.join(output_dir, 'interactive_scatter.html')
    fig.write_html(output_file)
    print(f"Saved interactive scatter plot to {output_file}")
    
    return fig

def create_timeline_visualization(results, output_dir):
    """Create a timeline visualization of file modifications."""
    print("Creating timeline visualization...")
    
    if 'paths' not in results or 'metadata' not in results:
        print("Missing required data for timeline visualization.")
        return
    
    # Get paths and metadata
    paths = results['paths']
    metadata = results['metadata']
    
    # Create a dataframe
    df = pd.DataFrame({
        'path': [os.path.basename(p) for p in paths],
        'full_path': paths,
        'modified': [metadata[p]['modified'] for p in paths],
        'size': [metadata[p]['size'] for p in paths],
    })
    
    # Convert timestamps to datetime
    df['date'] = pd.to_datetime(df['modified'], unit='s')
    
    # Group by day
    df['day'] = df['date'].dt.date
    daily_counts = df.groupby('day').size()
    daily_sizes = df.groupby('day')['size'].sum() / (1024*1024)  # Convert to MB
    
    # Create figure
    fig = go.Figure()
    
    # Add traces
    fig.add_trace(go.Bar(
        x=daily_counts.index,
        y=daily_counts.values,
        name='Number of Files',
        marker_color='blue',
        opacity=0.7
    ))
    
    # Create a secondary y-axis for file sizes
    fig.add_trace(go.Scatter(
        x=daily_sizes.index,
        y=daily_sizes.values,
        name='Total Size (MB)',
        marker_color='red',
        mode='lines+markers',
        yaxis='y2'
    ))
    
    # Update layout
    fig.update_layout(
        title='File Modifications Over Time',
        xaxis_title='Date',
        yaxis_title='Number of Files',
        yaxis2=dict(
            title='Total Size (MB)',
            overlaying='y',
            side='right'
        ),
        legend=dict(
            orientation='h',
            yanchor='bottom',
            y=1.02,
            xanchor='right',
            x=1
        ),
        height=600
    )
    
    # Save as HTML
    output_file = os.path.join(output_dir, 'timeline.html')
    fig.write_html(output_file)
    print(f"Saved timeline visualization to {output_file}")
    
    return fig

def create_treemap(results, output_dir):
    """Create a treemap visualization of file sizes and types."""
    print("Creating treemap visualization...")
    
    if 'paths' not in results or 'metadata' not in results:
        print("Missing required data for treemap visualization.")
        return
    
    # Get paths and metadata
    paths = results['paths']
    metadata = results['metadata']
    
    # Create a dataframe
    df = pd.DataFrame({
        'path': paths,
        'size': [metadata[p]['size'] for p in paths],
    })
    
    # Add directory and extension columns
    df['directory'] = df['path'].apply(lambda p: os.path.dirname(p) or '/')
    df['extension'] = df['path'].apply(lambda p: os.path.splitext(p)[1] or 'none')
    df['filename'] = df['path'].apply(os.path.basename)
    
    # Group by directory and extension
    grouped = df.groupby(['directory', 'extension']).agg({
        'size': 'sum',
        'path': 'count'
    }).reset_index()
    
    # Create treemap
    fig = px.treemap(
        grouped,
        path=['directory', 'extension'],
        values='size',
        color='extension',
        hover_data=['path'],
        title='Filesystem Treemap by Size',
        height=800
    )
    
    # Save as HTML
    output_file = os.path.join(output_dir, 'treemap.html')
    fig.write_html(output_file)
    print(f"Saved treemap visualization to {output_file}")
    
    return fig

def create_anomaly_details(results, output_dir):
    """Create detailed visualizations of anomalous files."""
    print("Creating anomaly details visualization...")
    
    if 'anomalies' not in results or not results['anomalies']:
        print("No anomalies found.")
        return
    
    # Get anomalies and metadata
    anomalies = results['anomalies']
    metadata = results.get('metadata', {})
    
    # Create a dataframe
    df = pd.DataFrame({
        'path': [os.path.basename(p) for p in anomalies],
        'full_path': anomalies,
    })
    
    # Add metadata if available
    if metadata:
        df['size'] = [metadata[p]['size'] if p in metadata else 0 for p in anomalies]
        df['size_mb'] = df['size'] / (1024*1024)
        df['modified'] = [datetime.fromtimestamp(metadata[p]['modified']).strftime('%Y-%m-%d %H:%M:%S') 
                          if p in metadata else 'Unknown' for p in anomalies]
        df['extension'] = [os.path.splitext(p)[1] or 'none' for p in anomalies]
    
    # Create bar chart of anomalous file sizes
    if 'size' in df.columns:
        fig = px.bar(
            df.sort_values('size', ascending=False).head(20),
            x='path',
            y='size_mb',
            color='extension',
            title='Top 20 Anomalous Files by Size',
            labels={'path': 'Filename', 'size_mb': 'Size (MB)'},
            height=600
        )
        
        # Save as HTML
        output_file = os.path.join(output_dir, 'anomaly_sizes.html')
        fig.write_html(output_file)
        print(f"Saved anomaly size visualization to {output_file}")
    
    # Create a sunburst chart of anomalies by directory and extension
    df['directory'] = [os.path.dirname(p) or '/' for p in anomalies]
    
    fig = px.sunburst(
        df,
        path=['directory', 'extension', 'path'],
        values='size' if 'size' in df.columns else None,
        title='Anomalous Files by Directory and Type',
        height=800
    )
    
    # Save as HTML
    output_file = os.path.join(output_dir, 'anomaly_sunburst.html')
    fig.write_html(output_file)
    print(f"Saved anomaly sunburst visualization to {output_file}")
    
    return fig

def create_index_page(output_dir):
    """Create an index.html page linking to all visualizations."""
    print("Creating index page...")
    
    # List HTML files in output directory
    html_files = [f for f in os.listdir(output_dir) if f.endswith('.html')]
    
    # Create index.html
    html_content = f"""<!DOCTYPE html>
<html>
<head>
    <title>DISKVOYEUR Interactive Visualizations</title>
    <style>
        body {{ font-family: Arial, sans-serif; margin: 20px; }}
        h1, h2 {{ color: #333; }}
        .viz-grid {{ display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap: 20px; }}
        .viz-card {{ background: #f5f5f5; border-radius: 5px; padding: 15px; }}
        .viz-card h3 {{ margin-top: 0; }}
        .viz-card a {{ display: block; padding: 10px; background: #4CAF50; color: white; 
                      text-align: center; text-decoration: none; border-radius: 5px; }}
        .viz-card a:hover {{ background: #45a049; }}
    </style>
</head>
<body>
    <h1>DISKVOYEUR Interactive Visualizations</h1>
    <p>Analysis completed: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}</p>
    
    <div class="viz-grid">
"""
    
    # Add cards for each visualization
    for html_file in html_files:
        if html_file == 'index.html':
            continue
            
        title = ' '.join(word.capitalize() for word in html_file.replace('.html', '').split('_'))
        
        html_content += f"""
        <div class="viz-card">
            <h3>{title}</h3>
            <a href="{html_file}" target="_blank">View Visualization</a>
        </div>
"""
    
    html_content += """
    </div>
    
    <h2>Static Visualizations</h2>
    <div class="viz-grid">
"""
    
    # Add cards for static images
    img_files = [f for f in os.listdir(output_dir) if f.endswith(('.png', '.jpg'))]
    for img_file in img_files:
        title = ' '.join(word.capitalize() for word in img_file.replace('.png', '').replace('.jpg', '').split('_'))
        
        html_content += f"""
        <div class="viz-card">
            <h3>{title}</h3>
            <img src="{img_file}" alt="{title}" style="max-width:100%; margin-bottom:10px;">
            <a href="{img_file}" target="_blank">View Full Size</a>
        </div>
"""
    
    html_content += """
    </div>
</body>
</html>
"""
    
    # Write index.html
    with open(os.path.join(output_dir, 'index.html'), 'w') as f:
        f.write(html_content)
    
    print(f"Created index page at {os.path.join(output_dir, 'index.html')}")

def main():
    """Main function."""
    results_file = '/data/output/analysis_results.json'
    output_dir = '/data/output'
    
    print(f"DISKVOYEUR Visualization")
    print(f"=======================")
    
    # Make sure output directory exists
    os.makedirs(output_dir, exist_ok=True)
    
    # Load results
    if not os.path.exists(results_file):
        print(f"Results file not found: {results_file}")
        print("Please run analysis first.")
        return
    
    results = load_results(results_file)
    
    # Create visualizations
    create_interactive_scatter(results, output_dir)
    create_timeline_visualization(results, output_dir)
    create_treemap(results, output_dir)
    create_anomaly_details(results, output_dir)
    
    # Create index page
    create_index_page(output_dir)
    
    print("Visualization complete. Open index.html in the output directory to view results.")

if __name__ == "__main__":
    main()
