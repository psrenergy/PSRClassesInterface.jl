-- create_first_snapshot
PRAGMA user_version = 1;
PRAGMA foreign_keys = ON;

CREATE TABLE Configuration (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    label TEXT UNIQUE
);

CREATE TABLE TestOne (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    label TEXT UNIQUE
);

CREATE TABLE TestTwo (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    label TEXT UNIQUE,
    capacity INTEGER,
    some_coefficient REAL
);