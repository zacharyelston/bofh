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
    # Input validation
    if not vector_data or len(vector_data) < 2:
        return []
        
    try:
        paths = list(vector_data.keys())
        vectors_list = list(vector_data.values())
        
        # Handle case where vectors might be lists instead of arrays
        vectors = {}
        for path, vector in zip(paths, vectors_list):
            if isinstance(vector, list):
                vectors[path] = np.array(vector, dtype=float)
            else:
                vectors[path] = vector
                
        # Check each vector for NaN or infinity
        for path, vector in vectors.items():
            if np.isnan(vector).any() or np.isinf(vector).any():
                print(f"Warning: NaN or infinity values found in vector for {path}. Replacing with zeros.")
                vectors[path] = np.nan_to_num(vector)
                
    except Exception as e:
        print(f"Error preparing vectors for duplicate detection: {e}")
        return []
    
    try:
        duplicates = []
        processed = set()
        
        # Improved implementation with better error handling
        for i, path1 in enumerate(paths):
            if path1 in processed:
                continue
            
            duplicate_group = {path1}
            
            for j, path2 in enumerate(paths[i+1:], start=i+1):
                if path2 in processed:
                    continue
                
                try:
                    # Calculate similarity based on metric
                    if metric == 'cosine':
                        similarity = cosine_similarity([vectors[path1]], [vectors[path2]])[0][0]
                    elif metric == 'euclidean':
                        # Safer implementation that avoids division by zero
                        dist = np.linalg.norm(vectors[path1] - vectors[path2])
                        similarity = 1.0 / (1.0 + dist)
                    elif metric == 'manhattan':
                        # Safer implementation that avoids division by zero
                        dist = np.sum(np.abs(vectors[path1] - vectors[path2]))
                        similarity = 1.0 / (1.0 + dist)
                    else:
                        raise ValueError(f"Unknown similarity metric: {metric}")
                    
                    # Handle NaN similarity (can happen with zero vectors)
                    if np.isnan(similarity):
                        similarity = 0.0
                    
                    # If similarity above threshold, add to duplicate group
                    if similarity >= threshold:
                        duplicate_group.add(path2)
                        processed.add(path2)
                        
                except Exception as e:
                    print(f"Error calculating similarity between {path1} and {path2}: {e}")
                    continue
            
            if len(duplicate_group) > 1:
                duplicates.append(duplicate_group)
                processed.add(path1)
        
        return duplicates
        
    except Exception as e:
        print(f"Error in duplicate detection: {e}")
        return []
