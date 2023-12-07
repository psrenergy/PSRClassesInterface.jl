# Customizing a Study

In this tutorial you will learn how to customize several items of your study.

## How we define the template for our studies

First of all, it's important to understand how we define the default rules for each collection in our study.

Let's take a look at the function [`PSRClassesInterface.create_study`](@ref) for the `OpenStudy` interface. It has the following signature:

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

- `pmd_files` or `pmds_path`
- `model_template_path`
- `defaults_path`

A PMD is a `.pmd` file where we define collections and the metadata for each of their attributes. A Model Template is a JSON file where we map the name of collections in the PMD to their names in our Study. Finally, Defaults is also a JSON file where we set the default values for some - or all - attributes in collections.

When we create a study, we parse the PMD file(s) and the Model Template, creating the `data.data_struct`, a Dict that contains the metadata for attributes and their names. 

When we create an element, PSRI uses `data.data_struct` to check if the values for the attributes that we have filled are in agreement with their definition(if they should be Vectors, Floats, ...) and if any attribute is missing. 


## Defining custom structures with new PMD file

When you already have your structures defined in a PMD file, you don't need to create them in runtime. First, save this code as a `.pmd` file, where we define a Study collection, different from `PSRStudy` and a `PSRExtra` collection. 

```
DEFINE_MODEL MODL:Custom_Study_Config
	PARM REAL 		Value1
	PARM REAL 		Value3
	PARM STRING     Text
END_MODEL

DEFINE_MODEL MODL:Extra_Collection
	PARM REAL 		ExtraValue
	PARM STRING     Text
END_MODEL
```

Now we need a Model Template file, to map our PMD Model to collections. Just as we did before, copy the following code into a file, but save it as a `.json` this time.

```
[
    {
        "classname": "CustomStudy",
        "models": ["Custom_Study_Config"]
    },
    {
        "classname": "PSRExtra",
        "models": ["Extra_Collection"]
    }
]
```

After that, we can create a Study with [`PSRClassesInterface.create_study`](@ref) using a few extra mandatory parameters.

```@example custom_study
import PSRClassesInterface
const PSRI = PSRClassesInterface


temp_path = joinpath(tempdir(), "PSRI")
json_path = joinpath(path_to_directory, "custom_json.json")

data = PSRI.create_study(PSRI.OpenInterface(), 
    data_path = temp_path, 
    pmds_path = path_to_directory, 
    model_template_path = json_path, 
    study_collection = "CustomStudy", 
    defaults = Dict{String,Any}(
        "CustomStudy" => Dict{String,Any}(
            "AVId" => "avid", 
            "Text" => "custom", 
            "Value1" => 1.0, 
            "Value3" => 2.0, 
            "code" => Int32(10), 
            "name" => "name"
        )
    )
)

```