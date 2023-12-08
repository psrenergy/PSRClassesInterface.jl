CREATE TABLE Configuration (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    label TEXT UNIQUE,
    value1 REAL NOT NULL DEFAULT 100,
    enum1 TEXT NOT NULL DEFAULT 'A' CHECK(enum1 IN ('A', 'B', 'C'))
);


CREATE TABLE Resource (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    label TEXT UNIQUE,
    type TEXT NOT NULL DEFAULT "D" CHECK(type IN ('D', 'E', 'F'))
);

CREATE TABLE Resource_vector_some_value (
    id INTEGER, 
    idx INTEGER NOT NULL,
    some_value REAL NOT NULL,
    FOREIGN KEY(id) REFERENCES Resource(id) ON DELETE CASCADE,
    PRIMARY KEY (id, idx)
); 

CREATE TABLE Cost (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    label TEXT UNIQUE,
    value REAL NOT NULL DEFAULT 100
);

CREATE TABLE Plant (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    label TEXT UNIQUE,
    capacity REAL NOT NULL DEFAULT 0,
    resource_id INTEGER,
    plant_turbine_to INTEGER,
    plant_spill_to INTEGER,
    FOREIGN KEY(resource_id) REFERENCES Resource(id),
    FOREIGN KEY(plant_turbine_to) REFERENCES Plant(id),
    FOREIGN KEY(plant_spill_to) REFERENCES Plant(id)
);

CREATE TABLE Plant_relation_Cost (
    source_id INTEGER,
    target_id INTEGER,
    relation_type TEXT,
    FOREIGN KEY(source_id) REFERENCES Plant(id) ON DELETE CASCADE,
    FOREIGN KEY(target_id) REFERENCES Costs(id) ON DELETE CASCADE,
    PRIMARY KEY (source_id, target_id, relation_type)
);

CREATE TABLE Plant_timeseries (
    generation TEXT,
    cost TEXT
);