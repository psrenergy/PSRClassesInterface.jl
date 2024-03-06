-- create_first_snapshot
PRAGMA user_version = 1;
PRAGMA foreign_keys = ON;

CREATE TABLE Test1 (
    id INTEGER PRIMARY KEY,
    name TEXT
);

CREATE TABLE Test2 (
    id INTEGER PRIMARY KEY,
    capacity INTEGER,
    some_coefficient REAL
);