-- create_first_snapshot
PRAGMA user_version = 1;

CREATE TABLE Test1 (
    id INTEGER PRIMARY KEY,
    name TEXT
);

CREATE TABLE Test2 (
    id INTEGER PRIMARY KEY,
    capacity INTEGER,
    some_coefficient REAL
);