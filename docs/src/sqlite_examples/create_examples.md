
# PSRDatabaseSQLite Examples

## Introduction

This section provides examples of how to use the `PSRDatabaseSQLite` module for common database operations such as creating, updating, deleting records, and managing relationships.

## SQL Tables Used

### Creating Basic Tables with Vector Relationships

```sql
PRAGMA user_version = 1;
PRAGMA foreign_keys = ON;

CREATE TABLE Configuration (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    label TEXT UNIQUE NOT NULL,
    value1 REAL NOT NULL DEFAULT 100,
    enum1 TEXT NOT NULL DEFAULT 'A' CHECK(enum1 IN ('A', 'B', 'C'))
) STRICT;

CREATE TABLE Resource (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    label TEXT UNIQUE NOT NULL,
    type TEXT NOT NULL DEFAULT "D" CHECK(type IN ('D', 'E', 'F'))
) STRICT;

CREATE TABLE Plant (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    label TEXT UNIQUE NOT NULL,
    capacity REAL NOT NULL DEFAULT 0,
    resource_id INTEGER,
    FOREIGN KEY(resource_id) REFERENCES Resource(id) ON DELETE SET NULL ON UPDATE CASCADE
) STRICT;

CREATE TABLE Plant_vector_some_relation_type (
    id INTEGER,
    vector_index INTEGER NOT NULL,
    cost_some_relation_type INTEGER,
    FOREIGN KEY(id) REFERENCES Plant(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY(cost_some_relation_type) REFERENCES Cost(id) ON DELETE SET NULL ON UPDATE CASCADE,
    PRIMARY KEY (id, vector_index)
) STRICT;

CREATE TABLE Cost (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    label TEXT UNIQUE NOT NULL,
    value1 REAL NOT NULL DEFAULT 100
) STRICT;
```

These tables now include representations of vector relationships, which will be used in the subsequent examples.

## Creating an Element

The `create_element!` function is used to add a new element to a specified collection within a PSRDatabaseSQLite-managed database.

### Example:

```julia
PSRDatabaseSQLite.create_element!(db, "Configuration"; label = "Toy Case", value1 = 1.0)
PSRDatabaseSQLite.create_element!(db, "Resource"; label = "Resource 2")
PSRDatabaseSQLite.create_element!(db, "Resource"; label = "Resource 1", type = "E")
```

## Managing Scalar Relations

The `set_scalar_relation!` function is used to create a scalar relationship between two elements in different tables within a PSRDatabaseSQLite-managed database.

### Examples:

```julia
PSRDatabaseSQLite.set_scalar_relation!(
    db,
    "Plant",
    "Resource",
    "Plant 1",
    "Resource 1",
    "id",
)

PSRDatabaseSQLite.set_scalar_relation!(
    db,
    "Plant",
    "Resource",
    "Plant 1",
    "Resource 2",
    "id",
    "some_relation_type",
)
```

In these examples, we establish scalar relations between elements in the `Plant` and `Resource` tables.

## Managing Vector Relations

The `set_vector_relation!` function is used to create a vector relationship between an element in one table and multiple elements in another table within a PSRDatabaseSQLite-managed database.

### Examples:

```julia
PSRDatabaseSQLite.set_vector_relation!(
    db,
    "Plant",
    "Cost",
    "Plant 1",
    ["Cost 1"],
    "some_relation_type",
)

PSRDatabaseSQLite.set_vector_relation!(
    db,
    "Plant",
    "Cost",
    "Plant 2",
    ["Cost 1", "Cost 2", "Cost 3"],
    "some_relation_type",
)

PSRDatabaseSQLite.set_vector_relation!(
    db,
    "Plant",
    "Cost",
    "Plant 4",
    ["Cost 1", "Cost 3"],
    "id",
)
```

These examples demonstrate how to create vector relationships between elements in the `Plant` table and multiple elements in the `Cost` table.

## Updating Vector Parameters

The `update_vector_parameters!` function modifies vector parameters of an existing element in a specified collection within a PSRDatabaseSQLite-managed database.

### Examples:

```julia
PSRDatabaseSQLite.update_vector_parameters!(
    db,
    "Resource",
    "some_value_1",
    "Resource 1",
    [4.0, 5.0, 6.0],
)

PSRDatabaseSQLite.update_vector_parameters!(
    db,
    "Resource",
    "some_value_2",
    "Resource 1",
    [4.0, 5.0, 6.0],
)
```

These examples update the vector parameters `some_value_1` and `some_value_2` for the element `"Resource 1"` in the `Resource` table.

## Deleting an Element

The `delete_element!` function removes an existing element from a specified collection within a PSRDatabaseSQLite-managed database.

### Example:

```julia
PSRDatabaseSQLite.delete_element!(db, "Plant", "Plant 3")
```

This example removes the element with label `"Plant 3"` from the `Plant` table.

