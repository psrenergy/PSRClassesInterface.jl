struct DatabaseException <: Exception
    msg::String
end

psr_database_sqlite_error(msg::String) = throw(DatabaseException(msg))
Base.showerror(io::IO, e::DatabaseException) = print(io, e.msg)