# PSRClassesInterface Documentation


PSRClassesInterface, or PSRI, is a Julia package that provides an interface to read and write open-source formats for PSR models.
It is comprised of three main modules:
- `OpenStudy`: Reads and writes data in the JSON format
- `OpenBinary`: Reads and writes time series data in the binary format
- `PSRDatabaseSQLite`: Reads and writes data in the SQL format

## Installation

This package is registered so you can simply `add` it using Julia's `Pkg` manager:
```julia
julia> import Pkg

julia> Pkg.add("PSRClassesInterface")
```

## Contributing

Users are encouraged to contributing by opening issues and opening pull requests. If you wish to implement a feature please follow 
the [JuMP Style Guide](https://jump.dev/JuMP.jl/v0.21.10/developers/style/#Style-guide-and-design-principles)
