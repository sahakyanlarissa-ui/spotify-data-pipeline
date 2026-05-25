"""
transform.py
------------
ETL Pipeline - Step 2: TRANSFORM

SQL Server-ի համար փոփոխություններ.
  - explicit → int (BIT սյուն SQL Server-ում, Python-ից 0/1 ուղարկում ենք)
  - 'key' սյունը schema-ում track_key անունով է
"""

import pandas as pd


def clean(df: pd.DataFrame) -> pd.DataFrame:
    print("[TRANSFORM] Starting data cleaning...")

    if "Unnamed: 0" in df.columns:
        df = df.drop(columns=["Unnamed: 0"])

    before = len(df)
    df = df.dropna(subset=["track_id", "artists", "album_name", "track_name", "track_genre"])
    print(f"[TRANSFORM] Dropped {before - len(df)} rows with missing values.")

    before = len(df)
    df = df.drop_duplicates(subset=["track_id"], keep="first")
    print(f"[TRANSFORM] Dropped {before - len(df)} duplicate track_ids.")

    df["artists"]     = df["artists"].str.strip()
    df["album_name"]  = df["album_name"].str.strip()
    df["track_name"]  = df["track_name"].str.strip()
    df["track_genre"] = df["track_genre"].str.strip()

    # SQL Server BIT սյուն — True→1, False→0
    df["explicit"] = df["explicit"].astype(bool).astype(int)

    # 'key' → 'track_key' (schema-ում այդպես ենք անվանել)
    if "key" in df.columns:
        df = df.rename(columns={"key": "track_key"})

    print(f"[TRANSFORM] Clean data: {len(df):,} rows remaining.")
    return df.reset_index(drop=True)


def build_genres(df: pd.DataFrame) -> pd.DataFrame:
    genres = df["track_genre"].drop_duplicates().reset_index(drop=True)
    genres_df = pd.DataFrame({
        "genre_id":   genres.index + 1,
        "genre_name": genres.values
    })
    print(f"[TRANSFORM] Genres: {len(genres_df)} unique genres.")
    return genres_df


def build_artists(df: pd.DataFrame) -> pd.DataFrame:
    primary_artists = (
        df["artists"].str.split(";").str[0].str.strip()
        .drop_duplicates().reset_index(drop=True)
    )
    artists_df = pd.DataFrame({
        "artist_id":   primary_artists.index + 1,
        "artist_name": primary_artists.values
    })
    print(f"[TRANSFORM] Artists: {len(artists_df)} unique artists.")
    return artists_df


def build_albums(df: pd.DataFrame, artists_df: pd.DataFrame) -> pd.DataFrame:
    df = df.copy()
    df["primary_artist"] = df["artists"].str.split(";").str[0].str.strip()
    df = df.merge(artists_df, left_on="primary_artist", right_on="artist_name", how="left")

    albums = df[["album_name", "artist_id"]].drop_duplicates().reset_index(drop=True)
    albums_df = albums.copy()
    albums_df.insert(0, "album_id", albums_df.index + 1)
    print(f"[TRANSFORM] Albums: {len(albums_df)} unique albums.")
    return albums_df


def build_tracks(df: pd.DataFrame, albums_df: pd.DataFrame, genres_df: pd.DataFrame) -> pd.DataFrame:
    df = df.copy()
    df["primary_artist"] = df["artists"].str.split(";").str[0].str.strip()

    df = df.merge(albums_df, left_on=["album_name", "primary_artist"],
                  right_on=["album_name", "artist_name"], how="left")
    df = df.merge(genres_df, left_on="track_genre", right_on="genre_name", how="left")

    tracks_df = df[[
        "track_id", "track_name", "album_id", "genre_id",
        "popularity", "duration_ms", "explicit",
        "danceability", "energy", "track_key", "loudness", "mode",
        "speechiness", "acousticness", "instrumentalness",
        "liveness", "valence", "tempo", "time_signature"
    ]].copy()

    print(f"[TRANSFORM] Tracks: {len(tracks_df)} rows ready to load.")
    return tracks_df


def transform(df: pd.DataFrame):
    df_clean   = clean(df)
    genres_df  = build_genres(df_clean)
    artists_df = build_artists(df_clean)
    albums_df  = build_albums(df_clean, artists_df)
    tracks_df  = build_tracks(df_clean, albums_df, genres_df)
    return genres_df, artists_df, albums_df, tracks_df
