import math
import time

def extract_metadata_features(stat_data):
    """
    Extract features from file metadata.
    
    Parameters:
    - stat_data: Dictionary of file metadata from stat command
    
    Returns:
    - Dictionary of metadata-based features
    """
    features = {}
    
    # Size features (log-scaled)
    features['size'] = math.log1p(stat_data['size'])
    
    # Time-based features
    current_time = time.time()
    features['age'] = (current_time - stat_data['modified']) / (24 * 3600)  # Age in days
    features['access_recency'] = (current_time - stat_data['atime']) / (24 * 3600)
    
    # Permission features (one-hot encoded)
    for i, perm in enumerate(['r', 'w', 'x']):
        features[f'user_{perm}'] = 1 if perm in stat_data['permissions'][1:4] else 0
        features[f'group_{perm}'] = 1 if perm in stat_data['permissions'][4:7] else 0
        features[f'other_{perm}'] = 1 if perm in stat_data['permissions'][7:10] else 0
    
    return features
