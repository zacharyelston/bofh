from sklearn.metrics.pairwise import cosine_similarity
import numpy as np

def find_similar_files(query_path, vector_data, n=10, metric='cosine'):
    """
    Find files similar to the query file.
    
    Parameters:
    - query_path: Path to the query file
    - vector_data: A dictionary mapping file paths to vector representations
    - n: Number of similar files to return
    - metric: Similarity metric ('cosine', 'euclidean', 'manhattan')
    
    Returns:
    - List of (file_path, similarity_score) tuples
    """
    if query_path not in vector_data:
        raise ValueError(f"Query path not found in vector data: {query_path}")
    
    query_vector = vector_data[query_path]
    
    similarities = []
    for path, vector in vector_data.items():
        if path == query_path:
            continue
        
        if metric == 'cosine':
            similarity = cosine_similarity([query_vector], [vector])[0][0]
        elif metric == 'euclidean':
            similarity = 1.0 / (1.0 + np.linalg.norm(query_vector - vector))
        elif metric == 'manhattan':
            similarity = 1.0 / (1.0 + np.sum(np.abs(query_vector - vector)))
        else:
            raise ValueError(f"Unknown similarity metric: {metric}")
        
        similarities.append((path, similarity))
    
    # Sort by similarity (descending) and return top n
    similarities.sort(key=lambda x: x[1], reverse=True)
    return similarities[:n]
