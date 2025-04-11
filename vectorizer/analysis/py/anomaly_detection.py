from sklearn.ensemble import IsolationForest
from sklearn.neighbors import LocalOutlierFactor

def detect_anomalies(vector_data, method='isolation_forest', contamination=0.05, **kwargs):
    """
    Detect anomalous files based on their vector representations.
    
    Parameters:
    - vector_data: A dictionary mapping file paths to vector representations
    - method: Anomaly detection method ('isolation_forest', 'lof')
    - contamination: Expected proportion of anomalies
    - kwargs: Additional arguments for the anomaly detection method
    
    Returns:
    - List of file paths identified as anomalies
    """
    paths = list(vector_data.keys())
    vectors = np.array(list(vector_data.values()))
    
    # Select anomaly detection algorithm
    if method == 'isolation_forest':
        detector = IsolationForest(contamination=contamination, **kwargs)
    elif method == 'lof':
        detector = LocalOutlierFactor(contamination=contamination, **kwargs)
    else:
        raise ValueError(f"Unknown anomaly detection method: {method}")
    
    # Fit the anomaly detection model
    if method == 'isolation_forest':
        labels = detector.fit_predict(vectors)
        anomalies = [path for path, label in zip(paths, labels) if label == -1]
    elif method == 'lof':
        labels = detector.fit_predict(vectors)
        anomalies = [path for path, label in zip(paths, labels) if label == -1]
    
    return anomalies
