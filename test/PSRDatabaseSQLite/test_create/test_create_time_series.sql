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
    type TEXT NOT NULL DEFAULT "D"
) STRICT;

CREATE TABLE Resource_time_series_group1 (
    id INTEGER, 
    date_time TEXT NOT NULL,
    some_vector1 REAL,
    some_vector2 REAL,
    FOREIGN KEY(id) REFERENCES Resource(id) ON DELETE CASCADE ON UPDATE CASCADE,
    PRIMARY KEY (id, date_time)
) STRICT; 

CREATE TABLE Resource_time_series_group2 (
    id INTEGER, 
    date_time TEXT NOT NULL,
    block INTEGER NOT NULL,
    some_vector3 REAL,
    some_vector4 REAL,
    FOREIGN KEY(id) REFERENCES Resource(id) ON DELETE CASCADE ON UPDATE CASCADE,
    PRIMARY KEY (id, date_time, block)
) STRICT; 

CREATE TABLE Resource_time_series_group3 (
    id INTEGER, 
    date_time TEXT NOT NULL,
    block INTEGER NOT NULL,
    segment INTEGER NOT NULL,
    some_vector5 REAL,
    some_vector6 REAL,
    FOREIGN KEY(id) REFERENCES Resource(id) ON DELETE CASCADE ON UPDATE CASCADE,
    PRIMARY KEY (id, date_time, block, segment)
) STRICT; 

CREATE TABLE Resource_time_series_group4 (
    id INTEGER, 
    date_time TEXT NOT NULL,
    block INTEGER NOT NULL,
    segment INTEGER NOT NULL,
    some_other_dimension INTEGER NOT NULL,
    some_vector7 REAL,
    some_vector8 REAL,
    FOREIGN KEY(id) REFERENCES Resource(id) ON DELETE CASCADE ON UPDATE CASCADE,
    PRIMARY KEY (id, date_time, block, segment, some_other_dimension)
) STRICT; 