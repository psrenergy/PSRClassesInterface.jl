PRAGMA user_version = 1;
PRAGMA foreign_keys = ON;

CREATE TABLE Configuration (
    id INTEGER PRIMARY KEY,
    label TEXT
);

CREATE TABLE Plant (
    id INTEGER PRIMARY KEY,
    label TEXT
);

CREATE TABLE Plant_timeseriesfiles (
    generation TEXT
);

CREATE TABLE Resource (
    id INTEGER PRIMARY KEY,
    label TEXT
);

CREATE TABLE Resource_timeseriesfiles (
    generation TEXT,
    other_generation TEXT
);