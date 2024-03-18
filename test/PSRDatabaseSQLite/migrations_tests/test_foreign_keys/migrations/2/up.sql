PRAGMA user_version = 2;
PRAGMA foreign_keys = ON;

ALTER TABLE Configuration ADD COLUMN write_lp INTEGER DEFAULT 0;