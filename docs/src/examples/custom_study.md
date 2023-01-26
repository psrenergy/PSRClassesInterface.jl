# Customizing a Study

In this tutorial you will learn how to customize several items of your study, such as:
- Adding new attributes to an existing collection in runtime
- Creating a new collection in runtime
- Defining a new relation between two collections in runtime
- Defining a template for your model from scratch

## How we define the template for our studies

First of all, it's important to understand how we define the default rules for each collection in our study.

Let's take a look at the function [`PSRI.create_study`](@ref):
```
function create_study(
    ::OpenInterface;
    data_path::AbstractString = pwd(),
    pmd_files::Vector{String} = String[],
    pmds_path::AbstractString = PMD._PMDS_BASE_PATH,
    defaults_path::Union{AbstractString,Nothing} = PSRCLASSES_DEFAULTS_PATH,
    defaults::Union{Dict{String,Any},Nothing} = _load_defaults!(),
    netplan::Bool = false,
    model_template_path::Union{String,Nothing} = nothing,
    study_collection::String = "PSRStudy",
)
```

From our other examples, you will notice that we have never filled most of these parameters, leaving them with their default values. However, the following are important for working with custom Studies:

<details>
<summary>pmd_files or pmds_path</summary>

A PMD file is where we define the collections and their attributes for a Study.

</details>

<details>
<summary>model_template_path</summary>
</details>

<details>
<summary>defaults_path</summary>
</details>


## Costumizing in runtime

### Custom collections and attributes

