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

- `pmd_files` or `pmds_path`
- `model_template_path`
- `defaults_path`

A PMD is a `.pmd` file where we define collections and the metadata for each of their attributes. A Model Template is a JSON file where we map the name of collections in the PMD to their names in our Study. Finally, Defaults is also a JSON file where we set the default values for some - or all - attributes in collections.

When we create a study, we parse the PMD file(s) and the Model Template, creating the `data.data_struct`, a Dict that contains the metadata for attributes and their names. 

When we create an element, PSRI uses `data.data_struct` to check if the values for the attributes that we have filled are in agreement with their definition(if they should be Vectors, Floats, ...) and if any attribute is missing. 



## Costumizing in runtime

### Custom collections, attributes and relations

First, let's create a new Study.

```
temp_path = joinpath(tempdir(), "PSRI")
data = PSRI.create_study(PSRI.OpenInterface(), data_path = temp_path)
```
#### Custom Attribute
Now we want to create a `PSRBus` element with an extra attribute `BusCustom`. However, if we do that, we will receive an error.
```
 PSRI.create_element!(data, "PSRBus",
           "AVId" =>  "avid",
           "name" =>  "busname",
           "Kv"   =>  5.0,
           "code" =>  7,
           "icca" =>  3,
           "BusCustom" => 7.0
        )
```
> <span style="color:red">ERROR:</span> Invalid attributes for collection 'PSRBus':
>
>  BusCustom

So what we want to do is add a new attribute to the collection `PSRBus` with the function [`PSRI.create_attribute!`](@ref).

```
PSRI.create_attribute!(data, "PSRBus", 
    "BusCustom", # attribute name
    false,       # is a vector?
    Float64,      # Type
    0           # dimension
)
```

After that, we can create a `PSRBus` with a `BusCustom` attribute.

#### Custom Collection

Let's say that we want to use a new collection named `PSRExtra`. For that, we have to use the function [`PSRI.create_collection!`](@ref).

```
PSRI.create_collection!(data, "PSRExtra")
```

As you can see from the parameters that we have used to define our new collection, there are no attributes. So we have to add some custom attributes for our new collection.

```
PSRI.create_attribute!(data, "PSRExtra",
    "extra_name",
    false,
    String,
    0
    )

PSRI.create_attribute!(data, "PSRExtra",
    "extra_value",
    false,
    Float64,
    0
    )

```

As soon as we do that, we are ready to create our first `PSRExtra` element. As we have set default values for both attributes, we could just create an element without defining any attribute.

```
PSRI.create_element!(data, "PSRExtra",
    "extra_name" => "extra",
    "extra_value" => 10.0
    )

PSRI.create_element!(data, "PSRExtra")
```

#### Custom relation

Now that we have a custom collection `PSRExtra`, we can define a relation between it and the collection `PSRBus`, with [`PSRI.add_relation!`](@ref).

```
PSRI.add_relation!(
    data, 
    "PSRBus",    # source  
    "PSRExtra",  # target
    PSRI.RELATION_1_TO_1,  # relation type
    "extra_relation"       # attribute name for relation(saved in source element)
    )
```

After that, we can set a relation between two elements from `PSRBus` and `PSRExtra`.

```
index_extra = PSRI.create_element!(data, "PSRExtra")
index_bus   = PSRI.create_element!(data, "PSRBus")

PSRI.set_related!(
    data, 
    "PSRBus", 
    "PSRExtra", 
    index_bus, 
    index_extra, 
    relation_type = PSRI.RELATION_1_TO_1
    )
```


### Saving/loading changes

Even saving our Study with `PSRI.write_data(data)`, if we loaded it in another time, we wouldn't be able to use our new collections, attributes and relations, because they should've been defined in a PMD file. 

Having said that, you can export a JSON file with the new defined structures for collections with [`PSRI.dump_json_struct`](@ref).

```
cpath = joinpath(temp_path, "custom.json")
PSRI.dump_json_struct(cpath, data)
```

Now, if we re-open our study, we wouldn't have any problem with using the `PSRExtra` collection.


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

After that, we can create a Study with [`PSRI.create_study`](@ref) using a few extra parameters.

```
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