module TestForeignKeys

using PSRClassesInterface.PSRDatabaseSQLite
using SQLite
using Test

function test_foreign_keys()
    migrations_dir = joinpath(@__DIR__, "migrations")
    path_schema = joinpath(migrations_dir, "1", "up.sql")
    db_path = joinpath(@__DIR__, "test.sqlite")
    db = PSRDatabaseSQLite.create_empty_db_from_schema(
        db_path,
        path_schema,
        force=true,
    )

    PSRDatabaseSQLite.create_element!(
        db,
        "Process";
        label="Sugar Mill",
        capex=52000.0,
        opex=0.0,
        base_capacity=100.0,
    )

    PSRDatabaseSQLite.create_element!(
        db,
        "Product";
        label="Sugar",
        sell_price=5.0,
        unit="kg"
    )

    PSRDatabaseSQLite.create_element!(
        db,
        "Product";
        label="Sugarcane",
        unit="ton",
        initial_availability=100.0
    )

    PSRDatabaseSQLite.create_element!(
        db,
        "Input";
        id=1,
        process_id=1,
        product_id=1,
        factor=1.0,
    )

    PSRDatabaseSQLite.create_element!(
        db,
        "Output";
        id=1,
        process_id=1,
        product_id=2,
        factor=0.75,
    )

    PSRDatabaseSQLite.apply_migrations!(
        db.sqlite_db,
        migrations_dir,
        1,
        3,
        :up,
    )

    PSRDatabaseSQLite.close!(db)

    db = PSRDatabaseSQLite.load_db(db_path)

    process_input = PSRDatabaseSQLite.read_vector_relation(db, "Process", "Product", "Sugar Mill", "input")
    process_output = PSRDatabaseSQLite.read_vector_relation(db, "Process", "Product", "Sugar Mill", "output")

    PSRDatabaseSQLite.close!(db)
    rm((joinpath(@__DIR__, "_backups")), recursive = true)
    rm(db_path, force = true)

end

function runtests()
    for name in names(@__MODULE__; all = true)
        if startswith("$name", "test_")
            @testset "$(name)" begin
                getfield(@__MODULE__, name)()
            end
        end
    end
end

TestForeignKeys.runtests()


end