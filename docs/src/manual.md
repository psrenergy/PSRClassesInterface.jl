# Manual

The PSRClassesInterface module provides interfaces to access data structured by PSR to be used in its models. Currently there are two main interfaces. 
 * The interface for studies. This interface is designed to read parameters from the files, some examples are deficit costs, fuel costs, currency, storage capacity etc.
 * The interface for reading and writing time series data. Time series data in the context of most studies have 4 dimensions (agents, stages, scenarios and blocks). Since studies of renewables with multiple agents, scenarios and stages can get quite big, we have designed different formats that are optimized to some objective (human readability, size, fast reading and writing, etc.).

Both interfaces are defined as a set of methods that need to be implemented to make a different file format work. In this manual we will describe the abstract methods and give concrete examples of code to perform the work needed.

## Abstract study interface

```@docs
PSRClassesInterface.AbstractStudyInterface
PSRClassesInterface.initialize_study
PSRClassesInterface.get_vector
PSRClassesInterface.max_elements
PSRClassesInterface.get_map
PSRClassesInterface.get_parms
PSRClassesInterface.get_code
PSRClassesInterface.get_name
PSRClassesInterface.mapped_vector
PSRClassesInterface.go_to_stage
PSRClassesInterface.go_to_dimension
PSRClassesInterface.update_vectors!
PSRClassesInterface.description
PSRClassesInterface.total_stages
PSRClassesInterface.total_scenarios
PSRClassesInterface.total_blocks
PSRClassesInterface.total_openings
PSRClassesInterface.total_stages_per_year
PSRClassesInterface.get_complex_map
PSRClassesInterface.stage_duration
PSRClassesInterface.stage_block_duration
PSRClassesInterface.get_nonempty_vector
```

## Abstract reader and writer interface

```@docs
PSRClassesInterface.AbstractReader
PSRClassesInterface.AbstractWriter
PSRClassesInterface.AbstractReaderMapper
PSRClassesInterface.file_to_array
PSRClassesInterface.file_to_array_and_header
PSRClassesInterface.read
PSRClassesInterface.write
PSRClassesInterface.is_hourly
PSRClassesInterface.max_stages
PSRClassesInterface.max_scenarios
PSRClassesInterface.max_blocks
PSRClassesInterface.max_blocks_current
PSRClassesInterface.max_blocks_stage
PSRClassesInterface.max_agents
PSRClassesInterface.stage_type
PSRClassesInterface.initial_stage
PSRClassesInterface.initial_year
PSRClassesInterface.data_unit
PSRClassesInterface.current_stage
PSRClassesInterface.current_scenario
PSRClassesInterface.current_block
PSRClassesInterface.agent_names
PSRClassesInterface.goto
PSRClassesInterface.next_registry
PSRClassesInterface.close
PSRClassesInterface.convert_file
PSRClassesInterface.convert
PSRClassesInterface.add_reader!
PSRClassesInterface.write_registry
PSRClassesInterface.array_to_file
```