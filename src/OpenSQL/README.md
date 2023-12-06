# OpenSQL

Following PSRI's `OpenStudy` standards, SQL schemas for the `OpenSQL` framework should follow the conventions described in this document.


## SQL Schema Conventions


### Collections

- The Table name should be the same as the name of the Collection.
- The Table name of a Collection should beging with a capital letter and be in singular form.
- In case of a Collection with a composite name, the Table name should be separeted by an underscore.
- The Table must contain a primary key named `id`.

Examples:


```sql
CREATE TABLE Resource (
    id TEXT PRIMARY KEY,
    type TEXT NOT NULL DEFAULT "D" CHECK(type IN ('D', 'E', 'F'))
);

CREATE TABLE Thermal_Plant(
    id TEXT PRIMARY KEY,
    capacity REAL NOT NULL DEFAULT 0
);
```


### Non-vector Attributes

- The name of an Attribute should be in snake case and be in singular form.

Example:
```sql
CREATE TABLE Thermal_Plant(
    id TEXT PRIMARY KEY,
    capacity REAL NOT NULL
);
```

### Vector Attributes

- In case of a vector attribute, a Table should be created with its name indicating the name of the Collection and the name of the attribute, separated by `_vector_`, as presented below

<p style="text-align: center;"> COLLECTION_NAME_vector_ATTRIBUTE_NAME</p>

- Note that after **_vector_** the name of the attribute should follow the same rule as non-vector attributes.
- The Table must contain a Column named `id` and another named `idx`.
- There must be a Column named after the attribute name, which will store the value of the attribute for the specified element `id` and index `idx`.

Example:
```sql
CREATE TABLE Thermal_Plant_vector_some_value(
    id TEXT,
    idx INTEGER NOT NULL,
    some_value REAL NOT NULL,
    FOREIGN KEY (id) REFERENCES Thermal_Plant(id) ON DELETE CASCADE,
    PRIMARY KEY (id, idx)
);
```

### Time Series

- All Time Series for the elements from a Collection should be stored in a Table
- The Table name should be the same as the name of the Collection followed by `_timeseries`, as presented below

<p style="text-align: center"> COLLECTION_NAME_vector_ATTRIBUTE_NAME</p>

- Each Column of the table should be named after the name of the attribute.
- Each Column should store the path to the file containing the time series data.

Example:

```sql
CREATE TABLE Plant_timeseries (
    generation TEXT,
    cost TEXT
);
```

### 1 to 1 Relations

- One to One relations (1:1, To, From, etc) should be stored in the Source's Table.
- The name of the Column storing the Target's element id should have the name of the Target Collection in lowercase and indicate the type of the relation (e.g. `plant_turbine_to`).
- For the case of a standard 1 to 1 relationship, the name of the Column should be the name of the Target Collection followed by `_id` (e.g. `resource_id`).

Example:

```sql
CREATE TABLE Plant (
    id TEXT PRIMARY KEY,
    capacity REAL NOT NULL DEFAULT 0,
    resource_id TEXT,
    plant_turbine_to TEXT,
    plant_spill_to TEXT,
    FOREIGN KEY(resource_id) REFERENCES Resource(id),
    FOREIGN KEY(plant_turbine_to) REFERENCES Plant(id),
    FOREIGN KEY(plant_spill_to) REFERENCES Plant(id)
);
```

### N to N Relations

- N to N relations should be stored in a separate Table, named after the Source and Target Collections, separated by `_relation_`, as presented below

<p style="text-align: center"> SOURCE_NAME_relation_TARGET_NAME</p>

- The Table must contain a Column named `source_id` and another named `target_id`.
- The Table must contain a Column named `relation_type`

Example:

```sql
CREATE TABLE Plant_relation_Cost (
    source_id TEXT,
    target_id TEXT,
    relation_type TEXT,
    FOREIGN KEY(source_id) REFERENCES Plant(id) ON DELETE CASCADE,
    FOREIGN KEY(target_id) REFERENCES Costs(id) ON DELETE CASCADE,
    PRIMARY KEY (source_id, target_id, relation_type)
);
```