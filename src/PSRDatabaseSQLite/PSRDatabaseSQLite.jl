module PSRDatabaseSQLite

import PSRClassesInterface
const PSRI = PSRClassesInterface

using SQLite
using DBInterface
using Tables
using OrderedCollections
using DataFrames
using Dates
using Random

"""
PSRDatabaseSQLiteInterface <: PSRI.AbstractStudyInterface
"""
struct PSRDatabaseSQLiteInterface <: PSRI.AbstractStudyInterface end

include("exceptions.jl")
include("utils.jl")
include("attribute.jl")
include("collection.jl")
include("time_controller.jl")
include("database_sqlite.jl")
include("create.jl")
include("read.jl")
include("update.jl")
include("delete.jl")
include("validate.jl")
include("migrations.jl")
include("psri_study_interface.jl")

end # module DatabaseSQLite
