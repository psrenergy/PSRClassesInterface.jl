PRAGMA user_version = 1;
PRAGMA foreign_keys = ON;

CREATE TABLE Configuration (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    label TEXT UNIQUE
) STRICT;

CREATE TABLE Cost (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    label TEXT UNIQUE
) STRICT;

CREATE TABLE Resource (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    label TEXT UNIQUE
) STRICT;

CREATE TABLE Plant (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    label TEXT UNIQUE,
    capacity REAL NOT NULL DEFAULT 0,
    resource_id INTEGER,
    FOREIGN KEY(resource_id) REFERENCES Resource(id) ON DELETE SET NULL ON UPDATE CASCADE
) STRICT;

CREATE TABLE Plant_vector_cost_relation (
    id INTEGER,
    vector_index INTEGER NOT NULL,
    some_factor REAL NOT NULL,
    cost_id INTEGER,
    FOREIGN KEY(id) REFERENCES Plant(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY(cost_id) REFERENCES Cost(id) ON DELETE SET NULL ON UPDATE CASCADE,
    PRIMARY KEY (id, vector_index)
) STRICT;

CREATE TABLE Plant_vector_some_relation_type (
    id INTEGER,
    vector_index INTEGER NOT NULL,
    cost_some_relation_type INTEGER,
    FOREIGN KEY(id) REFERENCES Plant(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY(cost_some_relation_type) REFERENCES Cost(id) ON DELETE SET NULL ON UPDATE CASCADE,
    PRIMARY KEY (id, vector_index)
) STRICT;