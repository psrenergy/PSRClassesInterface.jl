PRAGMA user_version = 3;
PRAGMA foreign_keys = ON;
CREATE TABLE Process_vector_input (
    id INTEGER,
    vector_index INTEGER NOT NULL,
    factor_input REAL NOT NULL,
    product_input INTEGER,
    FOREIGN KEY(id) REFERENCES Process(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY(product_input) REFERENCES Product(id) ON DELETE
    SET NULL ON UPDATE CASCADE,
        PRIMARY KEY (id, vector_index)
) STRICT;

INSERT INTO Process_vector_input (id, vector_index, factor_input, product_input)
SELECT id, process_id, factor, product_id
FROM Input;

DROP TABLE Input;

CREATE TABLE Process_vector_output (
    id INTEGER,
    vector_index INTEGER NOT NULL,
    factor_output REAL NOT NULL,
    product_output INTEGER,
    FOREIGN KEY(id) REFERENCES Process(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY(product_output) REFERENCES Product(id) ON DELETE
    SET NULL ON UPDATE CASCADE,
        PRIMARY KEY (id, vector_index)
) STRICT;
INSERT INTO Process_vector_output (id, vector_index, factor_output, product_output)
SELECT id, process_id, factor, product_id FROM Output;

DROP TABLE Output;

CREATE TABLE Configuration_new (
    id INTEGER PRIMARY KEY,
    scenarios INTEGER DEFAULT 1 NOT NULL,
    minimum_iterations INTEGER DEFAULT 3 NOT NULL,
    maximum_iterations INTEGER DEFAULT 15 NOT NULL,
    write_lp INTEGER DEFAULT 0 NOT NULL
);

INSERT INTO Configuration_new
SELECT *
FROM Configuration;
DROP TABLE Configuration;
ALTER TABLE Configuration_new
    RENAME TO Configuration;

PRAGMA foreign_keys = OFF;
BEGIN TRANSACTION;
CREATE TABLE Product_new (
    id INTEGER PRIMARY KEY,
    label TEXT UNIQUE NOT NULL,
    unit TEXT NOT NULL,
    initial_availability REAL DEFAULT 0.0 NOT NULL,
    sell_limit REAL,
    sell_price REAL DEFAULT 0.0 NOT NULL
);
INSERT INTO Product_new
SELECT *
FROM Product;
DROP TABLE Product;
ALTER TABLE Product_new
    RENAME TO Product;
CREATE TABLE Process_new (
    id INTEGER PRIMARY KEY,
    label TEXT UNIQUE NOT NULL,
    capex REAL NOT NULL,
    opex REAL NOT NULL,
    base_capacity REAL NOT NULL,
    scaling_factor REAL DEFAULT 0.7 NOT NULL,
    interest_rate REAL DEFAULT 0.1 NOT NULL,
    lifespan INTEGER DEFAULT 20 NOT NULL
);
INSERT INTO Process_new
SELECT *
FROM Process;
DROP TABLE Process;
ALTER TABLE Process_new
    RENAME TO Process;
COMMIT;
PRAGMA foreign_keys = ON;