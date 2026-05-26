import pyodbc
import pandas as pd


def get_connection(
    server:   str = "localhost\\SQLEXPRESS",
    database: str = "spotify_db",
    username: str = None,
    password: str = None,
    trusted:  bool = True
):

    if trusted:
        conn_str = (
            f"DRIVER={{ODBC Driver 17 for SQL Server}};"
            f"SERVER={server};"
            f"DATABASE={database};"
            f"Trusted_Connection=yes;"
        )
    else:
        conn_str = (
            f"DRIVER={{ODBC Driver 17 for SQL Server}};"
            f"SERVER={server};"
            f"DATABASE={database};"
            f"UID={username};"
            f"PWD={password};"
        )

    conn = pyodbc.connect(conn_str)
    conn.autocommit = False
    print(f"[LOAD] Connected to SQL Server — database: '{database}'")
    return conn


def load_table(conn, df: pd.DataFrame, table: str, columns: list):
    
    df_subset = df[columns].where(pd.notnull(df[columns]), None)
    rows = [tuple(row) for row in df_subset.itertuples(index=False)]

    cols_str     = ", ".join(columns)
    placeholders = ", ".join(["?"] * len(columns))  # SQL Server-ում %s չէ, ? է

    # IDENTITY սյունների համար SET IDENTITY_INSERT ON
    identity_tables = ["genres", "artists", "albums"]
    id_col_map = {
        "genres":  "genre_id",
        "artists": "artist_id",
        "albums":  "album_id"
    }

    cursor = conn.cursor()
    cursor.fast_executemany = True  # արագ batch mode

    if table in identity_tables:
        cursor.execute(f"SET IDENTITY_INSERT {table} ON")

    query = f"IF NOT EXISTS (SELECT 1 FROM {table} WHERE {id_col_map.get(table, 'track_id')} = ?) " \
            f"INSERT INTO {table} ({cols_str}) VALUES ({placeholders})" \
            if table in identity_tables else \
            f"IF NOT EXISTS (SELECT 1 FROM {table} WHERE track_id = ?) " \
            f"INSERT INTO {table} ({cols_str}) VALUES ({placeholders})"

    cursor.execute(f"DELETE FROM {table}")

    insert_query = f"INSERT INTO {table} ({cols_str}) VALUES ({placeholders})"
    cursor.executemany(insert_query, rows)

    if table in identity_tables:
        cursor.execute(f"SET IDENTITY_INSERT {table} OFF")

    conn.commit()
    cursor.close()
    print(f"[LOAD] {table}: {len(rows):,} rows inserted.")


def load(conn, genres_df, artists_df, albums_df, tracks_df):
    """
    Բեռնում է բոլոր 4 աղյուսակները ճիշտ հաջորդականությամբ։
    genres → artists → albums → tracks
    """
    print("[LOAD] Starting data load...")

    load_table(conn, genres_df,  "genres",  ["genre_id", "genre_name"])
    load_table(conn, artists_df, "artists", ["artist_id", "artist_name"])
    load_table(conn, albums_df,  "albums",  ["album_id", "album_name", "artist_id"])
    load_table(conn, tracks_df,  "tracks",  [
        "track_id", "track_name", "album_id", "genre_id",
        "popularity", "duration_ms", "explicit",
        "danceability", "energy", "track_key", "loudness", "mode",
        "speechiness", "acousticness", "instrumentalness",
        "liveness", "valence", "tempo", "time_signature"
    ])

    print("[LOAD] All data loaded successfully.")
