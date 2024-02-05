# OpenSQL

Following PSRI's `OpenStudy` standards, SQL schemas for the `OpenSQL` framework should follow the conventions described in this document.


## SQL Schema Conventions


### Collections

- The Table name should be the same as the name of the Collection.
- The Table name of a Collection should begin with a capital letter and be in singular form.
- In case of a Collection with a composite name, the Table name should written in Pascal Case.
- The Table must contain a primary key named `id` that is an `INTEGER`.

Examples:


```sql
CREATE TABLE Resource (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    label TEXT UNIQUE NOT NULL,
    type TEXT NOT NULL DEFAULT "D" CHECK(type IN ('D', 'E', 'F'))
) STRICT;

CREATE TABLE ThermalPlant(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    label TEXT UNIQUE NOT NULL,
    capacity REAL NOT NULL DEFAULT 0
) STRICT;
```

#### Configuration collection

Every case must have a `Configuration`, which will store information from the case. 
The column `label` is not mandatory for a `Configuration` collection.

```sql
CREATE TABLE Configuration (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    value1 REAL NOT NULL DEFAULT 100,
    enum1 TEXT NOT NULL DEFAULT 'A' CHECK(enum1 IN ('A', 'B', 'C'))
) STRICT;
```


### Non-vector Attributes

- The name of an Attribute should be in snake case and be in singular form.

Example:
```sql
CREATE TABLE ThermalPlant(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    label TEXT UNIQUE NOT NULL,
    capacity REAL NOT NULL
) STRICT;
```

### Vector Attributes

- In case of a vector attribute, a Table should be created with its name indicating the name of the Collection and the name of the attribute, separated by `_vector_`, as presented below

<p style="text-align: center;"> COLLECTION_vector_ATTRIBUTE</p>

- Note that after **_vector_** the name of the attribute should follow the same rule as non-vector attributes.
- The Table must contain a Column named `id` and another named `idx`.
- There must be a Column named after the attribute name, which will store the value of the attribute for the specified element `id` and index `idx`.

Example:
```sql
CREATE TABLE ThermalPlant_vector_some_value(
    id INTEGER,
    idx INTEGER NOT NULL,
    some_value REAL NOT NULL,
    FOREIGN KEY (id) REFERENCES ThermalPlant(id) ON DELETE CASCADE,
    PRIMARY KEY (id, idx)
) STRICT;
```

### Time Series

- All Time Series for the elements from a Collection should be stored in a Table
- The Table name should be the same as the name of the Collection followed by `_timeseries`, as presented below

<p style="text-align: center"> COLLECTION_timeseries_ATTRIBUTE</p>

- Each Column of the table should be named after the name of the attribute.
- Each Column should store the path to the file containing the time series data.

Example:

```sql
CREATE TABLE Plant_timeseries (
    generation TEXT,
    cost TEXT
) STRICT;
```

### 1 to 1 Relations

- One to One relations (1:1, To, From, etc) should be stored in the Source's Table.
- The name of the Column storing the Target's element id should have the name of the Target Collection in lowercase and indicate the type of the relation (e.g. `plant_turbine_to`).
- For the case of a standard 1 to 1 relationship, the name of the Column should be the name of the Target Collection followed by `_id` (e.g. `resource_id`).

Example:

```sql
CREATE TABLE Plant (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    label TEXT UNIQUE NOT NULL,
    capacity REAL NOT NULL DEFAULT 0,
    resource_id INTEGER,
    plant_turbine_to INTEGER,
    plant_spill_to INTEGER,
    FOREIGN KEY(resource_id) REFERENCES Resource(id),
    FOREIGN KEY(plant_turbine_to) REFERENCES Plant(id),
    FOREIGN KEY(plant_spill_to) REFERENCES Plant(id)
) STRICT;
```

### N to N Relations

- N to N relations should be stored in a separate Table, named after the Source and Target Collections, separated by `_relation_`, as presented below

<p style="text-align: center"> SOURCE_relation_TARGET</p>

- The Table must contain a Column named `source_id` and another named `target_id`.
- The Table must contain a Column named `relation_type`

Example:

```sql
CREATE TABLE Plant_relation_Cost (
    source_id INTEGER,
    target_id INTEGER,
    relation_type TEXT,
    FOREIGN KEY(source_id) REFERENCES Plant(id) ON DELETE CASCADE,
    FOREIGN KEY(target_id) REFERENCES Costs(id) ON DELETE CASCADE,
    PRIMARY KEY (source_id, target_id, relation_type)
) STRICT;
```

## Migrations

Migrations are an important part of the `OpenSQL` framework. They are used to update the database schema to a new version without the need to delete the database and create a new one from scratch. Migrations are defined by two separate `.sql` files that are stored in the `migrations` directory of the model. The first file is the `up` migration and it is used to update the database schema to a new version. The second file is the `down` migration and it is used to revert the changes made by the `up` migration. Migrations are stored in directories in the model and they have a specific naming convention. The name of the migration folder should be the number of the version (e.g. `/migrations/1/`).

```md
database/migrations
├── 1
│   ├── up.sql
│   └── down.sql
└── 2
    ├── up.sql
    └── down.sql
```

### Creating a migration

It is advised to create new migrations using the functions from `OpenSQL`. First you need to make sure that the migrations directory is registered 
by the function `OpenSQL.set_migrations_folder` and after that you can create a new migration using the function `OpenSQL.create_migration`. This function will create a new migration file with the name and version specified by the user. The migration file will contain a template for the migration.

### Running migrations

To run migrations you need to use the function `OpenSQL.apply_migrations!`. There are various versions of this function, each one tailored to make something easier for the user.

### Testing migrations

It is very important to test if the migrations of a certain model are working as expected, so the user can be sure that the database schema is updated correctly. To test migrations you need to use the function `OpenSQL.test_migrations()`. It is highly advised that each model has one of these functions in their test suite to make sure that the migrations are working as expected.
