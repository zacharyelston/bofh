from sklearn.preprocessing import StandardScaler, MinMaxScaler

def normalize_features(feature_matrix, method='standard'):
    """
    Normalize feature matrix.
    
    Parameters:
    - feature_matrix: Matrix of feature vectors
    - method: Normalization method ('standard', 'minmax')
    
    Returns:
    - Normalized feature matrix
    """
    if method == 'standard':
        scaler = StandardScaler()
    elif method == 'minmax':
        scaler = MinMaxScaler()
    else:
        raise ValueError(f"Unknown normalization method: {method}")
    
    normalized = scaler.fit_transform(feature_matrix)
    return normalized
