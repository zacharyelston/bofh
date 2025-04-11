import os

def extract_relationship_features(file_path, filesystem_data):
    """
    Extract features based on filesystem relationships.
    
    Parameters:
    - file_path: Path to the file
    - filesystem_data: Dictionary or list of all files in the filesystem
    
    Returns:
    - Dictionary of relationship-based features
    """
    features = {}
    
    # Directory siblings count
    dir_path = os.path.dirname(file_path)
    siblings = [f for f in filesystem_data if os.path.dirname(f) == dir_path]
    features['sibling_count'] = len(siblings)
    
    # Directory size relative to parent
    parent_dir = os.path.dirname(dir_path)
    parent_files = [f for f in filesystem_data if os.path.dirname(f).startswith(parent_dir)]
    dir_files = [f for f in filesystem_data if os.path.dirname(f).startswith(dir_path)]
    features['dir_size_ratio'] = len(dir_files) / max(1, len(parent_files))
    
    # Same-extension siblings
    _, ext = os.path.splitext(file_path)
    ext_siblings = [f for f in siblings if f.endswith(ext)]
    features['same_ext_siblings'] = len(ext_siblings)
    
    return features
