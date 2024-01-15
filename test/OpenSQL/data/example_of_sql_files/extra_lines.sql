PRAGMA foreign_keys = ON;
PRAGMA user_version = 1;

CREATE TABLE Configurations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    value TEXT NOT NULL
);


