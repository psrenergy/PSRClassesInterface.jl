PRAGMA foreign_keys = ON;
PRAGMA user_version = 1;

CREATE TABLE Configuration (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    val1 INTEGER
) STRICT;

CREATE TABLE Plant (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    label TEXT UNIQUE
) STRICT;

CREATE TABLE Plant_timeseries (
    generation TEXT,
    cost TEXT
) STRICT;