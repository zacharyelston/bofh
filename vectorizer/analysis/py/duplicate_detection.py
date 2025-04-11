from sklearn.metrics.pairwise import cosine_similarity
import numpy as np

def find_duplicates(vector_data, threshold=0.99, metric='cosine'):
    """
    Find duplicate or near-duplicate files.
    
    Parameters:
    - vector_data: A dictionary mapping file paths to vector representations
    - threshold: Similarity threshold for considering files as duplicates
    - metric: Similarity metric ('cosine', 'euclidean', 'manhattan')
    
    Returns:
    - List of sets, where each set contains paths to duplicate files
    """
    paths = list(vector_data.keys())
    duplicates = []
    
    # Track which files have been processed
    processed = set()
    
    for i, path1 in enumerate(paths):
        if path1 in processed:
            continue
        
        duplicate_group = {path1}
        
        for j, path2 in enumerate(paths[i+1:], start=i+1):
            if path2 in processed:
                continue
            
            # Calculate similarity
            if metric == 'cosine':
                similarity = cosine_similarity([vector_data[path1]], [vector_data[path2]])[0][0]
            elif metric == 'euclidean':
                similarity = 1.0 / (1.0 + np.linalg.norm(vector_data[path1] - vector_data[path2]))
            elif metric == 'manhattan':
                similarity = 1.0 / (1.0 + np.sum(np.abs(vector_data[path1] - vector_data[path2])))
            
            # If similarity above threshold, add to duplicate group
            if similarity >= threshold:
                duplicate_group.add(path2)
                processed.add(path2)
        
        if len(duplicate_group) > 1:
            duplicates.append(duplicate_group)
            processed.add(path1)
    
    return duplicates
