from sklearn.feature_extraction.text import TfidfVectorizer
import numpy as np

def extract_text_features(file_path, max_features=100):
    """
    Extract features from text file content.
    
    Parameters:
    - file_path: Path to the text file
    - max_features: Maximum number of features to extract
    
    Returns:
    - Array of text features
    """
    try:
        with open(file_path, 'r', errors='ignore') as f:
            content = f.read()
        
        vectorizer = TfidfVectorizer(max_features=max_features)
        features = vectorizer.fit_transform([content])
        return features.toarray()[0]
    except:
        return np.zeros(max_features)
