import os
import math

def calculate_entropy(data):
    """Calculate Shannon entropy of binary data."""
    if not data:
        return 0
    
    entropy = 0
    for byte in range(256):
        p_x = data.count(byte) / len(data)
        if p_x > 0:
            entropy += p_x * math.log2(p_x)
    
    return -entropy

def is_text_file(file_path, sample=None):
    """Determine if the file is a text file by checking for binary content."""
    if sample:
        # Quick check on the sample
        null_bytes = sample.count(0)
        if null_bytes > len(sample) * 0.05:  # More than 5% null bytes suggests binary
            return False
        try:
            sample.decode('utf-8')
            return True
        except UnicodeDecodeError:
            return False
    else:
        # Slower fallback if no sample provided
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                f.read(1024)
            return True
        except (UnicodeDecodeError, IOError):
            return False

def get_mime_type(file_path):
    """Get the MIME type of a file."""
    import mimetypes
    mime_type, _ = mimetypes.guess_type(file_path)
    return mime_type or 'application/octet-stream'

def extract_content_features(file_path, content_hash, sample=None):
    """
    Extract features from file content.
    
    Parameters:
    - file_path: Path to the file
    - content_hash: Hash of the file content
    - sample: Optional sample of file content
    
    Returns:
    - Dictionary of content-based features
    """
    features = {}
    
    # Hash-based features
    features['hash_prefix'] = content_hash[:8]
    
    # Entropy of content
    if sample:
        entropy = calculate_entropy(sample)
        features['entropy'] = entropy
    
    # Text vs binary classification
    is_text = is_text_file(file_path, sample)
    features['is_text'] = 1 if is_text else 0
    
    # MIME type features
    mime = get_mime_type(file_path)
    features['mime_type'] = mime
    features['is_image'] = 1 if mime.startswith('image/') else 0
    features['is_video'] = 1 if mime.startswith('video/') else 0
    features['is_audio'] = 1 if mime.startswith('audio/') else 0
    features['is_document'] = 1 if mime.startswith('application/') and any(
        x in mime for x in ['pdf', 'document', 'spreadsheet', 'presentation']) else 0
    
    return features
