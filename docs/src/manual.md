# Manual

The PSRClassesInterface module provides interfaces to access data structured by PSR to be used in its models. Currently there are two main interfaces: 
<!-- eu não entendi o que são as duas interfaces -->
 * The interface for studies. This interface is designed to read parameters from the files. Some examples of parameters are deficit costs, fuel costs, currency, storage capacity etc.
 * The interface for reading and writing time series data. Time series data in the context of most studies have 4 dimensions (agents, stages, scenarios and blocks). Since studies with multiple agents, scenarios and stages can get quite big, we have designed different formats that are optimized to some objective (human readability, size, fast reading and writing, etc.).

Both interfaces are defined as a set of methods that need to be implemented to make a different file format work. In this manual we will describe the abstract methods and give concrete examples of code to perform the work needed.

When using the PSRClassesInterface package in your codebase we strongly advise you to create a constant `PSRI` to keep the code concise and explicitly declare that a certain function came from PSRClassesInterface. To implement this, simply add the following code snippet at the beginning of your code:
```julia
using PSRClassesInterface
const PSRI = PSRClassesInterface
```

## Initialize Study
```@docs
PSRClassesInterface.AbstractData
PSRClassesInterface.AbstractStudyInterface
PSRClassesInterface.load_study
PSRClassesInterface.description
PSRClassesInterface.max_elements
```

## Study dimensions
<!-- Tem alguma função pra descobrir o StageType do caso? -->
```@docs
PSRClassesInterface.StageType
PSRClassesInterface.total_stages
PSRClassesInterface.total_scenarios
PSRClassesInterface.total_blocks
PSRClassesInterface.total_openings
PSRClassesInterface.total_stages_per_year
```

## Study duration and blocking
<!-- faltam descrições -->
```
PSRClassesInterface.BlockDurationMode
PSRClassesInterface.stage_duration
PSRClassesInterface.block_duration
PSRClassesInterface.block_from_stage_hour
```

## Read Scalar Attributes
<!-- Não ficou clara a diferença entre get_parm e get_parm_1d. get_parm é 0d? -->
<!-- Dar descrições diferentes para os get_parm, explicitando a diferença -->
```@docs
PSRClassesInterface.configuration_parameter
PSRClassesInterface.get_code
PSRClassesInterface.get_name
PSRClassesInterface.get_parm
PSRClassesInterface.get_parm_1d
PSRClassesInterface.get_parms
PSRClassesInterface.get_parms_1d
```

## Read Vector Attributes
### Time controller
<!-- estruturar melhor o go_to_stage e go_to_dimension. idealmente mostrar os valores se alterando ao mudar estágio e bloco ou segmento -->
<!-- talvez na descrição de update_vectors lembrar que não é necessário no PSRI -->
```@docs
PSRClassesInterface.mapped_vector
PSRClassesInterface.go_to_stage
PSRClassesInterface.go_to_dimension
PSRClassesInterface.update_vectors!
```

### Direct access
<!-- Não entendi o nome da seção -->
<!-- Ideia: explicitar que o index do get_vector se refere a agente, e que get_vectors retorna para todos os agentes. Explicitar quais são as dimensões 1d, 2d (estágio? bloco?) -->
<!-- Não entendo tão bem a diferença entre get_parm_1d e get_vector -->
<!-- Não entendi como usa get_series -->
```@docs
PSRClassesInterface.get_vector
PSRClassesInterface.get_vector_1d
PSRClassesInterface.get_vector_2d
PSRClassesInterface.get_vectors
PSRClassesInterface.get_vectors_1d
PSRClassesInterface.get_vectors_2d
PSRClassesInterface.get_nonempty_vector
PSRClassesInterface.get_series
```

## Relations between collections
<!-- Tem uma mensagem alertando que não tem docstring pra RelationType -->
<!-- Podia conceituar melhor como funciona relation, por exemplo explicando que get_map é um vetor de índices, que vec[x] = y significa que a collection 1 no índice x ta ligada a collection 2 no índice y..., e com isso melhorar a descrição de todos os map -->
```@docs
PSRClassesInterface.RelationType
PSRClassesInterface.is_vector_relation
PSRClassesInterface.get_map
PSRClassesInterface.get_vector_map
PSRClassesInterface.get_reverse_map
PSRClassesInterface.get_reverse_vector_map
PSRClassesInterface.get_related
PSRClassesInterface.get_vector_related
```

## Reflection
<!-- Não entendi o nome da seção -->
<!-- PSRI.get_relations(data, col1) podia retornar um dict em que as chaves são as collections associadas à col1, e os valores são os RelationType. Ou um vetor de tuplas. O formato atual tá um pouco estranho, e a descrição no manual ta errada -->
```@docs
PSRClassesInterface.get_attribute_dim1
PSRClassesInterface.get_attribute_dim2
PSRClassesInterface.get_collections
PSRClassesInterface.get_attributes
PSRClassesInterface.Attribute
PSRClassesInterface.get_attribute_struct
PSRClassesInterface.get_data_struct
PSRClassesInterface.get_attributes_indexed_by
PSRClassesInterface.get_relations
PSRClassesInterface.get_attribute_dim
```

## Write Graf files
### Open and Close
```@docs
PSRClassesInterface.AbstractWriter
PSRClassesInterface.open
PSRClassesInterface.close
```

### Write entire file
```@docs
PSRClassesInterface.array_to_file
```

### Write registry
```@docs
PSRClassesInterface.write_registry
```

## Read Graf files
### Open and Close
```@docs
PSRClassesInterface.AbstractReader
PSRClassesInterface.open
PSRClassesInterface.close
```

### Header information
```@docs
PSRClassesInterface.is_hourly
PSRClassesInterface.hour_discretization
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
PSRClassesInterface.agent_names
```

### Read entire file
```@docs
PSRClassesInterface.file_to_array
PSRClassesInterface.file_to_array_and_header
```

### Read registry
```@docs
PSRClassesInterface.current_stage
PSRClassesInterface.current_scenario
PSRClassesInterface.current_block
PSRClassesInterface.goto
PSRClassesInterface.next_registry
```

## File conversion
```@docs
PSRClassesInterface.convert_file
PSRClassesInterface.add_reader!
```

## Reader mapper
```@docs
PSRClassesInterface.ReaderMapper
PSRClassesInterface.add_reader!
PSRClassesInterface.goto
PSRClassesInterface.close
```

## Modification API
```@docs
PSRClassesInterface.create_study
PSRClassesInterface.create_element!
PSRClassesInterface.set_parm!
PSRClassesInterface.set_vector!
PSRClassesInterface.set_series!
PSRClassesInterface.write_data
PSRClassesInterface.set_related!
PSRClassesInterface.set_vector_related!
```