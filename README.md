[README.md](https://github.com/user-attachments/files/28215520/README.md)
# Spotify Tracks — Data Ingestion & Analytics Pipeline (SQL Server)

## Dataset
- **Source:** [Kaggle — Spotify Tracks Dataset](https://www.kaggle.com/datasets/maharshipandya/-spotify-tracks-dataset)
- **Size:** 114,000 tracks, 114 genres, 31,000+ artists

## Project Structure
```
project/
├── data/
│   └── dataset.csv
├── app/
│   ├── extract.py
│   ├── transform.py
│   ├── load.py
│   └── main.py
├── sql/
│   ├── schema.sql
│   └── queries.sql
├── requirements.txt
└── README.md
```

## How to Run

### 1. Create database in SSMS
```sql
CREATE DATABASE spotify_db;
```

### 2. Run schema.sql in SSMS
Open `sql/schema.sql` in SSMS and execute (F5).

### 3. Install Python dependencies
```bash
pip install -r requirements.txt
```

### 4. Copy dataset
Place `dataset.csv` inside the `data/` folder.

### 5. Run the pipeline (Windows Authentication)
```bash
cd app
python main.py --server "localhost\SQLEXPRESS" --database spotify_db
```

### Run with SQL Server Authentication
```bash
python main.py --server "localhost\SQLEXPRESS" --database spotify_db --trusted false --username sa --password yourpassword
```

## SQL Server vs MySQL/PostgreSQL Differences
| Feature | MySQL/PostgreSQL | SQL Server |
|---|---|---|
| Auto increment | `AUTO_INCREMENT` / `SERIAL` | `IDENTITY(1,1)` |
| Boolean | `BOOLEAN` / `TINYINT(1)` | `BIT` |
| Row limit | `LIMIT 10` | `TOP 10` |
| Std deviation | `STDDEV()` | `STDEV()` |
| Conditional agg | `FILTER (WHERE ...)` | `SUM(CASE WHEN ...)` |
| Library | psycopg2 / mysql-connector | pyodbc |
| Auth | username+password | Windows Auth or SQL Auth |

## Data Cleaning
- Removed 1 row with missing values
- Removed 24,259 duplicate track_ids
- Converted `explicit` bool → BIT (0/1)
- Renamed `key` → `track_key` (reserved word in SQL)
