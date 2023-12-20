const MIGRATION_DATE_FORMAT = "yyyy_mm_dd_HHMMSS"
const MIGRATIONS_FOLDER = Ref{String}("")

struct Migration
    date::DateTime
    version::Int
    name::String
    path::String
end

Base.isless(m1::Migration, m2::Migration) = m1.date < m2.date && m1.version < m2.version
Base.isequal(m1::Migration, m2::Migration) = m1.version == m2.version && m1.name == m2.name

function set_migrations_folder(migrations_folder::String)
    if !isdir(migrations_folder)
        error("migrations folder is not a directory: $migrations_folder")
    end
    MIGRATIONS_FOLDER[] = migrations_folder
    return migrations_folder
end

function get_migrations_folder()
    migrations_folder = MIGRATIONS_FOLDER[]
    if !isdir(migrations_folder)
        error("migrations folder is not a directory: $migrations_folder")
    end
    return migrations_folder
end

function get_sorted_migrations()
    migrations_folder = get_migrations_folder()
    migrations_sub_folders = readdir(migrations_folder)
    sorted_migrations = Vector{Migration}(undef, 0)
    if isempty(migrations_sub_folders)
        return sorted_migrations
    end

    for migration_sub_folder in migrations_sub_folders
        name, version, date = parse_name_version_date(migration_sub_folder)
        path = joinpath(migrations_folder, migration_sub_folder)
        push!(sorted_migrations, Migration(date, version, name, path))
    end

    sort!(sorted_migrations)

    if !allunique(sorted_migrations)
        @debug("Migrations are not unique.")
        @debug("printing migrations:")
        for migration in sorted_migrations
            @debug(migration)
        end
        error("Migrations are not unique.")
    end

    return sorted_migrations
end

function get_user_version(db::SQLite.DB)
    df = DBInterface.execute(db, "PRAGMA user_version;") |> DataFrame
    return df[1, 1]
end
function get_last_user_version()
    migrations = get_sorted_migrations()
    versions = migration_versions(migrations)
    return versions[end]
end
function migration_names(migrations::Vector{Migration})
    return map(migration -> migration.name, migrations)
end
function migration_versions(migrations::Vector{Migration})
    return map(migration -> migration.version, migrations)
end
function db_is_empty(db::SQLite.DB)
    tbls = SQLite.tables(db)
    return length(tbls) == 0
end

function parse_name_version_date(migration::String)
    date_string = migration[1:17]
    date = DateTime(date_string, MIGRATION_DATE_FORMAT)
    version_and_name_string = migration[19:end]
    version = parse(Int, split(version_and_name_string, "_")[1][2:end])
    name = join(split(version_and_name_string, "_")[2:end], "_")
    return name, version, date
end

"""
    create_migration(name::String)

Creates a new migration in the migrations folder with the current date, the correct version and the name 
given in this function
"""
function create_migration(name::String)
    migrations_folder = get_migrations_folder()
    existing_migrations = get_sorted_migrations()

    migration_index = findfirst(migration -> migration.name == name, existing_migrations)

    if migration_index !== nothing
        error("migration already exists in folder: $(existing_migrations[migration_index].path)")
    end

    old_version = 0
    new_version = 1
    if !isempty(existing_migrations)
        old_version = existing_migrations[end].version
        new_version = old_version + 1
    end

    name_with_version_and_date = Dates.format(now(), MIGRATION_DATE_FORMAT) * "_v$(new_version)_" * name
    migration_folder = joinpath(migrations_folder, name_with_version_and_date)

    mkpath(migration_folder)
    open(joinpath(migration_folder, "up.sql"), "w") do file
        println(file, "-- $name")
        print(file, "PRAGMA user_version = $new_version")
    end
    open(joinpath(migration_folder, "down.sql"), "w") do file
        println(file, "-- $name")
        print(file, "PRAGMA user_version = $old_version")
    end
    return migration_folder
end

function _apply_migrations!(
    db::SQLite.DB,
    migrations::Vector{Migration},
    starting_point::Int,
    ending_point::Int,
    direction::Symbol
)
    if direction == :down && starting_point < ending_point
        error("when going down, the starting migration must be after the ending migration")
    end
    if direction == :up && starting_point > ending_point
        error("when going up, the starting migration must be before the ending migration")
    end

    range_of_migrations = if direction == :up
        starting_point:ending_point
    else
        starting_point:-1:ending_point
    end

    for migration in migrations[range_of_migrations]
        _apply_migration!(db, migration, direction)
    end

    return db
end

function apply_migration!(db::SQLite.DB, name::String, direction::Symbol)
    migrations = get_sorted_migrations()
    
    migration_index = findfirst(migration -> migration.name == name, migrations)
    
    if migration_index === nothing
        error("migration not found: $name")
    end

    migration = migrations[migration_index]

    _apply_migration!(db, migration, direction)

    return db
end

function apply_migration!(db::SQLite.DB, version::Int, direction::Symbol)
    migrations = get_sorted_migrations()

    migration_index = findfirst(migration -> migration.version == version, migrations)

    if migration_index === nothing
        error("migration not found: $version")
    end

    migration = migrations[migration_index]

    _apply_migration!(db, migration, direction)

    return db
end

function _apply_migration!(
    db::SQLite.DB,
    migration::Migration,
    direction::Symbol
)
    if !(direction in [:up, :down])
        error("direction not recognized: $direction. The only directions allowed are :up and :down.")
    end

    @debug("Applying migration $(migration.name) v$(migration.version) in direction $direction")

    sql_file = joinpath(migration.path, "$(string(direction)).sql")
    return execute_statements(db, sql_file)
end

function apply_migrations!(db::SQLite.DB, from::String, to::String, direction::Symbol)
    if from == to
        error("Starting at $from and ending at $to is not a valid migration range.")
    end

    migrations = get_sorted_migrations()
    names = migration_names(migrations)
    starting_point = findfirst(isequal(from), names)
    ending_point = findfirst(isequal(to), names)

    if starting_point === nothing
        error("starting migration not found: $from")
    end
    if ending_point === nothing
        error("ending migration not found: $to")
    end
    
    _apply_migrations!(db, migrations, starting_point, ending_point, direction)

    return db
end

function apply_migrations!(db::SQLite.DB, from::Int, to::Int, direction::Symbol)
    if from == to
        error("starting at v$from and ending at v$to is not a valid migration range.")
    end

    migrations = get_sorted_migrations()
    versions = migration_versions(migrations)
    starting_point = findfirst(isequal(from), versions)
    ending_point = findfirst(isequal(to), versions)

    if starting_point === nothing
        error("starting migration not found: $from")
    end
    if ending_point === nothing
        error("ending migration not found: $to")
    end
    
    _apply_migrations!(db, migrations, starting_point, ending_point, direction)

    return db
end

function _apply_all_up_migrations(db::SQLite.DB)
    migrations = get_sorted_migrations()
    for migration in migrations
        _apply_migration!(db, migration, :up)
    end
    return db
end

"""
    generate_current_schema_file(db::SQLite.DB, file::String)

generates a .sql file based in sqlite_master that indicates the statements to create a new db from scratch.
"""
function generate_current_schema_file(db::SQLite.DB, file::String)
    if isfile(file)
        rm(file)
    end
    sqlite_master = DBInterface.execute(db, "SELECT * FROM sqlite_master;") |> DataFrame

    open(file, "w") do io
        for row in eachrow(sqlite_master)
            println(io, row.sql, ";\n")
        end
    end
    return file
end

"""
    test_migrations()

fucntion to put in the test suite of the module to verify that the migrations are behaving correctly.
"""
function test_migrations()
    migrations = get_sorted_migrations()
    versions = migration_versions(migrations)

    if versions != collect(versions[1]:versions[end])
        error("Migrations are not consecutive.")
    end

    # Go to the first migration and apply every 
    # migration in order.
    db = SQLite.DB()
    expected_user_version = 0
    for migration in migrations
        apply_migration!(db, migration.name, :up)
        expected_user_version += 1
        user_version = get_user_version(db)
        if expected_user_version != user_version
            error("The user version is not correct. Expected $user_version, got $expected_user_version")
        end
    end

    expected_user_version = get_last_user_version()
    for migration in reverse(migrations)
        apply_migration!(db, migration.name, :down)
        expected_user_version -= 1
        user_version = get_user_version(db)
        if expected_user_version != user_version
            error("The user version is not correct. Expected $user_version, got $expected_user_version")
        end
    end

    if !db_is_empty(db)
        error("The database is not empty after applying all migrations up and down.")
    end

    return true
end