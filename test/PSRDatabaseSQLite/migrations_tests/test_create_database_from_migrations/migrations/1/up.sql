-- create_first_snapshot
PRAGMA user_version = 1;
PRAGMA foreign_keys = ON;

CREATE TABLE Configuration (
    id INTEGER PRIMARY KEY,
    something TEXT
);

CREATE TABLE SomeTest (
    id INTEGER PRIMARY KEY,
    name TEXT
);

CREATE TABLE SomeOtherTest (
    id INTEGER PRIMARY KEY,
    capacity INTEGER,
    some_coefficient REAL
);