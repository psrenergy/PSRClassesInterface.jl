PRAGMA user_version = 1;
PRAGMA foreign_keys = ON;

CREATE TABLE Configuration (
    id INTEGER PRIMARY KEY,
    label TEXT UNIQUE NOT NULL,
    some_value REAL NOT NULL DEFAULT 100
);

CREATE TABLE Product (
    id INTEGER PRIMARY KEY,
    label TEXT UNIQUE NOT NULL,
    unit TEXT NOT NULL,
    initial_availability REAL DEFAULT 0.0
) STRICT;

CREATE TABLE Process (
    id INTEGER PRIMARY KEY,
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