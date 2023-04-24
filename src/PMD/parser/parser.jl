module Parser

import ..PMD
import Lerche:
    Lerche,
    Lark,
    Transformer,
    @inline_rule,
    @terminal,
    @rule

include("rules.jl")

function parse!(data, path::AbstractString)
    grammar = read(joinpath(@__DIR__, "pmd.lark"), String)

    open(path, "r") do io
        source = read(io, String)
        parser = Lark(
            grammar;
            parser="lalr",
            lexer="standard",
            transformer=PMDT(),
        )

        try
            data["result"] = Lerche.parse(parser, source)
        catch e
            if e isa Lerche.UnexpectedToken
                @error("Unexpected Token '$(e.token)' at '$(path):$(e.line):$(e.column)")
                
                return nothing
            else
                rethrow(e)
            end
        end
    end
    
    return nothing
end

end