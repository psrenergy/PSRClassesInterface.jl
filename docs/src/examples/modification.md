# Modifying a Study

In this example we will be showing how to modify your study in runtime, adding/deleting elements, setting relations, ...

## Creating a Study

You can modify an existing study or a new one with the following functions:
- [`PSRClassesInterface.create_study`](@ref) &rarr; to create a new study;
- [`PSRClassesInterface.load_study`](@ref) &rarr; to load an old study.

In this example, we will be working with a new empty study.

```@example modification
using PSRClassesInterface
const PSRI = PSRClassesInterface

temp_path = joinpath(tempdir(), "PSRI")

data = PSRI.create_study(PSRI.OpenInterface(); data_path = temp_path)
```

## Adding new elements

You can only add elements from collections that are available for your study. Here we will be using our default study configuration, but in another example you can learn how to work with a custom study. You can check which collections are available with `PSRI.get_collections(data)`.

Every study already comes with a `PSRStudy` element. So now we can add some elements with the function [`PSRClassesInterface.create_element!`](@ref), that returns the element's index in the collection.

```
bus_1_index   = PSRI.create_element!(data, "PSRBus")
serie_1_index = PSRI.create_element!(data, "PSRSerie")
```

When not specified, the attributes for the element are filled with their default values. But you can also set them manually. If you need, it is possible to see the attributes for a collection with `PSRI.get_attributes(data, COLLECTION)`.

```@example modification
bus_2_index = PSRI.create_element!(
    data, "PSRBus", 
    "name" => "bus_name", 
    "Kv" => 1.5, 
    "code"=> Int32(98), 
    "icca" => Int32(5), 
    "AVId" => "bus_id"
    )

# You don't need to set all attributes

bus_3_index = PSRI.create_element!(
    data, "PSRBus", 
    "code"=> Int32(10), 
    )
```

## Setting relations

Some collections in a Study can have relations between some of their elements. 

A Relation has a `source` and a `target` element. We can check the available relations for an element when it is a `source` with `PSRI.get_relations(COLLECTION)`. Just as for custom collections, you can learn how to customize relations in another tutorial.

```@example modification
PSRI.set_related!(
    data, 
    "PSRSerie", 
    "PSRBus", 
    serie_1_index, 
    bus_1_index , 
    relation_type = PSRI.PMD.RELATION_FROM
    )

PSRI.set_related!(
    data, 
    "PSRSerie", 
    "PSRBus", 
    serie_1_index, 
    bus_2_index , 
    relation_type = PSRI.PMD.RELATION_TO
    )
```

## Deleting elements

We can delete an element using [`PSRClassesInterface.delete_element!`](@ref). 

```@example modification
PSRI.delete_element!(data, "PSRBus", bus_3_index)
```

However, if you try to delete an element that has a relation with any other, you will receive an error message. 

```@example modification
PSRI.delete_element!(data, "PSRSerie", serie_1_index)
```
> <span style="color:red">ERROR:</span> Element PSRSerie cannot be deleted because it has relations with other elements


So first, you have to check the relations that the element has and delete them.

To see the relations set to an element, use [`PSRClassesInterface.relations_summary`](@ref), which returns a list with the `target` element, with its index, pointing to the `source` element, also with its index.

```@example modification
PSRI.relations_summary(data, "PSRBus", bus_1_index)
```

```@example modification
PSRI.relations_summary(data, "PSRBus", bus_2_index)
```

```@example modification
PSRI.relations_summary(data, "PSRSerie", serie_1_index)
```

Now we know that we have to delete two relations to be able to delete the `PSRSerie` element. For that, we use [`PSRClassesInterface.delete_relation!`](@ref).

```@example modification
PSRI.delete_relation!(data, "PSRSerie", "PSRBus", serie_1_index, bus_1_index)
PSRI.delete_relation!(data, "PSRSerie", "PSRBus", serie_1_index, bus_2_index)
```

After that, we can easily delete our `PSRSerie` element.

```@example modification
PSRI.delete_element!(data, "PSRSerie", serie_1_index)
```

After that we can save our study to a JSON file, which can later be used to load the study again.
```@example modification
PSRI.write_data(data)
```