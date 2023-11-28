CREATE TABLE Study (
    id TEXT PRIMARY KEY
);

CREATE TABLE Plant (
    id TEXT PRIMARY KEY
);

CREATE TABLE _Plant_TimeSeries (
    id TEXT PRIMARY KEY,
    generation_file TEXT,
    cost_file TEXT
);