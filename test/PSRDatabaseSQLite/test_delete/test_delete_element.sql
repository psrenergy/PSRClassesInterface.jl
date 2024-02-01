PRAGMA user_version = 1;
PRAGMA foreign_keys = ON;

CREATE TABLE Configuration (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    label TEXT UNIQUE,
    value1 REAL NOT NULL DEFAULT 100
) STRICT;


CREATE TABLE Resource (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    label TEXT UNIQUE
) STRICT;

CREATE TABLE Resource_vector_some_group (
    id INTEGER, 
    vector_index INTEGER NOT NULL,
    some_value REAL NOT NULL,
    some_other_value REAL,
    FOREIGN KEY(id) REFERENCES Resource(id) ON DELETE CASCADE ON UPDATE CASCADE,
    PRIMARY KEY (id, vector_index)
) STRICT; 


CREATE TABLE Plant (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    label TEXT UNIQUE,
    capacity REAL NOT NULL DEFAULT 0,
    resource_id INTEGER,
    plant_turbine_to INTEGER,
    plant_spill_to INTEGER,
    FOREIGN KEY(resource_id) REFERENCES Resource(id) ON DELETE SET NULL ON UPDATE CASCADE,
    FOREIGN KEY(plant_turbine_to) REFERENCES Plant(id) ON DELETE SET NULL ON UPDATE CASCADE,
    FOREIGN KEY(plant_spill_to) REFERENCES Plant(id) ON DELETE SET NULL ON UPDATE CASCADE
) STRICT;

