struct Migration
    version::Int
    path::String
end

Base.isless(m1::Migration, m2::Migration) = m1.version < m2.version
Base.isequal(m1::Migration, m2::Migration) = m1.version == m2.version

function get_sorted_migrations(path_migrations_directory::String)
    migrations_sub_folders = readdir(path_migrations_directory)
    sorted_migrations = Vector{Migration}(undef, 0)
    if isempty(migrations_sub_folders)
        return sorted_migrations
    end

    for migration_sub_folder in migrations_sub_folders
        version = parse_version(migration_sub_folder)
        path = joinpath(path_migrations_directory, migration_sub_folder)
        push!(sorted_migrations, Migration(version, path))
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
function get_last_user_version(path_migrations_directory::String)
    migrations = get_sorted_migrations(path_migrations_directory)
    versions = migration_versions(migrations)
    return versions[end]
end
function migration_versions(migrations::Vector{Migration})
    return map(migration -> migration.version, migrations)
end
function db_is_empty(db::SQLite.DB)
    tbls = SQLite.tables(db)
    return length(tbls) == 0
end

function parse_version(migration::String)
    version = parse(Int, migration)
    return version
end

"""
    create_migration(path_migrations_directory::String, version::Int)

Creates a new migration in the migrations folder with the current date, the correct version and the name
given in this function
"""
function create_migration(path_migrations_directory::String, version::Int)
    existing_migrations = get_sorted_migrations(path_migrations_directory)

    migration_index =
        findfirst(migration -> migration.version == version, existing_migrations)

    if migration_index !== nothing
        error(
            "migration already exists in folder: $(existing_migrations[migration_index].path)",
        )
    end

    old_version = 0
    new_version = 1
    if !isempty(existing_migrations)
        old_version = existing_migrations[end].version
        new_version = old_version + 1
    end

    new_migration = "$(new_version)"
    migration_folder = joinpath(path_migrations_directory, new_migration)

    mkpath(migration_folder)
    #! format: off
    # We turn off formatting here because of this discussion
    # https://github.com/domluna/JuliaFormatter.jl/issues/751
    # I agree that open do blocks with return are slighly misleading.
    open(joinpath(migration_folder, "up.sql"), "w") do file
        println(file, "-- $name")
        println(file, "PRAGMA user_version = $new_version;")
    end
    open(joinpath(migration_folder, "down.sql"), "w") do file
        println(file, "-- $name")
        println(file, "PRAGMA user_version = $old_version;")
    end
    #! format: on
    return migration_folder
end

function _apply_migrations!(
    db::SQLite.DB,
    migrations::Vector{Migration},
    starting_point::Int,
    ending_point::Int,
    direction::Symbol,
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

function apply_migration!(
    db::SQLite.DB, 
    path_migrations_directory::String,
    version::Int, 
    direction::Symbol
)
    migrations = get_sorted_migrations(path_migrations_directory)

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
    direction::Symbol,
)
    if !(direction in [:up, :down])
        error(
            "direction not recognized: $direction. The only directions allowed are :up and :down.",
        )
    end

    @debug(
        "Applying migration $(migration.version) in direction $direction"
    )

    sql_file = joinpath(migration.path, "$(string(direction)).sql")
    return execute_statements(db, sql_file)
end

function apply_migrations!(
    db::SQLite.DB, 
    path_migrations_directory::String,
    from::Int, 
    to::Int, 
    direction::Symbol
)
    if from == to
        error("starting at $from and ending at $to is not a valid migration range.")
    end

    migrations = get_sorted_migrations(path_migrations_directory)
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

function _apply_all_up_migrations(db::SQLite.DB, path_migrations_directory::String)
    migrations = get_sorted_migrations(path_migrations_directory)
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
    test_migrations(path_migrations_directory::String)

fucntion to put in the test suite of the module to verify that the migrations are behaving correctly.
"""
function test_migrations(path_migrations_directory::String)
    migrations = get_sorted_migrations(path_migrations_directory)
    versions = migration_versions(migrations)

    if versions != collect(versions[1]:versions[end])
        error("Migrations are not consecutive.")
    end

    # Go to the first migration and apply every 
    # migration in vector_index.
    db = SQLite.DB()
    expected_user_version = 0
    for migration in migrations
        apply_migration!(db, path_migrations_directory, migration.version, :up)
        expected_user_version += 1
        user_version = get_user_version(db)
        if expected_user_version != user_version
            error(
                "The user version is not correct. Expected $user_version, got $expected_user_version",
            )
        end
    end

    expected_user_version = get_last_user_version(path_migrations_directory)
    for migration in reverse(migrations)
        apply_migration!(db, path_migrations_directory, migration.version, :down)
        expected_user_version -= 1
        user_version = get_user_version(db)
        if expected_user_version != user_version
            error(
                "The user version is not correct. Expected $user_version, got $expected_user_version",
            )
        end
    end

    if !db_is_empty(db)
        error("The database is not empty after applying all migrations up and down.")
    end

    return true
end
