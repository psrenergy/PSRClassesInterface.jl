Base.@kwdef mutable struct Batteries
    names::Vector{String} = String[]
    codes::Vector{Int32} = Int32[]
    charge::Vector{Float64} = Float64[]
    bat2sys::Vector{Int32} = Int32[]
end

import PSRClassesInterface
const PSRI = PSRClassesInterface

PATH_CASE_EXAMPLE_BATTERIES = joinpath(pathof(PSRI) |> dirname |> dirname, "test", "data", "caso1")

data = PSRI.initialize_study(
    PSRI.OpenInterface(),
    data_path = PATH_CASE_EXAMPLE_BATTERIES
)

therm_gen = Batteries()
therm_gen.names = PSRI.get_name(data, "PSRBatteries")
therm_gen.codes = PSRI.get_code(data, "PSRBatteries")
therm_gen.generation_capacities = PSRI.mapped_vector(data, "PSRBatteries", "Existing", Float64)
therm_gen.therm2sys = PSRI.get_map(data, "PSRBatteries", "PSRSystem")
