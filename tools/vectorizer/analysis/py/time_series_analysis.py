import pandas as pd
import numpy as np
from datetime import datetime

def analyze_time_series(vector_data, metadata):
    """
    Analyze file changes over time.
    
    Parameters:
    - vector_data: A dictionary mapping file paths to vector representations
    - metadata: A dictionary mapping file paths to metadata including timestamps
    
    Returns:
    - Dictionary of time series analytics
    """
    # Create a dataframe with timestamps
    df = pd.DataFrame([
        {
            'path': path,
            'modified': datetime.fromtimestamp(metadata[path]['modified']),
            'created': datetime.fromtimestamp(metadata[path].get('created', metadata[path]['modified'])),
            'accessed': datetime.fromtimestamp(metadata[path].get('accessed', metadata[path]['modified'])),
            'size': metadata[path]['size']
        }
        for path in vector_data
    ])
    
    # Add date components
    df['year'] = df['modified'].dt.year
    df['month'] = df['modified'].dt.month
    df['day'] = df['modified'].dt.day
    df['hour'] = df['modified'].dt.hour
    df['weekday'] = df['modified'].dt.weekday
    
    # Group by time periods
    by_year = df.groupby('year').agg({'path': 'count', 'size': 'sum'})
    by_month = df.groupby(['year', 'month']).agg({'path': 'count', 'size': 'sum'})
    by_weekday = df.groupby('weekday').agg({'path': 'count', 'size': 'sum'})
    by_hour = df.groupby('hour').agg({'path': 'count', 'size': 'sum'})
    
    results = {
        'by_year': by_year.to_dict(),
        'by_month': by_month.to_dict(),
        'by_weekday': by_weekday.to_dict(),
        'by_hour': by_hour.to_dict(),
        'oldest_file': df.sort_values('modified').iloc[0]['path'],
        'newest_file': df.sort_values('modified', ascending=False).iloc[0]['path'],
        'most_accessed_file': df.sort_values('accessed', ascending=False).iloc[0]['path'],
        'largest_file': df.sort_values('size', ascending=False).iloc[0]['path']
    }
    
    return results
