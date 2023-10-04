"""
    ParserState

Subtypes of `ParserState` represent the states of the PMD parser.
"""
abstract type ParserState end

"""
    PMD_IDLE

Indicates that the parser is in _idle_ state, that is, it is at the beginning of
the file or has just finished consuming a top-level block.
"""
struct PMD_IDLE <: ParserState end

"""
    PMD_DEF_MODEL

Indicates that the parser is parsing a _model definition_ block.
Identified by `DEFINE_MODEL XXX` for a model named XXX.

Example

```
DEFINE_MODEL MODL:SDDP_V10.2_Bateria
	PARM REAL 	Einic
END_MODEL
```

The model name is `MODL:SDDP_V10.2_Bateria`.
The model can be attached to a class to define its attributes.
"""
struct PMD_DEF_MODEL <: ParserState
    collection::Union{String, Nothing}
end

"""
    PMD_DEF_CLASS

Indicates that the parser is parsing a _class definition_ block.

Example

```
DEFINE_CLASS Contract_Forward
  PARM INTEGER SpreadUnit
END_CLASS
```

The class name is `Contract_Forward`.
This class definition does not require a model attached.
"""
struct PMD_DEF_CLASS <: ParserState
    collection::Union{String, Nothing}
end

"""
    PMD_MERGE_CLASS

Indicates that the parser is parsing a _class_ block.
"""
struct PMD_MERGE_CLASS <: ParserState
    collection::Union{String, Nothing}
end

"""
    PMD_DEF_VALIDATION

Validation block `DEFINE_VALIDATION`.
This block is skipped.
"""
struct PMD_DEF_VALIDATION <: ParserState end

"""
    PMD_DEF_MATH

Math block `DEFINE_MATH`.
This is skipped.
"""
struct PMD_DEF_MATH <: ParserState end
