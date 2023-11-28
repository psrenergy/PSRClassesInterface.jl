CREATE TABLE Study (
    id TEXT PRIMARY KEY,
    value1 REAL NOT NULL DEFAULT 100,
    enum1 TEXT NOT NULL DEFAULT 'A' CHECK(enum1 IN ('A', 'B', 'C'))
);


CREATE TABLE Resource (
    id TEXT PRIMARY KEY,
    type TEXT NOT NULL DEFAULT "D" CHECK(type IN ('D', 'E', 'F'))
);

CREATE TABLE _Resource_some_values (
    id TEXT,
    idx INTEGER NOT NULL,
    some_values REAL NOT NULL,
    FOREIGN KEY(id) REFERENCES Resource(id) ON DELETE CASCADE,
    PRIMARY KEY (id, idx)
); 


CREATE TABLE Plant (
    id TEXT PRIMARY KEY,
    capacity REAL NOT NULL DEFAULT 0,
    resource_id TEXT,
    FOREIGN KEY(resource_id) REFERENCES Resource(id)
);

CREATE TABLE _Plant_TimeSeries (
    id TEXT PRIMARY KEY,
    generation_file TEXT
);