import numpy as np
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
    # Input validation
    if not vector_data:
        return []
        
    # Check that data is in the right format
    try:
        paths = list(vector_data.keys())
        vectors_list = list(vector_data.values())
        
        # Handle case where vectors might be lists instead of arrays
        vectors = np.array([np.array(v, dtype=float) if isinstance(v, list) else v for v in vectors_list])
        
        # Check for NaN or infinity values
        if np.isnan(vectors).any() or np.isinf(vectors).any():
            print("Warning: NaN or infinity values found in vectors. Replacing with zeros.")
            vectors = np.nan_to_num(vectors)
        
        # Ensure consistent dimensionality
        if len(vectors.shape) != 2:
            raise ValueError(f"Expected 2D array of vectors, got shape {vectors.shape}")
            
    except Exception as e:
        print(f"Error preparing vectors for anomaly detection: {e}")
        return []
    
    # Select anomaly detection algorithm
    try:
        if method == 'isolation_forest':
            # Add random_state for reproducibility
            detector = IsolationForest(contamination=contamination, random_state=42, **kwargs)
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
        
    except Exception as e:
        print(f"Error in anomaly detection: {e}")
        return []
