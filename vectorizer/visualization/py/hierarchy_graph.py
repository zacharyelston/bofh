import networkx as nx
import matplotlib.pyplot as plt
import community as community_louvain
import numpy as np
import os

def hierarchy_graph(filesystem_data, output_file=None):
    """
    Create a hierarchical graph visualization of the filesystem.
    
    Parameters:
    - filesystem_data: Dictionary mapping paths to metadata
    - output_file: Output file path (optional)
    
    Returns:
    - NetworkX graph and matplotlib figure
    """
    # Create graph
    G = nx.Graph()
    
    # Add nodes and edges for directory structure
    for path in filesystem_data:
        parts = path.split('/')
        for i in range(1, len(parts)):
            parent = '/'.join(parts[:i])
            child = '/'.join(parts[:i+1])
            
            # Add nodes if they don't exist
            if not G.has_node(parent):
                G.add_node(parent, type='directory')
            
            if i == len(parts) - 1:
                # This is a file
                G.add_node(child, type='file', 
                          size=filesystem_data[path].get('size', 0),
                          modified=filesystem_data[path].get('modified', 0))
            else:
                # This is a directory
                G.add_node(child, type='directory')
            
            # Add edge
            G.add_edge(parent, child)
    
    # Find communities
    partition = community_louvain.best_partition(G)
    
    # Assign colors based on communities
    cmap = plt.cm.tab20
    colors = [cmap(partition[node] / max(partition.values())) for node in G.nodes()]
    
    # Node sizes based on type and size
    sizes = []
    for node in G.nodes():
        if G.nodes[node]['type'] == 'file':
            sizes.append(50 + np.log1p(G.nodes[node]['size']) / 10)
        else:
            sizes.append(100)
    
    # Create layout
    pos = nx.spring_layout(G, k=0.15, iterations=50)
    
    # Draw the graph
    plt.figure(figsize=(20, 16))
    nx.draw_networkx(G, pos, node_color=colors, node_size=sizes, 
                    with_labels=False, alpha=0.7, edge_color='gray')
    
    # Add file extension labels to important nodes
    file_nodes = [n for n in G.nodes() if G.nodes[n]['type'] == 'file']
    file_labels = {n: os.path.splitext(n)[-1] for n in file_nodes}
    nx.draw_networkx_labels(G, pos, labels=file_labels, font_size=6)
    
    plt.title("Filesystem Hierarchy Graph")
    plt.axis('off')
    
    if output_file:
        plt.savefig(output_file, dpi=300, bbox_inches='tight')
        print(f"Saved graph to {output_file}")
    
    return G, plt.gcf()
