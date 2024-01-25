module TestPerformance

using PSRClassesInterface.OpenSQL
using SQLite
using Dates
using Test

const N = 100

function test_performance_naive()
    path_schema = joinpath(@__DIR__, "test_performance.sql")
    db_path = joinpath(@__DIR__, "test_performance.sqlite")
    println("Adding one by one")
    db = OpenSQL.create_empty_db_from_schema(db_path, path_schema; force = true)
    OpenSQL.create_element!(db, "Configuration"; label = "Toy Case")
    time_create_parameters = @timed for i in 1:N
        OpenSQL.create_element!(
            db,
            "Plant";
            label = "Plant $(i)",
            capacity = 1.0 * i,
        )
    end
    println("Time to create $N parameters => $(time_create_parameters.time)")
    time_create_vectors = @timed for i in 1:N
        OpenSQL.create_element!(
            db,
            "Resource";
            label = "Resource $(i)",
            some_value = [1.0, 2.0 + i, 3.0 * i],
        )
    end
    println("Time to create $N vectors => $(time_create_vectors.time)")
    OpenSQL.close!(db)
    return rm(db_path)
end

function test_performance_with_transactions()
    path_schema = joinpath(@__DIR__, "test_performance.sql")
    db_path = joinpath(@__DIR__, "test_performance.sqlite")
    println("Adding one by one within a transaction")
    db = OpenSQL.create_empty_db_from_schema(db_path, path_schema; force = true)
    OpenSQL.create_element!(db, "Configuration"; label = "Toy Case")
    OpenSQL.SQLite.transaction(db.sqlite_db) do
        time_create_parameters = @timed for i in 1:N
            OpenSQL.create_element!(
                db,
                "Plant";
                label = "Plant $(i)",
                capacity = 1.0 * i,
            )
        end
        return println("Time to create $N parameters => $(time_create_parameters.time)")
    end
    OpenSQL.SQLite.transaction(db.sqlite_db) do
        time_create_vectors = @timed for i in 1:N
            OpenSQL.create_element!(
                db,
                "Resource";
                label = "Resource $(i)",
                some_value = [1.0, 2.0 + i, 3.0 * i],
            )
        end
        return println("Time to create $N vectors => $(time_create_vectors.time)")
    end
    OpenSQL.close!(db)
    return rm(db_path)
end

function runtests()
    println("Starting perfromance reports")
    Base.GC.gc()
    Base.GC.gc()
    for name in names(@__MODULE__; all = true)
        if startswith("$name", "test_")
            @testset "$(name)" begin
                getfield(@__MODULE__, name)()
            end
        end
    end
end

TestPerformance.runtests()

end
