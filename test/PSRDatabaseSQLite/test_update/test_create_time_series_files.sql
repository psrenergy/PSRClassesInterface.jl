PRAGMA user_version = 1;
PRAGMA foreign_keys = ON;

CREATE TABLE Configuration (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    label TEXT UNIQUE NOT NULL,
    value1 REAL NOT NULL DEFAULT 100,
    enum1 TEXT NOT NULL DEFAULT 'A' CHECK(enum1 IN ('A', 'B', 'C'))
) STRICT;

CREATE TABLE Resource (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    label TEXT UNIQUE NOT NULL,
    type TEXT NOT NULL DEFAULT "D" CHECK(type IN ('D', 'E', 'F'))
) STRICT;

CREATE TABLE Resource_time_series_files (
    wind_speed TEXT,
    wind_direction TEXT
) STRICT;