PRAGMA user_version = 2;

CREATE TABLE Input (
    id INTEGER PRIMARY KEY,
    process_id INTEGER,
    product_id INTEGER,
    factor REAL,
    FOREIGN KEY(process_id) REFERENCES Process(id) ON UPDATE CASCADE ON DELETE SET NULL,
    FOREIGN KEY(product_id) REFERENCES Product(id) ON UPDATE CASCADE ON DELETE SET NULL
);

INSERT INTO Input (id, process_id, product_id, factor)
SELECT 
    ROW_NUMBER() OVER () AS id,
    id AS process_id,
    product_input AS product_id,
    factor_input AS factor
FROM
    Process_vector_input;

DROP TABLE Process_vector_input;

CREATE TABLE Output (
    id INTEGER PRIMARY KEY,
    process_id INTEGER,
    product_id INTEGER,
    factor REAL,
    FOREIGN KEY(process_id) REFERENCES Process(id) ON UPDATE CASCADE ON DELETE SET NULL,
    FOREIGN KEY(product_id) REFERENCES Product(id) ON UPDATE CASCADE ON DELETE SET NULL
);

INSERT INTO Output (id, process_id, product_id, factor)
SELECT 
    ROW_NUMBER() OVER () AS id,
    id AS process_id,
    product_output AS product_id,
    factor_output AS factor
FROM
    Process_vector_output;

DROP TABLE Process_vector_output;

CREATE TABLE Configuration_new (
    id INTEGER PRIMARY KEY,
    scenarios INTEGER DEFAULT 1,
    minimum_iterations INTEGER DEFAULT 3,
    maximum_iterations INTEGER DEFAULT 15,
    write_lp INTEGER DEFAULT 0
);

INSERT INTO Configuration_new SELECT * FROM Configuration;

DROP TABLE Configuration;

ALTER TABLE Configuration_new RENAME TO Configuration;