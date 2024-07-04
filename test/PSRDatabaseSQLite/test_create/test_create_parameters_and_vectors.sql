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

CREATE TABLE Resource_vector_some_group (
    id INTEGER, 
    vector_index INTEGER NOT NULL,
    some_value REAL NOT NULL,
    FOREIGN KEY(id) REFERENCES Resource(id) ON DELETE CASCADE ON UPDATE CASCADE,
    PRIMARY KEY (id, vector_index)
) STRICT; 

CREATE TABLE Cost (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    label TEXT UNIQUE NOT NULL,
    value REAL NOT NULL DEFAULT 100
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

CREATE TABLE Plant_vector_cost_relation (
    id INTEGER,
    vector_index INTEGER NOT NULL,
    some_factor REAL NOT NULL,
    cost_id INTEGER,
    FOREIGN KEY(id) REFERENCES Plant(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY(cost_id) REFERENCES Cost(id) ON DELETE SET NULL ON UPDATE CASCADE,
    PRIMARY KEY (id, vector_index)
) STRICT;

CREATE TABLE Product (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    label TEXT UNIQUE NOT NULL,
    unit TEXT NOT NULL,
    initial_availability REAL DEFAULT 0.0
) STRICT;

CREATE TABLE Process (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    label TEXT UNIQUE NOT NULL
) STRICT;

CREATE TABLE Process_vector_inputs (
    id INTEGER,
    vector_index INTEGER NOT NULL,
    factor_input REAL NOT NULL,
    product_input INTEGER,
    FOREIGN KEY(product_input) REFERENCES Product(id) ON DELETE SET NULL ON UPDATE CASCADE,
    PRIMARY KEY (id, vector_index)
) STRICT;

CREATE TABLE Process_vector_outputs (
    id INTEGER,
    vector_index INTEGER NOT NULL,
    factor_output REAL NOT NULL,
    product_output INTEGER,
    FOREIGN KEY(product_output) REFERENCES Product(id) ON DELETE SET NULL ON UPDATE CASCADE,
    PRIMARY KEY (id, vector_index)
) STRICT;

CREATE TABLE Plant_time_series_files (
    generation TEXT,
    prices TEXT
) STRICT;