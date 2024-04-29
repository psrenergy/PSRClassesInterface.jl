PRAGMA foreign_keys = ON;
PRAGMA user_version = 1;

CREATE TABLE Configuration (
    id INTEGER PRIMARY KEY,
    scenarios INTEGER DEFAULT 1,
    minimum_iterations INTEGER DEFAULT 3,
    maximum_iterations INTEGER DEFAULT 15,
    alpha REAL DEFAULT 0.95 CHECK (alpha >= 0 AND alpha <= 1),
    lambda REAL DEFAULT 0.0 CHECK (lambda >= 0 AND lambda <= 1)
);

CREATE TABLE Product (
    id INTEGER PRIMARY KEY,
    label TEXT UNIQUE NOT NULL,
    unit TEXT NOT NULL,
    initial_availability REAL DEFAULT 0.0,
    sell_availability REAL DEFAULT 0.0,
    sell_price REAL DEFAULT 0.0,
    vol_mass REAL DEFAULT 0.0
);

CREATE TABLE Process (
    id INTEGER PRIMARY KEY,
    label TEXT UNIQUE NOT NULL,
    capex REAL,
    opex REAL,
    base_capacity REAL,
    scaling_factor REAL DEFAULT 0.7,
    interest_rate REAL DEFAULT 0.1,
    lifespan INTEGER DEFAULT 20
);

CREATE TABLE Process_vector_input (
    id INTEGER,
    vector_index INTEGER NOT NULL,
    product_input INTEGER,
    input_factor REAL,
    FOREIGN KEY (id) REFERENCES Process(id) ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (product_input) REFERENCES Product(id) ON UPDATE CASCADE ON DELETE SET NULL,
    PRIMARY KEY (id, vector_index)
);

CREATE TABLE Process_vector_output (
    id INTEGER,
    vector_index INTEGER NOT NULL,
    output_product INTEGER,
    output_factor REAL,
    FOREIGN KEY (id) REFERENCES Process(id) ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (output_product) REFERENCES Product(id) ON UPDATE CASCADE ON DELETE SET NULL,
    PRIMARY KEY (id, vector_index)
);