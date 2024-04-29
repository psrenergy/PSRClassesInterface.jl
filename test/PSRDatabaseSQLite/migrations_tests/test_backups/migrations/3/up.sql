-- add_test_3
PRAGMA user_version = 3;

CREATE TABLE TestThree (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    label TEXT UNIQUE NOT NULL,
    capacity INTEGER,
    some_other_coefficient REAL
);