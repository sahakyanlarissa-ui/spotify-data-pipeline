-- ============================================================
--  Spotify Tracks — SQL Analysis Queries
--  Database: Microsoft SQL Server
--
--  MySQL/PostgreSQL-ից տարբերությունները.
--  1. LIMIT → TOP կամ FETCH NEXT ... ROWS ONLY
--  2. ROUND(x, 2) → նույնն է
--  3. FILTER (WHERE...) → չկա, SUM(CASE WHEN ... END) ենք օգտ.
--  4. 'key' → track_key (schema-ում այդպես ենք անվանել)
--  5. Window functions → SQL Server 2012+-ում կան
-- ============================================================

USE spotify_db;
GO

-- ============================================================
-- 1. SUMMARY STATISTICS
-- ============================================================

-- Քանի երգ, արտիստ, ալբոմ, ժանր
SELECT
    (SELECT COUNT(*) FROM tracks)  AS total_tracks,
    (SELECT COUNT(*) FROM artists) AS total_artists,
    (SELECT COUNT(*) FROM albums)  AS total_albums,
    (SELECT COUNT(*) FROM genres)  AS total_genres;

-- Popularity վիճակագրություն
SELECT
    ROUND(AVG(CAST(popularity AS FLOAT)), 2) AS avg_popularity,
    MIN(popularity)                           AS min_popularity,
    MAX(popularity)                           AS max_popularity,
    ROUND(STDEV(popularity), 2)               AS stddev_popularity  -- SQL Server-ում STDEV()
FROM tracks;

-- Երգերի տևողություն (վայրկյաններով)
SELECT
    ROUND(AVG(duration_ms) / 1000.0, 1) AS avg_duration_sec,
    ROUND(MIN(duration_ms) / 1000.0, 1) AS min_duration_sec,
    ROUND(MAX(duration_ms) / 1000.0, 1) AS max_duration_sec
FROM tracks;


-- ============================================================
-- 2. TOP ENTITIES
-- ============================================================

-- Top 10 ամենапopular երգ — SQL Server-ում TOP փոխարեն LIMIT-ի
SELECT TOP 10
    t.track_name,
    ar.artist_name,
    g.genre_name,
    t.popularity
FROM tracks t
JOIN albums  al ON t.album_id   = al.album_id
JOIN artists ar ON al.artist_id = ar.artist_id
JOIN genres  g  ON t.genre_id   = g.genre_id
ORDER BY t.popularity DESC;

-- Top 10 արտիստ ըստ երգերի քանակի
SELECT TOP 10
    ar.artist_name,
    COUNT(t.track_id) AS track_count
FROM artists ar
JOIN albums al ON ar.artist_id = al.artist_id
JOIN tracks t  ON al.album_id  = t.album_id
GROUP BY ar.artist_name
ORDER BY track_count DESC;

-- Top 10 արտիստ ըստ միջին popularity-ի (min 5 երգ)
SELECT TOP 10
    ar.artist_name,
    COUNT(t.track_id)                        AS track_count,
    ROUND(AVG(CAST(t.popularity AS FLOAT)),2) AS avg_popularity
FROM artists ar
JOIN albums al ON ar.artist_id = al.artist_id
JOIN tracks t  ON al.album_id  = t.album_id
GROUP BY ar.artist_name
HAVING COUNT(t.track_id) >= 5
ORDER BY avg_popularity DESC;


-- ============================================================
-- 3. GROUPED ANALYSIS — Ժանրի վերլուծություն
-- ============================================================

-- Ժանր → երգերի քանակ, popularity, danceability, energy
SELECT
    g.genre_name,
    COUNT(t.track_id)                             AS track_count,
    ROUND(AVG(CAST(t.popularity AS FLOAT)),  2)   AS avg_popularity,
    ROUND(AVG(t.danceability), 3)                 AS avg_danceability,
    ROUND(AVG(t.energy), 3)                       AS avg_energy
FROM genres g
JOIN tracks t ON g.genre_id = t.genre_id
GROUP BY g.genre_name
ORDER BY avg_popularity DESC;

-- Explicit % ըստ ժանրի — SQL Server-ում SUM(CASE WHEN ...)
SELECT TOP 10
    g.genre_name,
    SUM(CASE WHEN t.explicit = 1 THEN 1 ELSE 0 END)  AS explicit_count,
    COUNT(*)                                           AS total_count,
    ROUND(
        100.0 * SUM(CASE WHEN t.explicit = 1 THEN 1 ELSE 0 END) / COUNT(*), 1
    )                                                  AS explicit_pct
FROM genres g
JOIN tracks t ON g.genre_id = t.genre_id
GROUP BY g.genre_name
ORDER BY explicit_pct DESC;


-- ============================================================
-- 4. AUDIO FEATURE ANALYSIS
-- ============================================================

-- Danceability bucket vs Popularity
SELECT
    CASE
        WHEN danceability < 0.25 THEN 'Low (0-0.25)'
        WHEN danceability < 0.50 THEN 'Medium (0.25-0.50)'
        WHEN danceability < 0.75 THEN 'High (0.50-0.75)'
        ELSE                          'Very High (0.75-1)'
    END                                              AS danceability_bucket,
    COUNT(*)                                         AS track_count,
    ROUND(AVG(CAST(popularity AS FLOAT)), 2)         AS avg_popularity
FROM tracks
GROUP BY
    CASE
        WHEN danceability < 0.25 THEN 'Low (0-0.25)'
        WHEN danceability < 0.50 THEN 'Medium (0.25-0.50)'
        WHEN danceability < 0.75 THEN 'High (0.50-0.75)'
        ELSE                          'Very High (0.75-1)'
    END
ORDER BY danceability_bucket;

-- Ամենաբարձր tempo ունեցող ժանրները
SELECT TOP 10
    g.genre_name,
    ROUND(AVG(t.tempo), 1) AS avg_tempo
FROM genres g
JOIN tracks t ON g.genre_id = t.genre_id
GROUP BY g.genre_name
ORDER BY avg_tempo DESC;


-- ============================================================
-- 5. WINDOW FUNCTIONS
-- ============================================================

-- Յուրաքանչյուր ժանրի Top 3 ամենапopular երգ
SELECT *
FROM (
    SELECT
        g.genre_name,
        t.track_name,
        ar.artist_name,
        t.popularity,
        RANK() OVER (
            PARTITION BY g.genre_id
            ORDER BY t.popularity DESC
        ) AS rank_in_genre
    FROM tracks  t
    JOIN albums  al ON t.album_id   = al.album_id
    JOIN artists ar ON al.artist_id = ar.artist_id
    JOIN genres  g  ON t.genre_id   = g.genre_id
) ranked
WHERE rank_in_genre <= 3
ORDER BY genre_name, rank_in_genre;

-- Running total ըստ popularity
SELECT
    popularity,
    COUNT(*)                                         AS track_count,
    SUM(COUNT(*)) OVER (ORDER BY popularity ROWS
        UNBOUNDED PRECEDING)                         AS running_total
FROM tracks
GROUP BY popularity
ORDER BY popularity;

-- Ժանրի % բաժինը ամբողջ catalog-ում
SELECT
    g.genre_name,
    COUNT(t.track_id)   AS track_count,
    ROUND(
        100.0 * COUNT(t.track_id) / SUM(COUNT(t.track_id)) OVER (), 2
    )                   AS pct_of_total
FROM genres g
JOIN tracks t ON g.genre_id = t.genre_id
GROUP BY g.genre_name, g.genre_id
ORDER BY pct_of_total DESC;


-- ============================================================
-- 6. ANALYTICAL QUESTION
--    Ո՞ր ժանրն ունի ամենաբարձր danceability × popularity score,
--    և ո՞ր արտիստն է ամենաշատ ներկայացված այդ ժանրում։
-- ============================================================

WITH genre_scores AS (
    SELECT
        g.genre_id,
        g.genre_name,
        ROUND(AVG(t.danceability * t.popularity), 3) AS dance_pop_score,
        COUNT(t.track_id)                             AS track_count
    FROM genres g
    JOIN tracks t ON g.genre_id = t.genre_id
    GROUP BY g.genre_id, g.genre_name
),
top_genre AS (
    SELECT TOP 1 genre_id, genre_name, dance_pop_score  -- SQL Server-ում LIMIT → TOP
    FROM genre_scores
    ORDER BY dance_pop_score DESC
),
top_artists_in_genre AS (
    SELECT TOP 5
        ar.artist_name,
        COUNT(t.track_id)                             AS track_count,
        ROUND(AVG(CAST(t.popularity AS FLOAT)), 2)    AS avg_pop
    FROM tracks  t
    JOIN albums  al ON t.album_id   = al.album_id
    JOIN artists ar ON al.artist_id = ar.artist_id
    JOIN top_genre tg ON t.genre_id = tg.genre_id
    GROUP BY ar.artist_name
    ORDER BY track_count DESC
)
SELECT
    tg.genre_name,
    tg.dance_pop_score,
    ta.artist_name,
    ta.track_count,
    ta.avg_pop
FROM top_genre tg
CROSS JOIN top_artists_in_genre ta
ORDER BY ta.track_count DESC;
