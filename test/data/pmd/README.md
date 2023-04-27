# PMD Parser Tests

This test suite has to cover the following parser capabilities:

- [ ] Blocks
  - [x] `DEFINE_MODEL`
  - [ ] `DEFINE_CLASS`
  - [ ] `MERGE_CLASS`
  - [x] `MERGE_MODEL`
  - [x] `DEFINE_VALIDATION`
  - [x] Empty block
- [x] Attributes
  - [x] Kinds
    - [x] `PARM`
    - [x] `VECTOR|VETOR`
  - [x] Types
    - [x] `INTEGER`
    - [x] `REAL`
    - [x] `DATE`
    - [x] `STRING`
    - [x] `REFERENCE`
  - [x] Extras
    - [x] `DIMENSION`
    - [x] `INDEX`
    - [x] `INTERVAL`
    - [x] `DIM(...)`
  - [ ] Tags
    - [ ] `@id`
    - [ ] `@hourly_dense`
- [x] Names
  - [x] `(MODL:)?`
  - [x] `->|<-`