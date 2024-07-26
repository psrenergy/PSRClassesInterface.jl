# Time Series

It is possible to store time series data in your database. Time series in `PSRDatabaseSQLite` are very flexible. You can have missing values, and you can have sparse data. 

There is a specific table format that must be followed. Consider the following example:

```sql
CREATE TABLE Resource (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    label TEXT UNIQUE NOT NULL
) STRICT;

CREATE TABLE Resource_time_series_group1 (
    id INTEGER, 
    date_time TEXT NOT NULL,
    some_vector1 REAL,
    some_vector2 REAL,
    FOREIGN KEY(id) REFERENCES Resource(id) ON DELETE CASCADE ON UPDATE CASCADE,
    PRIMARY KEY (id, date_time)
) STRICT; 
```

It is mandatory for a time series to be indexed by a `date_time` column with the following format: `YYYY-MM-DD HH:MM:SS`. You can use the `Dates.jl` package for handling this format.

```julia
using Dates
date = DateTime(2024, 3, 1) # 2024-03-01T00:00:00 (March 1st, 2024)
```

Notice that in this example, there are two value columns `some_vector1` and `some_vector2`. You can have as many value columns as you want. You can also separate the time series data into different tables, by creating a table `Resource_time_series_group2` for example.

It is also possible to add more dimensions to your time series, such as `block` and `scenario`.

```sql	
CREATE TABLE Resource_time_series_group2 (
    id INTEGER, 
    date_time TEXT NOT NULL,
    block INTEGER NOT NULL,
    some_vector3 REAL,
    some_vector4 REAL,
    FOREIGN KEY(id) REFERENCES Resource(id) ON DELETE CASCADE ON UPDATE CASCADE,
    PRIMARY KEY (id, date_time, block)
) STRICT; 
```

## Rules 

Time series in `PSRDatabaseSQLite` are very flexible. You can have missing values, and you can have sparse data. 

If you are querying for a time series row entry that has a missing value, it first checks if there is a data with a `date_time` earlier than the queried `date_time`. If there is, it returns the value of the previous data. If there is no data earlier than the queried `date_time`, it returns a specified value according to the type of data you are querying.

- For `Float64`, it returns `NaN`.
- For `Int64`, it returns `typemin(Int)`.
- For `String`, it returns `""` (empty String).
- For `DateTime`, it returns `typemin(DateTime)`.

For example, if you have the following data:

| **Date** | **some_vector1(Float64)** | **some_vector2(Float64)** |
|:--------:|:-----------:|:-----------:|
|   2020   |      1.0      |   missing   |
|   2021   |   missing   |      1.0      |
|   2022   |      3.0      |   missing   |

1. If you query for `some_vector1` at `2020`, it returns `1.0`. 
2. If you query for `some_vector2` at `2020`, it returns `NaN`. 
3. If you query for `some_vector1` at `2021`, it returns `1.0`. 
4. If you query for `some_vector2` at `2021`, it returns `1.0`. 
5. If you query for `some_vector1` at `2022`, it returns `3.0`. 
6. If you query for `some_vector2` at `2022`, it returns `1.0`.


## Inserting data

When creating a new element that has a time series, you can pass this information via a `DataFrame`. Consider the collection `Resource` with the two time series tables `Resource_time_series_group1` and `Resource_time_series_group2`.

```julia
using DataFrames
using Dates
using PSRClassesInterface
PSRDatabaseSQLite = PSRClassesInterface.PSRDatabaseSQLite

db = PSRDatabaseSQLite.create_empty_db_from_schema(db_path, path_schema; force = true)

PSRDatabaseSQLite.create_element!(db, "Configuration"; label = "Toy Case", value1 = 1.0)

df_group1 = DataFrame(;
        date_time = [DateTime(2000), DateTime(2001), DateTime(2002)],
        some_vector1 = [missing, 1.0, 2.0],
        some_vector2 = [1.0, missing, 5.0],
    )

df_group2 = DataFrame(;
            date_time = [
                DateTime(2000),
                DateTime(2000),
                DateTime(2000),
                DateTime(2000),
                DateTime(2001),
                DateTime(2001),
                DateTime(2001),
                DateTime(2009),
            ],
            block = [1, 1, 1, 1, 2, 2, 2, 2],
            some_vector3 = [1.0, 2.0, 3.0, 4.0, 1, 2, 3, 4],
            some_vector4 = [1.0, 2.0, 3.0, 4.0, 1, 2, 3, 4],
        )


PSRDatabaseSQLite.create_element!(
    db,
    "Resource";
    label = "Resource 1",
    group1 = df_group1,
    group2 = df_group2,
)
```

## Reading data

You can read the information from the time series in two different ways.

### Reading as a table
First, you can read the whole time series table for a given value, as a `DataFrame`.

```julia
df = PSRDatabaseSQLite.read_time_series_table(
    db,
    "Resource",
    "some_vector1",
    "Resource 1",
)
```

### Reading a single row

It is also possible to read a single row of the time series in the form of an array. This is useful when you want to query a specific dimension entry.
For this function, there are performance improvements when reading the data via caching the previous and next non-missing values. 

```julia
values = PSRDatabaseSQLite.read_time_series_row(
    db,
    "Resource",
    "some_vector1",
    Float64;
    date_time = DateTime(2020)
)
```

When querying a row, all values should non-missing. However, if there is a missing value, the function will return the previous non-missing value. And if even the previous value is missing, it will return a specified value according to the type of data you are querying.


- For `Float64`, it returns `NaN`.
- For `Int64`, it returns `typemin(Int)`.
- For `String`, it returns `""` (empty String).
- For `DateTime`, it returns `typemin(DateTime)`.

For example, if you have the following data for the time series `some_vector1`:

| **Date** | **Resource 1** | **Resource 2** |
|:--------:|:-----------:|:-----------:|
|   2020   |      1.0      |   missing   |
|   2021   |   missing   |      1.0      |
|   2022   |      3.0      |   missing   |

1. If you query at `2020`, it returns `[1.0, NaN]`. 
3. If you query at `2021`, it returns `[1.0, 1.0]`. 
5. If you query at `2022`, it returns `[3.0, 1.0]`. 


## Updating data

When updating one of the entries of a time series for a given element and attribute, you need to specify the exact dimension values of the row you want to update. 


For example, consider a time series that has `block` and `data_time` dimensions.

```julia
PSRDatabaseSQLite.update_time_series_row!(
    db,
    "Resource",
    "some_vector3",
    "Resource 1",
    10.0; # new value
    date_time = DateTime(2000),
    block = 1
)
```

## Deleting data

You can delete the whole time series of an element for a given time series group.
Consider the following table:

```sql
CREATE TABLE Resource_time_series_group1 (
    id INTEGER, 
    date_time TEXT NOT NULL,
    some_vector1 REAL,
    some_vector2 REAL,
    FOREIGN KEY(id) REFERENCES Resource(id) ON DELETE CASCADE ON UPDATE CASCADE,
    PRIMARY KEY (id, date_time)
) STRICT; 
```

This table represents a "group" that stores two time series `some_vector1` and `some_vector2`. You can delete all the data from this group by calling the following function:

```julia
PSRDatabaseSQLite.delete_time_series!(
    db,
    "Resource",
    "group1",
    "Resource 1",
)
```

When trying to read a time series that has been deleted, the function will return an empty `DataFrame`.
