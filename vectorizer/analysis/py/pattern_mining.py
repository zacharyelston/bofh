import networkx as nx
from collections import Counter
import os
import re

def mine_patterns(vector_data, filesystem_structure):
    """
    Mine patterns in file organization.
    
    Parameters:
    - vector_data: A dictionary mapping file paths to vector representations
    - filesystem_structure: A dictionary representing the filesystem hierarchy
    
    Returns:
    - Dictionary of discovered patterns
    """
    patterns = {}
    
    # Directory co-occurrence patterns
    dir_graph = nx.Graph()
    for path in vector_data:
        dir_path = os.path.dirname(path)
        dir_parts = dir_path.split('/')
        for i in range(len(dir_parts)):
            for j in range(i+1, len(dir_parts)):
                dir_graph.add_edge(dir_parts[i], dir_parts[j])
    
    # Find communities in the directory graph
    communities = nx.community.greedy_modularity_communities(dir_graph)
    patterns['directory_communities'] = [list(c) for c in communities]
    
    # Extension co-occurrence patterns
    ext_counter = Counter()
    for path in vector_data:
        ext = os.path.splitext(path)[1]
        if ext:
            ext_counter[ext] += 1
    
    patterns['common_extensions'] = ext_counter.most_common(10)
    
    # Naming patterns
    filename_patterns = []
    for path in vector_data:
        filename = os.path.basename(path)
        parts = re.split(r'[-_\s.]', filename)
        if len(parts) > 1:
            filename_patterns.extend(parts)
    
    pattern_counter = Counter(filename_patterns)
    patterns['filename_patterns'] = pattern_counter.most_common(20)
    
    return patterns
