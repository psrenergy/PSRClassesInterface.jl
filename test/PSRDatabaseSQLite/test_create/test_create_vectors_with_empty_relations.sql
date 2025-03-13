PRAGMA user_version = 1;
PRAGMA foreign_keys = ON;

CREATE TABLE Configuration (
    id INTEGER PRIMARY KEY,
    label TEXT UNIQUE NOT NULL
);

CREATE TABLE Process (
    id INTEGER PRIMARY KEY,
    label TEXT UNIQUE NOT NULL
);

CREATE TABLE Plant (
    id INTEGER PRIMARY KEY,
    label TEXT UNIQUE NOT NULL
);

CREATE TABLE Plant_vector_process (
    id INTEGER,
    vector_index INTEGER NOT NULL,
    process_id INTEGER,
    process_capacity REAL NOT NULL,
    process_is_candidate INTEGER NOT NULL,
    process_substitute INTEGER,
    FOREIGN KEY(process_id) REFERENCES Process(id) ON DELETE SET NULL ON UPDATE CASCADE,
    FOREIGN KEY(process_substitute) REFERENCES Process(id) ON DELETE SET NULL ON UPDATE CASCADE,
    PRIMARY KEY (id, vector_index)
);
