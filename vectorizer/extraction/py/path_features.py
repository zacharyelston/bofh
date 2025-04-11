import os

def extract_path_features(path):
    """
    Extract features from file path structure.
    
    Parameters:
    - path: File path to analyze
    
    Returns:
    - Dictionary of path-based features
    """
    features = {}
    
    # Directory depth
    features['depth'] = path.count('/')
    
    # Filename length
    filename = os.path.basename(path)
    features['filename_length'] = len(filename)
    
    # Extension
    _, ext = os.path.splitext(filename)
    features['has_extension'] = 1 if ext else 0
    
    # Hidden file
    features['is_hidden'] = 1 if filename.startswith('.') else 0
    
    # Path embedding using TF-IDF
    path_parts = path.split('/')
    features['path_parts'] = ' '.join(path_parts)
    
    return features
