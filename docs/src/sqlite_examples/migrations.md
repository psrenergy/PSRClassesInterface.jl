# Migration Examples

Migrations are a way to manage the evolution of the database schema over time.
As mentioned in the documentation for [PSRDatabaseSQLite]("../psrdatabasesqlite/rules.md"), migrations are defined by two separate `.sql` files that are stored in the `migrations` directory of the model. The first file is the `up` migration and it is used to update the database schema to a new version. The second file is the `down` migration and it is used to revert the changes made by the `up` migration. Migrations are stored in directories in the model and they have a specific naming convention. The name of the migration folder should be the number of the version (e.g. `/migrations/1/`).

In this section, we will provide some examples of migrations.
First, let us start with the first migration, the one that creates the initial database schema.

### Adding two tables to the database

```sql
PRAGMA user_version = 1; -- Set the database version to 1
PRAGMA foreign_keys = ON; -- Enable foreign keys to enforce referential integrity

-- Create the Configuration table
CREATE TABLE Configuration (
    id INTEGER PRIMARY KEY,
    label TEXT UNIQUE NOT NULL,
    value TEXT NOT NULL
) ;

-- Create Plant table
CREATE TABLE Plant (
    id INTEGER PRIMARY KEY,
    label TEXT UNIQUE NOT NULL,
    capacity REAL NOT NULL,
    bus_name TEXT NOT NULL
) ;
```

This schema is the `up.sql` migration for version 1. It creates two tables, `Configuration` and `Plant`. Now we have to create the `down.sql` migration for version 1. This migration should drop the tables created in the `up.sql` migration.

```sql
PRAGMA user_version = 0; -- Set the database version to 0
-- Drop the Configuration table
DROP TABLE Configuration;
-- Drop the Plant table
DROP TABLE Plant;
```

### Adding a new column

Now let us create a migration that adds a new column to the `Configuration` and `Plant` tables.

```sql
PRAGMA user_version = 2; -- Set the database version to 2
PRAGMA foreign_keys = ON; -- Enable foreign keys to enforce referential integrity

-- Add the description column to the Configuration table
ALTER TABLE Configuration ADD COLUMN description TEXT;

-- Add the type column to the Plant table
ALTER TABLE Plant ADD COLUMN type INTEGER NOT NULL DEFAULT 0;
```

This is the `up.sql` migration for version 2. The `down.sql` migration should remove the column added in the `up.sql` migration.

```sql
PRAGMA user_version = 1; -- Set the database version to 1

-- Remove the description column from the Configuration table
ALTER TABLE Configuration DROP COLUMN description;

-- Remove the type column from the Plant table
ALTER TABLE Plant DROP COLUMN type;
```

### Renaming a table

Let us create a migration that renames the `Plant` table to `PowerPlant`.

```sql
PRAGMA user_version = 3; -- Set the database version to 3
PRAGMA foreign_keys = ON; -- Enable foreign keys to enforce referential integrity

-- Rename the Plant table to PowerPlant
ALTER TABLE Plant RENAME TO PowerPlant;
```

This is the `up.sql` migration for version 3. The `down.sql` migration should rename the `PowerPlant` table back to `Plant`.

```sql
PRAGMA user_version = 2; -- Set the database version to 2

-- Rename the PowerPlant table to Plant
ALTER TABLE PowerPlant RENAME TO Plant;
```

### Adding a foreign key constraint

Let us create a migration that adds a foreign key constraint to the `PowerPlant` table.
First, we need to create a new table, `Resource`, that will be referenced by the `PowerPlant` table.

Adding a foreign key constraint, however, is not as trivial as adding a column or renaming a table. We need to follow these steps:

1. Disable foreign key constraints
2. Start a transaction
3. Create an auxiliary `new_PowerPlant` table with the new column and the foreign key constraint
4. Copy the data from the `PowerPlant` table to the `new_PowerPlant` table
5. Drop the `PowerPlant` table
6. Rename the `new_PowerPlant` table to `PowerPlant`
7. Check if any foreign key constraints were violatet with `PRAGMA foreign_key_check`
8. Commit the transaction
9. Enable foreign key constraints 

```sql
PRAGMA user_version = 4; -- Set the database version to 4
PRAGMA foreign_keys = ON; -- Enable foreign keys to enforce referential integrity

-- Create the Resource table
CREATE TABLE Resource (
    id INTEGER PRIMARY KEY,
    label TEXT UNIQUE NOT NULL
) ;

-- Disable foreign key constraints
PRAGMA foreign_keys = OFF;

-- Start a transaction
BEGIN TRANSACTION;

-- Create the new PowerPlant table
CREATE TABLE new_PowerPlant (
    id INTEGER PRIMARY KEY,
    label TEXT UNIQUE NOT NULL,
    capacity REAL NOT NULL,
    bus_name TEXT NOT NULL,
    type INTEGER NOT NULL DEFAULT 0,
    resource_id INTEGER,
    FOREIGN KEY (resource_id) REFERENCES Resource(id) ON UPDATE CASCADE ON DELETE CASCADE
) ;

-- Copy the data from the PowerPlant table to the new PowerPlant table
INSERT INTO new_PowerPlant (id, label, capacity, bus_name, type)
SELECT id, label, capacity, bus_name, type FROM PowerPlant;

-- Drop the PowerPlant table
DROP TABLE PowerPlant;

-- Rename the new PowerPlant table to PowerPlant
ALTER TABLE new_PowerPlant RENAME TO PowerPlant;

-- Check if any foreign key constraints were violated
PRAGMA foreign_key_check;

-- Commit the transaction
COMMIT;

-- Enable foreign key constraints
PRAGMA foreign_keys = ON;
``` 

Now, the `down.sql` migration should revert the changes made by the `up.sql` migration.

```sql
PRAGMA user_version = 3; -- Set the database version to 3

-- Disable foreign key constraints
PRAGMA foreign_keys = OFF;

-- Start a transaction
BEGIN TRANSACTION;

-- Create the new PowerPlant table
CREATE TABLE new_PowerPlant (
    id INTEGER PRIMARY KEY,
    label TEXT UNIQUE NOT NULL,
    capacity REAL NOT NULL,
    bus_name TEXT NOT NULL,
    type INTEGER NOT NULL DEFAULT 0
) ;

-- Copy the data from the PowerPlant table to the new PowerPlant table
INSERT INTO new_PowerPlant (id, label, capacity, bus_name, type)
SELECT id, label, capacity, bus_name, type FROM PowerPlant;

-- Drop the PowerPlant table
DROP TABLE PowerPlant;

-- Rename the new PowerPlant table to PowerPlant
ALTER TABLE new_PowerPlant RENAME TO PowerPlant;

-- Check if any foreign key constraints were violated
PRAGMA foreign_key_check;

-- Commit the transaction
COMMIT;

-- Enable foreign key constraints
PRAGMA foreign_keys = ON;

-- Drop the Resource table
DROP TABLE Resource;
```

### Dividing a table into two tables

Let us create a migration that divides the `PowerPlant` table into two tables, `HydroPlant` and `ThermalPlant`. 
`HydroPlant` corresponds to the rows with `type = 0` and `ThermalPlant` corresponds to the rows with `type = 1`.

```sql
PRAGMA user_version = 5; -- Set the database version to 5



PRAGMA foreign_keys = OFF;
BEGIN TRANSACTION;

-- Create the HydroPlant table
CREATE TABLE HydroPlant (
    id INTEGER PRIMARY KEY,
    label TEXT UNIQUE NOT NULL,
    capacity REAL NOT NULL,
    bus_name TEXT NOT NULL,
    resource_id INTEGER,
    FOREIGN KEY (resource_id) REFERENCES Resource(id) ON UPDATE CASCADE ON DELETE CASCADE
) ;

-- Create the ThermalPlant table
CREATE TABLE ThermalPlant (
    id INTEGER PRIMARY KEY,
    label TEXT UNIQUE NOT NULL,
    capacity REAL NOT NULL,
    bus_name TEXT NOT NULL,
    resource_id INTEGER,
    FOREIGN KEY (resource_id) REFERENCES Resource(id) ON UPDATE CASCADE ON DELETE CASCADE
) ;

-- Fill the HydroPlant table
INSERT INTO HydroPlant (id, label, capacity, bus_name, resource_id)
SELECT id, label, capacity, bus_name, resource_id FROM PowerPlant WHERE type = 0;

-- Fill the ThermalPlant table
INSERT INTO ThermalPlant (id, label, capacity, bus_name, resource_id)
SELECT id, label, capacity, bus_name, resource_id FROM PowerPlant WHERE type = 1;

-- Drop the PowerPlant table
DROP TABLE PowerPlant;

PRAGMA foreign_key_check;
COMMIT;
PRAGMA foreign_keys = ON;

```

This is the `up.sql` migration for version 5. The `down.sql` migration should revert the changes made by the `up.sql` migration.

```sql
PRAGMA user_version = 4; -- Set the database version to 4
PRAGMA foreign_keys = ON; -- Enable foreign keys to enforce referential integrity

-- Create the PowerPlant table
CREATE TABLE PowerPlant (
    id INTEGER PRIMARY KEY,
    label TEXT UNIQUE NOT NULL,
    capacity REAL NOT NULL,
    type INTEGER NOT NULL DEFAULT 0,
    bus_name TEXT NOT NULL,
    resource_id INTEGER,
    FOREIGN KEY (resource_id) REFERENCES Resource(id) ON UPDATE CASCADE ON DELETE CASCADE
) ;

-- Fill the PowerPlant table
INSERT INTO PowerPlant (id, label, capacity, bus_name, type, resource_id)
SELECT id, label, capacity, bus_name, 0, resource_id FROM HydroPlant;

INSERT INTO PowerPlant (id, label, capacity, bus_name, type, resource_id)
SELECT id, label, capacity, bus_name, 1, resource_id FROM ThermalPlant;

-- Drop the HydroPlant table
DROP TABLE HydroPlant;

-- Drop the ThermalPlant table
DROP TABLE ThermalPlant;
```

### Create a table with data from another table

Let us create a migration that adds a new Table `Bus` with data from the `HydroPlant` and `ThermalPlant` tables.
These tables already have a column `bus_name` that will be used to fill the `Bus` table.
After creating the `Bus` table, we will remove the `bus_name` column from the `HydroPlant` and `ThermalPlant` tables.
Moreover, the `bus_name` column in the `PowerPlant` table will be replaced by a `bus_id` column that references the `Bus` table.

```sql
PRAGMA user_version = 6; -- Set the database version to 6
PRAGMA foreign_keys = ON; -- Enable foreign keys to enforce referential integrity

-- Create the Bus table
CREATE TABLE Bus (
    id INTEGER PRIMARY KEY,
    label TEXT UNIQUE NOT NULL
) ;

-- Fill the Bus table
INSERT INTO Bus (label)
SELECT DISTINCT bus_name FROM HydroPlant;

INSERT INTO Bus (label)
SELECT DISTINCT bus_name FROM ThermalPlant;

PRAGMA foreign_keys = OFF;
BEGIN TRANSACTION;

-- Add foreign key 
CREATE TABLE new_HydroPlant (
    id INTEGER PRIMARY KEY,
    label TEXT UNIQUE NOT NULL,
    capacity REAL NOT NULL,
    resource_id INTEGER,
    bus_id INTEGER,
    FOREIGN KEY (resource_id) REFERENCES Resource(id) ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (bus_id) REFERENCES Bus(id) ON UPDATE CASCADE ON DELETE CASCADE
) ;

CREATE TABLE new_ThermalPlant (
    id INTEGER PRIMARY KEY,
    label TEXT UNIQUE NOT NULL,
    capacity REAL NOT NULL,
    resource_id INTEGER,
    bus_id INTEGER,
    FOREIGN KEY (resource_id) REFERENCES Resource(id) ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (bus_id) REFERENCES Bus(id) ON UPDATE CASCADE ON DELETE CASCADE
) ;

-- Copy the data from the HydroPlant table to the new HydroPlant table
INSERT INTO new_HydroPlant (id, label, capacity, resource_id)
SELECT id, label, capacity, resource_id FROM HydroPlant;

-- Copy the data from the ThermalPlant table to the new ThermalPlant table
INSERT INTO new_ThermalPlant (id, label, capacity, resource_id)
SELECT id, label, capacity, resource_id FROM ThermalPlant;

-- Add data for the bus_id column
UPDATE new_HydroPlant SET bus_id = (SELECT Bus.id FROM Bus
INNER JOIN HydroPlant ON Bus.label = HydroPlant.bus_name AND 
HydroPlant.id = new_HydroPlant.id
);
UPDATE new_ThermalPlant SET bus_id = (SELECT Bus.id FROM Bus
INNER JOIN ThermalPlant ON Bus.label = ThermalPlant.bus_name AND
ThermalPlant.id = new_ThermalPlant.id
);

-- Drop tables
DROP TABLE HydroPlant;
DROP TABLE ThermalPlant;

-- Rename tables
ALTER TABLE new_HydroPlant RENAME TO HydroPlant;
ALTER TABLE new_ThermalPlant RENAME TO ThermalPlant;

PRAGMA foreign_key_check;
COMMIT;
PRAGMA foreign_keys = ON;
```

This is the `up.sql` migration for version 6. The `down.sql` migration should revert the changes made by the `up.sql` migration.

```sql
PRAGMA user_version = 5; -- Set the database version to 5


PRAGMA foreign_keys = OFF;
BEGIN TRANSACTION;

-- Create auxiliary tables
CREATE TABLE new_HydroPlant (
    id INTEGER PRIMARY KEY,
    label TEXT UNIQUE NOT NULL,
    capacity REAL NOT NULL,
    resource_id INTEGER,
    bus_name TEXT,
    FOREIGN KEY (resource_id) REFERENCES Resource(id) ON UPDATE CASCADE ON DELETE CASCADE
) ;

CREATE TABLE new_ThermalPlant (
    id INTEGER PRIMARY KEY,
    label TEXT UNIQUE NOT NULL,
    capacity REAL NOT NULL,
    resource_id INTEGER,
    bus_name TEXT,
    FOREIGN KEY (resource_id) REFERENCES Resource(id) ON UPDATE CASCADE ON DELETE CASCADE
) ;

-- Copy the data from the HydroPlant table to the new HydroPlant table
INSERT INTO new_HydroPlant (id, label, capacity, resource_id)
SELECT id, label, capacity, resource_id FROM HydroPlant;

-- Copy the data from the ThermalPlant table to the new ThermalPlant table
INSERT INTO new_ThermalPlant (id, label, capacity, resource_id)
SELECT id, label, capacity, resource_id FROM ThermalPlant;

-- Add data for the bus_name column
UPDATE new_HydroPlant SET bus_name = (SELECT Bus.label FROM Bus
INNER JOIN HydroPlant ON Bus.id = HydroPlant.bus_id AND 
HydroPlant.id = new_HydroPlant.id
);

UPDATE new_ThermalPlant SET bus_name = (SELECT Bus.label FROM Bus
INNER JOIN ThermalPlant ON Bus.id = ThermalPlant.bus_id AND
ThermalPlant.id = new_ThermalPlant.id
);

-- Drop tables
DROP TABLE HydroPlant;
DROP TABLE ThermalPlant;

-- Rename tables
ALTER TABLE new_HydroPlant RENAME TO HydroPlant;
ALTER TABLE new_ThermalPlant RENAME TO ThermalPlant;

-- Drop the Bus table
DROP TABLE Bus;

PRAGMA foreign_key_check;
COMMIT;
PRAGMA foreign_keys = ON;
```



