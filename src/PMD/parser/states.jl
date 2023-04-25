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
"""
struct PMD_DEF_MODEL <: ParserState
    collection::String
end

"""
    PMD_DEF_CLASS

Indicates that the parser is parsing a _class definition_ block.
"""
struct PMD_DEF_CLASS <: ParserState
    collection::String
end

"""
    PMD_MERGE_CLASS

Indicates that the parser is parsing a _class_ block.
"""
struct PMD_MERGE_CLASS <: ParserState
    collection::String
end