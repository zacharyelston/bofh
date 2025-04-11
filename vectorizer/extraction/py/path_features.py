import os

def extract_path_features(path):
    """
    Extract features from file path structure.
    
    Parameters:
    - path: File path to analyze
    
    Returns:
    - Dictionary of path-based features (numeric values only)
    """
    features = {}
    
    # Directory depth
    features['depth'] = float(path.count('/'))
    
    # Filename length
    filename = os.path.basename(path)
    features['filename_length'] = float(len(filename))
    
    # Extension
    _, ext = os.path.splitext(filename)
    features['has_extension'] = float(1 if ext else 0)
    
    # Hidden file
    features['is_hidden'] = float(1 if filename.startswith('.') else 0)
    
    # Extension length
    features['extension_length'] = float(len(ext))
    
    # Path length
    features['path_length'] = float(len(path))
    
    # Directory name length (parent directory)
    dirname = os.path.dirname(path)
    if dirname:
        features['dirname_length'] = float(len(os.path.basename(dirname)))
    else:
        features['dirname_length'] = 0.0
    
    # Number of dots in filename
    features['dot_count'] = float(filename.count('.'))
    
    # Number of underscores in filename
    features['underscore_count'] = float(filename.count('_'))
    
    # Number of hyphens in filename
    features['hyphen_count'] = float(filename.count('-'))
    
    # Number of numbers in filename
    features['number_count'] = float(sum(c.isdigit() for c in filename))
    
    # All features are numeric
    return features
