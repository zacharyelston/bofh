from sklearn.feature_selection import VarianceThreshold, SelectKBest, f_classif

def select_features(feature_matrix, target=None, method='variance', k=100):
    """
    Select most informative features.
    
    Parameters:
    - feature_matrix: Matrix of feature vectors
    - target: Optional target values for supervised selection
    - method: Selection method ('variance', 'kbest')
    - k: Number of features to select for 'kbest' method
    
    Returns:
    - Feature matrix with selected features
    """
    if method == 'variance':
        selector = VarianceThreshold(threshold=0.01)
        return selector.fit_transform(feature_matrix)
    elif method == 'kbest' and target is not None:
        selector = SelectKBest(f_classif, k=k)
        return selector.fit_transform(feature_matrix, target)
    else:
        return feature_matrix
