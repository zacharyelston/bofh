import numpy as np
import pandas as pd

def store_as_binary(raw_metadata_file):
    """
    Convert raw metadata to efficient binary storage format.
    
    Parameters:
    - raw_metadata_file: Path to the raw metadata file
    
    Returns:
    - Paths to the saved numpy files
    """
    # Load raw data
    data = pd.read_csv(raw_metadata_file, sep='|', 
                      names=['path', 'size', 'modified', 'permissions', 
                             'type', 'uid', 'gid', 'links', 'atime', 'ctime'])

    # Convert to numpy arrays for efficient storage
    paths = np.array(data['path'].tolist())
    numeric_data = data[['size', 'modified', 'uid', 'gid', 'atime', 'ctime']].to_numpy()

    # Save as binary files
    np.save('paths.npy', paths)
    np.save('numeric_data.npy', numeric_data)
    
    return ('paths.npy', 'numeric_data.npy')
