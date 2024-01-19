PRAGMA user_version = 1;
PRAGMA foreign_keys = ON;

CREATE TABLE Configuration (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    label TEXT UNIQUE,
    value1 REAL NOT NULL DEFAULT 100,
    enum1 TEXT NOT NULL DEFAULT 'A' CHECK(enum1 IN ('A', 'B', 'C'))
) STRICT;

CREATE TABLE Cost (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    label TEXT UNIQUE,
    value1 REAL NOT NULL DEFAULT 100
) STRICT;

CREATE TABLE Resource (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    label TEXT UNIQUE,
    type TEXT NOT NULL DEFAULT "D" CHECK(type IN ('D', 'E', 'F')),
    some_value_1 REAL NOT NULL DEFAULT 100,
    some_value_2 REAL NOT NULL DEFAULT 100,
    cost_id INTEGER,
    FOREIGN KEY(cost_id) REFERENCES Cost(id) ON DELETE CASCADE ON UPDATE CASCADE
) STRICT;
