# Loading an incomplete Study

From other tutorials, you already know how to create a Study or load it from a JSON file. However, sometimes your JSON file containing the Study data might be missing some information.

In this tutorial, you will learn how to load an incomplete JSON file and fill the missing data with default values.

From the following code block, there are three important parameters:

- `use_defaults`: If `true`, the function will fill the missing data with default values.
- `rectify_json_data`: Some data types, such as `Date`, are not supported by JSON and are treated as strings. If `true`, the function will convert the strings to the correct data type.
- `defaults_path`: The path to the JSON file containing the default values. If you don't provide a path, the function will use the default path from the `PSRI` module.

```julia
data = PSRI.load_study(
    PSRI.OpenInterface();
    data_path = CASE_PATH,
    use_defaults = true,
    rectify_json_data = true,
    defaults_path = DEFAULTS_PATH,
)
```

!!! warning
    You can still load a Study with missing data without filling it with default values. However, you will get error messages when querying missing information.