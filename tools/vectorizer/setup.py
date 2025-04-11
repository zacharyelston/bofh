from setuptools import setup, find_packages

setup(
    name="vectorizer",
    version="0.1.0",
    packages=find_packages(),
    install_requires=[
        "numpy",
        "pandas",
        "scikit-learn",
        "matplotlib",
        "seaborn",
        "plotly",
        "networkx",
        "python-louvain",
        "umap-learn",
    ],
)
