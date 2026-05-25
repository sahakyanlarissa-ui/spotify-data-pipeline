-- ============================================================
--  Spotify Tracks Database Schema
--  Database: Microsoft SQL Server
-- ============================================================

USE spotify_db;
GO

-- Drop tables if they exist (foreign key կարգով)
IF OBJECT_ID('tracks',  'U') IS NOT NULL DROP TABLE tracks;
IF OBJECT_ID('albums',  'U') IS NOT NULL DROP TABLE albums;
IF OBJECT_ID('artists', 'U') IS NOT NULL DROP TABLE artists;
IF OBJECT_ID('genres',  'U') IS NOT NULL DROP TABLE genres;
GO

-- ------------------------------------------------------------
-- 1. GENRES
-- ------------------------------------------------------------
CREATE TABLE genres (
    genre_id   INT           NOT NULL IDENTITY(1,1),  -- AUTO_INCREMENT = IDENTITY(1,1)
    genre_name NVARCHAR(100) NOT NULL,
    CONSTRAINT PK_genres        PRIMARY KEY (genre_id),
    CONSTRAINT UQ_genre_name    UNIQUE      (genre_name)
);

CREATE INDEX idx_genres_name ON genres(genre_name);
GO

-- ------------------------------------------------------------
-- 2. ARTISTS
-- ------------------------------------------------------------
CREATE TABLE artists (
    artist_id   INT            NOT NULL IDENTITY(1,1),
    artist_name NVARCHAR(255)  NOT NULL,
    CONSTRAINT PK_artists      PRIMARY KEY (artist_id),
    CONSTRAINT UQ_artist_name  UNIQUE      (artist_name)
);

CREATE INDEX idx_artists_name ON artists(artist_name);
GO

-- ------------------------------------------------------------
-- 3. ALBUMS
-- ------------------------------------------------------------
CREATE TABLE albums (
    album_id   INT           NOT NULL IDENTITY(1,1),
    album_name NVARCHAR(500) NOT NULL,
    artist_id  INT           NOT NULL,
    CONSTRAINT PK_albums         PRIMARY KEY (album_id),
    CONSTRAINT UQ_album_artist   UNIQUE      (album_name, artist_id),
    CONSTRAINT FK_albums_artist  FOREIGN KEY (artist_id)
        REFERENCES artists(artist_id) ON DELETE CASCADE
);

CREATE INDEX idx_albums_artist ON albums(artist_id);
GO

-- ------------------------------------------------------------
-- 4. TRACKS
-- ------------------------------------------------------------
CREATE TABLE tracks (
    track_id         NVARCHAR(50)  NOT NULL,
    track_name       NVARCHAR(500) NOT NULL,
    album_id         INT           NOT NULL,
    genre_id         INT           NOT NULL,
    popularity       SMALLINT      NOT NULL,
    duration_ms      INT           NOT NULL,
    explicit         BIT           NOT NULL DEFAULT 0,  -- BIT = boolean (0/1)
    danceability     DECIMAL(5,4)  NULL,
    energy           DECIMAL(5,4)  NULL,
    track_key        SMALLINT      NULL,   -- 'key' reserved word — track_key անունով
    loudness         DECIMAL(6,3)  NULL,
    mode             SMALLINT      NULL,
    speechiness      DECIMAL(5,4)  NULL,
    acousticness     DECIMAL(5,4)  NULL,
    instrumentalness DECIMAL(7,6)  NULL,
    liveness         DECIMAL(5,4)  NULL,
    valence          DECIMAL(5,4)  NULL,
    tempo            DECIMAL(7,3)  NULL,
    time_signature   SMALLINT      NULL,

    CONSTRAINT PK_tracks          PRIMARY KEY (track_id),
    CONSTRAINT FK_tracks_album    FOREIGN KEY (album_id)  REFERENCES albums(album_id)  ON DELETE CASCADE,
    CONSTRAINT FK_tracks_genre    FOREIGN KEY (genre_id)  REFERENCES genres(genre_id),
    CONSTRAINT CHK_popularity     CHECK (popularity    BETWEEN 0 AND 100),
    CONSTRAINT CHK_duration       CHECK (duration_ms   > 0),
    CONSTRAINT CHK_danceability   CHECK (danceability  BETWEEN 0 AND 1),
    CONSTRAINT CHK_energy         CHECK (energy        BETWEEN 0 AND 1),
    CONSTRAINT CHK_mode           CHECK (mode          IN (0, 1))
);

CREATE INDEX idx_tracks_album      ON tracks(album_id);
CREATE INDEX idx_tracks_genre      ON tracks(genre_id);
CREATE INDEX idx_tracks_popularity ON tracks(popularity DESC);
GO
