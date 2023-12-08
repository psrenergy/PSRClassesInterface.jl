module OpenSQL

using SQLite
using DBInterface
using Tables
# TODO talvez a gente nem precise dos DataFrames, da pra fazer com o Tables mesmo
using DataFrames

const DB = SQLite.DB

"""
SQLInterface
"""
struct SQLInterface end

include("utils.jl")
include("create.jl")
include("read.jl")
include("update.jl")
include("delete.jl")
include("validate.jl")

end # module OpenSQL
