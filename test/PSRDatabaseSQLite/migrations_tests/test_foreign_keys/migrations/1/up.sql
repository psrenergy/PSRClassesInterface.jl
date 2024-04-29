PRAGMA foreign_keys = ON;
PRAGMA user_version = 1;

CREATE TABLE Configuration (
    id INTEGER PRIMARY KEY,
    scenarios INTEGER DEFAULT 1,
    minimum_iterations INTEGER DEFAULT 3,
    maximum_iterations INTEGER DEFAULT 15
);

CREATE TABLE Product (
    id INTEGER PRIMARY KEY,
    label TEXT UNIQUE NOT NULL,
    unit TEXT NOT NULL,
    initial_availability REAL DEFAULT 0.0,
    sell_limit REAL,
    sell_price REAL DEFAULT 0.0
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

CREATE TABLE Input (
    id INTEGER PRIMARY KEY,
    process_id INTEGER,
    product_id INTEGER,
    factor REAL,
    FOREIGN KEY(process_id) REFERENCES Process(id) ON UPDATE CASCADE ON DELETE SET NULL,
    FOREIGN KEY(product_id) REFERENCES Product(id) ON UPDATE CASCADE ON DELETE SET NULL
);

CREATE TABLE Output (
    id INTEGER PRIMARY KEY,
    process_id INTEGER,
    product_id INTEGER,
    factor REAL,
    FOREIGN KEY(process_id) REFERENCES Process(id) ON UPDATE CASCADE ON DELETE SET NULL,
    FOREIGN KEY(product_id) REFERENCES Product(id) ON UPDATE CASCADE ON DELETE SET NULL
);