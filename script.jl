using Revise, PSRClassesInterface.PSRDatabaseSQLite, TOML

database_path = raw"D:\git\IARA.jl\test\case_10\guess_bid\study.iara"

model_database_folder = raw"D:\git\IARA.jl\database"

study = PSRDatabaseSQLite.load_db(database_path, joinpath(model_database_folder, "migrations"))

# function _snake_case(string)
#     string = replace(string, r"[\-\.\s]" => "_")
#     words = lowercase.(split(string, r"(?=[A-Z])"))
#     return join([i==1 ? word : "_$word" for (i,word) in enumerate(words)])
# end

# function _get_parameter_tooltip(parameter::String, toml_map::Dict{Any, Any})
#     if haskey(toml_map, parameter)
#         tooltip = toml_map[parameter]["tooltip"]["en"]
#         if !ismissing(tooltip)
#             return ": "*tooltip
#         else 
#             return ""
#         end
#     end
# end

# function _get_collection_toml(collection::PSRDatabaseSQLite.Collection, toml_path::String)
#     toml_map = Dict()

#     toml_reader = TOML.parsefile(toml_path)

#     for attribute in toml_reader["attribute"]
#         toml_map[attribute["id"]] = attribute
#     end

#     for attribute_group in toml_reader["attribute_group"]
#         toml_map[attribute_group["id"]] = attribute_group
#     end

#     return toml_map
# end

# function parameters_docstring(
#     collection::PSRDatabaseSQLite.Collection; 
#     model_database_folder::String = "",
#     ignore_id::Bool = true
#     )

#     toml_map = if model_database_folder != ""
#         toml_path = joinpath(model_database_folder, "ui", _snake_case(collection.id) * ".toml")
#         _get_collection_toml(collection, toml_path)
#     else
#         Dict()
#     end

#     required_arguments = ""
#     optional_arguments = ""

#     for (key, parameter) in collection.scalar_parameters
#         if ignore_id && parameter.id == "id"
#             continue
#         end
#         if parameter.not_null
#             entry = "`$(parameter.id)::$(parameter.type)`"
#             entry *= _get_parameter_tooltip(parameter.id, toml_map)
#             if !ismissing(parameter.default_value)
#                 entry *= " (default: `$(parameter.default_value)`)"
#             end
#             required_arguments *= entry * ". \n"
#         else 
#             entry = "`$(parameter.id)::$(parameter.type)`"
#             entry *= _get_parameter_tooltip(parameter.id, toml_map)
#             if !ismissing(parameter.default_value)
#                 entry *= " (default: `$(parameter.default_value)`)"
#             end
#             optional_arguments *= entry * ". \n"
#         end
#     end

#     for (key, parameter) in collection.scalar_relations
#         if parameter.not_null
#             entry = "`$(parameter.id)::$(parameter.type)`"
#             entry *= _get_parameter_tooltip(parameter.id, toml_map)
#             if !ismissing(parameter.default_value)
#                 entry *= " (default: `$(parameter.default_value)`)"
#             end
#             required_arguments *= entry * ". \n"
#         else 
#             entry = "`$(parameter.id)::$(parameter.type)`"
#             entry *= _get_parameter_tooltip(parameter.id, toml_map)
#             if !ismissing(parameter.default_value)
#                 entry *= " (default: `$(parameter.default_value)`)"
#             end
#             optional_arguments *= entry * ". \n"
#         end
#     end 

#     docstring = """
#     Required arguments:
#     $required_arguments \n

#     Optional arguments:
#     $optional_arguments
#     """
#     return println(docstring)
# end
