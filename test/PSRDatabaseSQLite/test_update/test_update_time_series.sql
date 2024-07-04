PRAGMA user_version = 1;
PRAGMA foreign_keys = ON;

CREATE TABLE Configuration (
    id INTEGER PRIMARY KEY,
    label TEXT UNIQUE NOT NULL
);

CREATE TABLE Plant (
    id INTEGER PRIMARY KEY,
    label TEXT UNIQUE NOT NULL
);

CREATE TABLE Plant_time_series_files (
    generation TEXT
);

CREATE TABLE Resource (
    id INTEGER PRIMARY KEY,
    label TEXT UNIQUE NOT NULL
);

CREATE TABLE Resource_time_series_files (
    generation TEXT,
    other_generation TEXT
);