import pandas as pd
import os


def extract(filepath: str) -> pd.DataFrame:
    if not os.path.exists(filepath):
        raise FileNotFoundError(f"Dataset not found at: {filepath}")

    print(f"[EXTRACT] Reading file: {filepath}")
    df = pd.read_csv(filepath)
    print(f"[EXTRACT] Loaded {len(df):,} rows and {len(df.columns)} columns.")
    return df
