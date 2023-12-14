CREATE TABLE Configuration (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    val1 INTEGER
);

CREATE TABLE Plant (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    label TEXT UNIQUE
);

CREATE TABLE Plant_timeseries (
    generation TEXT,
    cost TEXT
);