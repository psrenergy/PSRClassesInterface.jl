module OpenSQL

import PSRClassesInterface
const PSRI = PSRClassesInterface

using SQLite
using DBInterface
using Tables
using OrderedCollections
using DataFrames
using Dates

const DB = SQLite.DB

"""
SQLInterface <: PSRI.AbstractStudyInterface
"""
struct SQLInterface <: PSRI.AbstractStudyInterface end

include("utils.jl")
include("collections.jl")
include("create.jl")
include("read.jl")
include("update.jl")
include("delete.jl")
include("validate.jl")
include("migrations.jl")
include("psri_study_interface.jl")

end # module OpenSQL
