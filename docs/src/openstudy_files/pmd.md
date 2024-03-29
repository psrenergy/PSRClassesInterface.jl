# PMD

!!! tip
    We have a syntax highlighter for .pmd files available on [Visual Studio's Marktetplace](https://marketplace.visualstudio.com/items?itemName=pedromxavier.psr-pmd)

!!! warning
    The syntax for PMD files is case-sensitive 


PMD files are used to define models accross multiple PSR software.
It stores metadata about every attribute and relation.


## Good practices

In order to make the PMD file more readable and easier to maintain, we recommend the following good practices:
- Decide whether you want to use PascalCase, snake_case or camelCase and stick to it.
- Always write the name for the `Attributes` and `Collections` in English.
- Do not use special characters other than "_" (underscore) in the names.
- Define understandable names for the `Attributes` and `Collections`, as other users may use your model in the future.

## Defining a model

To define a model `Custom_Model_v1`, you need to use the following structure:

```
DEFINE_MODEL MODL:Custom_Model_v1

	...

END_MODEL
```

## Defining a parameter

A parameter can be either a `VECTOR` or a `PARM`.

### `PARM`

```
DEFINE_MODEL MODL:Custom_Model_v1

	...

	PARM INTEGER Iterations
	PARM REAL Price
	PARM STRING Name
	PARM DATE DateOfEvent

	...

END_MODEL
```

### `VECTOR`

A `VECTOR` parameter can store the same types as a `PARM`.
Additionally can have an indexing parameter attribute.


Let's say that you have a vector `Cost` where each index corresponds to a cost in a specific date.
We can use an auxiliary indexing vector `CostDates` to access the cost value correspondent to a given date (see the [Graf Files and Time Series](../examples/graf_files.md) example).

```
DEFINE_MODEL MODL:Custom_Model_v1

	...

	VECTOR DATE CostDates
	VECTOR REAL Cost INDEX CostDates

	...

END_MODEL
```

### Parameters with dimension

A `VECTOR` or `PARM` parameter can change according to a given Stage, Scenario and/or Block dimension (see the [Graf Files and Time Series](../examples/graf_files.md) example).
We can specify whether a parameter is dimensioned using the following syntax:
```
DEFINE_MODEL MODL:Custom_Model_v1

	...

	PARM INTEGER Iterations DIM(block)

	VECTOR REAL Duration DIM(block) 

	VECTOR DATE CostDates
	VECTOR REAL Cost DIM(block,segment) INDEX CostDates 

	...

END_MODEL
```


### `REFERENCE`

Besides `REAL`, `INTEGER`, `STRING` and `DATE`, there is a fith attribute type labeled `REFERENCE`. 
It can be stored either in a `VECTOR` or a `PARM`.

A `REFERENCE` represents a relation between two models(or collections, when considering a PSRI study).

It has the following structure:

```
DEFINE_MODEL MODL:Custom_Model_v1

	...

	PARM REFERENCE Plant TargetCollection  

	VECTOR REFERENCE Items SecondTargetCollection

	...

END_MODEL
```

In this example, our Custom_Model_v1 model has two relations:
- a relation of `1 to 1` (for being a `PARM` parameter) with elements of collection TargetCollection
- a relation of `1 to N` (for being a `VECTOR` parameter) with elements of collection SecondTargetCollection

The `Plant` and `Items` parameters store the `reference_id` of the corresponding elements from collections TargetCollection and SecondTargetCollection, respectively.

Note that the names TargetCollection and SecondTargetCollection are the name of the collections inside the study, not their name in the PMD file. 
This difference between names is explained in the [Model Template manual](./model_template.md).

Also, we define a `REFERENCE` only in the models which play the role of source. 

There is another way to define relations in a study.
For that, see the [Relation Mapper manual](relation_mapper.md).


