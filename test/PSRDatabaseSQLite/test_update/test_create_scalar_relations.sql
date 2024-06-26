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
    type TEXT NOT NULL DEFAULT "D" CHECK(type IN ('D', 'E', 'F'))
) STRICT;

CREATE TABLE Plant (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    label TEXT UNIQUE NOT NULL,
    capacity REAL NOT NULL DEFAULT 0,
    resource_id INTEGER,
    plant_turbine_to INTEGER,
    plant_spill_to INTEGER,
    FOREIGN KEY(resource_id) REFERENCES Resource(id) ON DELETE SET NULL ON UPDATE CASCADE,
    FOREIGN KEY(plant_turbine_to) REFERENCES Plant(id) ON DELETE SET NULL ON UPDATE CASCADE,
    FOREIGN KEY(plant_spill_to) REFERENCES Plant(id) ON DELETE SET NULL ON UPDATE CASCADE
) STRICT;