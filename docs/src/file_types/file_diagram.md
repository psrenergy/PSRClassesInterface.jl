# PSRI Files and Structs 101

When creating or loading a study, PSRI uses different files.
This flowchart shows the order in which the files are used.

1. The classes and their attributes are defined in a `PMD` file.
2. Then, a `Model Template` file is used to map the classes to collections in the study.
3. Using the `Model Template` and the `PMD` file, the `Data Struct` file is created.
4. PSRI loads the `Data Struct`, `Relation Mapper` and `Defaults` files into structs and create a study, whose data will be stored in a file named `psrclasses.json`.

```@diagram mermaid
%%{init: {"flowchart": {"htmlLabels": false}} }%%

graph LR
  PMD[("PMD")]
  MTF[("modeltemplates.json")]
  DS["Data Struct"]
  RMF[("relations.json")]
  RM["Relation Mapper"]
  DF[("defaults.json")]
  D["Defaults"]
  P(("PSRI Study"))
  S[("psrclasses.json")]


  PMD --> DS;
  MTF --> DS;
  DS --> P;
  RMF --> RM;
  RM --> P;
  DF --> D;
  D --> P;
  P --> S;
```

## How the structs are used

### Creating an element

When creating an element from a collection, PSRI uses the `Data Struct`, `Relation Mapper` and `Defaults` files to check if:
- The collection is defined in the `Data Struct` file.
- The element has all the attributes defined in the `Data Struct` file.
- In the case where the element does not have all the attributes, the `Defaults` file has the remaining ones.


```@diagram mermaid
%%{init: {"flowchart": {"htmlLabels": false}} }%%

graph TD
  CEL["PSRI.create_element!(data,CollectionName)"]

  Q1{"`Is the collection defined in the Data Struct?`"}
  Q2{"`Does it have any missing attributes?`"}
  Q3{"`Does the Defaults have the remaining attributes?`"}


  E["`Error`"]
  D["`Add to Study`"]

  style E fill:#FF0000
  style D fill:#00FF00

  CEL --> Q1;
  Q1 --"YES"--> Q2;
  Q1 --"NO"--> E;
  Q2 --"YES"--> Q3;
  Q2 --"NO"--> D;
  Q3 --"YES"--> D;
  Q3 --"NO"--> E;
```


### Creating a relation