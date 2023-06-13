# PMD

> 💡 **Tip:** We have a syntax highlighter for .pmd files available on [Visual Studio's Marktetplace](https://marketplace.visualstudio.com/items?itemName=pedromxavier.psr-pmd)

> ⚠ **Warning:** The syntax for PMD files is case-sensitive 


PMD files are used to define classes accross multiple PSR software.
It stores metadata about every attribute and relation.

## Defining a class

To define a class `Custom_Model_v1`, you need to use the following structure.

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
We can specify whether a parameter is dimensioned using the following syntax.
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



