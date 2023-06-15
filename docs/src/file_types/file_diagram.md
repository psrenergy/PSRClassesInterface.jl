# PSRI File flowchart

```@diagram mermaid
graph LR
  PMD["PMD"]
  MT["Model Template"]
  DS["Data Struct"]
  RM["Relation Mapper"]
  D["Defaults"]
  P["psrclasses.json"]
  
  PMD --> MT;
  MT --> DS;
  DS --> P;
  RM --> P;
  D --> P;
```