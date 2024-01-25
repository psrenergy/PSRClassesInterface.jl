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
OpenSQLInterface <: PSRI.AbstractStudyInterface
"""
struct OpenSQLInterface <: PSRI.AbstractStudyInterface end

include("utils.jl")
include("open_sql_database.jl")
include("create.jl")
include("read.jl")
include("update.jl")
include("delete.jl")
include("validate.jl")
include("migrations.jl")
include("psri_study_interface.jl")

end # module OpenSQL
