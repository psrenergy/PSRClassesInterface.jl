# OpenSQL

Following PSRI's `OpenStudy` standards, SQL schemas for the `OpenSQL` framework should follow the conventions described in this document.


## SQL Schema Conventions


### Collections

- The Table name should be the same as the name of the Collection.
- The Table name of a Collection should beging with a capital letter and be in singular form.
- In case of a Collection with a composite name, the Table name should written in Pascal Case.
- The Table must contain a primary key named `id` that is an `INTEGER`. You should use the `AUTOINCREMENT` keyword to automatically generate the `id` for each element.

Examples:

```sql
CREATE TABLE Resource (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    label TEXT UNIQUE NOT NULL,
    some_type TEXT
) STRICT;

CREATE TABLE ThermalPlant(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    label TEXT UNIQUE NOT NULL,
    minimum_generation REAL DEFAULT 0
) STRICT;
```

#### Configuration collection

Every database definition must have a `Configuration`, which will store information from the case. 
The column `label` is not mandatory for a `Configuration` collection.

```sql
CREATE TABLE Configuration (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    value1 REAL NOT NULL DEFAULT 100,
) STRICT;
```

### Non-vector Attributes

- The name of an Attribute should be in snake case and be in singular form.

Example:
```sql
CREATE TABLE ThermalPlant(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    label TEXT UNIQUE NOT NULL,
    minimum_generation REAL NOT NULL
    some_example_of_attribute REAL
) STRICT;
```

If an attribute name starts with `date` it should be stored as a `TEXT` and indicates a date that will be mapped to a DateTime object.

Example:
```sql
CREATE TABLE ThermalPlant(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    label TEXT UNIQUE NOT NULL,
    minimum_generation REAL NOT NULL,
    date_of_construction TEXT
) STRICT;
```

If an attribute name starts with the name of another collection it should be stored as a `INTEGER` and indicates a relation with another collection. It should never have the `NOT NULL` constraint. All references should always declare the `ON UPDATE CASCADE ON DELETE CASCADE` constraint. In the example below the attribute `gaugingstation_id` indicates that the collection Plant has an `id` relation with the collection GaugingStation and the attribute `plant_spill_to` indicates that the collection Plant has a `spill_to` relation with itself.

Example:
```sql
CREATE TABLE Plant(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    label TEXT UNIQUE NOT NULL,
    capacity REAL NOT NULL
    gaugingstation_id INTEGER,
    plant_spill_to INTEGER,
    FOREIGN KEY(gaugingstation_id) REFERENCES GaugingStation(id) ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY(plant_spill_to) REFERENCES Plant(id) ON UPDATE CASCADE ON DELETE CASCADE
) STRICT;
```

### Vector Attributes

- In case of a vector attribute, a table should be created with its name indicating the name of the Collection and the name of a group of the attribute, separated by `_vector_`, as presented below

<p style="text-align: center;"> COLLECTION_vector_GROUP_OF_ATTRIBUTES</p>

- The table must contain a Column named `id` and another named `vector_index`.
- There must be a Column named after the attributes names, which will store the value of the attribute for the specified element `id` and index `vector_index`.

These groups are used to store vectors that should have the same size. If two vectors don't necessarily have the same size, they should be stored in different groups.

Example:
```sql
CREATE TABLE ThermalPlant_vector_some_group(
    id INTEGER,
    vector_index INTEGER NOT NULL,
    some_value REAL NOT NULL,
    some_other_value REAL,
    FOREIGN KEY (id) REFERENCES ThermalPlant(id) ON UPDATE CASCADE ON DELETE CASCADE,
    PRIMARY KEY (id, vector_index)
) STRICT;
```

Example of a small time series
```sql
CREATE TABLE ThermalPlant_vector_some_group(
    id INTEGER,
    vector_index INTEGER NOT NULL,
    date_of_modification REAL NOT NULL,
    capacity REAL,
    FOREIGN KEY (id) REFERENCES ThermalPlant(id) ON UPDATE CASCADE ON DELETE CASCADE,
    PRIMARY KEY (id, vector_index)
) STRICT;
```

A vector relation with another collection should be stored in a table of vector groups and be defined the same way as a vector attribute. To tell that it is a relation with another collection, the name of the relational attribute should be the name of the target collection followed by the relation type defined as `_relation_type`, i.e. `gaugingstation_id` indicated that the collection HydroPlant has an `id` relation with the collection GaugingStation. If the name of the attribute was `gaugingstation_one_to_one`, it would indicate that the collection HydroPlant has a relation `one_to_one` with the collection GaugingStation.

```sql
CREATE TABLE HydroPlant_vector_GaugingStation(
    id INTEGER,
    vector_index INTEGER NOT NULL,
    conversion_factor REAL NOT NULL,
    gaugingstation_id INTEGER,
    FOREIGN KEY (gaugingstation_id) REFERENCES GaugingStation(id) ON UPDATE CASCADE ON DELETE CASCADE,
    PRIMARY KEY (id, vector_index)
) STRICT;

```

### Time Series

- All Time Series for the elements from a Collection should be stored in a Table
- The Table name should be the same as the name of the Collection followed by `_timeseriesfiles`, as presented below

<p style="text-align: center"> COLLECTION_vector_ATTRIBUTE</p>

- Each Column of the table should be named after the name of the attribute.
- Each Column should store the path to the file containing the time series data.

Example:

```sql
CREATE TABLE Plant_timeseriesfiles (
    generation TEXT,
    cost TEXT
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