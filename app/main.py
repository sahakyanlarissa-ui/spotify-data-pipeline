"""
main.py
-------
ETL Pipeline - Գլխավոր ֆայլ (SQL Server տարբերակ)

Օգտագործում (Windows Authentication — ամենապարզը):
    python main.py

Օգտագործում (SQL Server Authentication):
    python main.py --trusted false --username sa --password secret
"""

import argparse
from extract   import extract
from transform import transform
from load      import get_connection, load


def parse_args():
    parser = argparse.ArgumentParser(description="Spotify ETL Pipeline — SQL Server")
    parser.add_argument("--server",   default="localhost\\SQLEXPRESS", help="SQL Server instance")
    parser.add_argument("--database", default="spotify_db",            help="Database name")
    parser.add_argument("--trusted",  default="true",                  help="Windows Auth (true/false)")
    parser.add_argument("--username", default=None,                    help="SQL Server username")
    parser.add_argument("--password", default=None,                    help="SQL Server password")
    parser.add_argument("--csv",      default="../data/dataset.csv",   help="Path to CSV file")
    return parser.parse_args()


def main():
    args = parse_args()
    use_trusted = args.trusted.lower() == "true"

    print("=" * 50)
    print("  Spotify ETL Pipeline  (SQL Server)")
    print("=" * 50)

    # STEP 1 — EXTRACT
    print("\n--- STEP 1: EXTRACT ---")
    df_raw = extract(args.csv)

    # STEP 2 — TRANSFORM
    print("\n--- STEP 2: TRANSFORM ---")
    genres_df, artists_df, albums_df, tracks_df = transform(df_raw)

    # STEP 3 — LOAD
    print("\n--- STEP 3: LOAD ---")
    conn = get_connection(
        server=args.server,
        database=args.database,
        trusted=use_trusted,
        username=args.username,
        password=args.password
    )
    try:
        load(conn, genres_df, artists_df, albums_df, tracks_df)
    finally:
        conn.close()
        print("[LOAD] Connection closed.")

    print("\n" + "=" * 50)
    print("  Pipeline completed successfully!")
    print("=" * 50)


if __name__ == "__main__":
    main()
