
function test_relations1() # tests _get_target_index_from_relation
    temp_path = joinpath(tempdir(), "PSRI")
    json_path = joinpath(temp_path, "psrclasses.json")

    mkpath(temp_path)

    data = PSRI.create_study(PSRI.OpenInterface(), data_path = temp_path)

    index1 = PSRI.create_element!(data,"PSRBus")
    index2 = PSRI.create_element!(data,"PSRBus")
    
    index3 = PSRI.create_element!(data,"PSRSerie")

    PSRI.set_related!(data, "PSRSerie", "PSRBus", 1, 1, relation_type = PSRI.RELATION_FROM)
    PSRI.set_related!(data, "PSRSerie", "PSRBus", 1, 2, relation_type = PSRI.RELATION_TO)

    target_index = PSRI._get_target_index_from_relation(data, "PSRSerie", "PSRBus", 1, "no1")

    @test target_index == index1
end


function test_relations2() # tests _get_sources_indices_from_relations
    temp_path = joinpath(tempdir(), "PSRI")
    json_path = joinpath(temp_path, "psrclasses.json")

    mkpath(temp_path)

    data = PSRI.create_study(PSRI.OpenInterface(), data_path = temp_path)

    index1 = PSRI.create_element!(data,"PSRBus")
    index2 = PSRI.create_element!(data,"PSRBus")
    
    index3 = PSRI.create_element!(data,"PSRSerie")

    PSRI.set_related!(data, "PSRSerie", "PSRBus", 1, 1, relation_type = PSRI.RELATION_FROM)
    PSRI.set_related!(data, "PSRSerie", "PSRBus", 1, 2, relation_type = PSRI.RELATION_TO)

    source_indices = PSRI._get_sources_indices_from_relations(data, "PSRSerie", "PSRBus", data.raw["PSRBus"][1]["reference_id"], "no1")

    @test source_indices[1] == index3
end


function test_relations3() # tests hasRelations
    temp_path = joinpath(tempdir(), "PSRI")
    json_path = joinpath(temp_path, "psrclasses.json")

    mkpath(temp_path)

    data = PSRI.create_study(PSRI.OpenInterface(), data_path = temp_path)

    index1 = PSRI.create_element!(data,"PSRBus")
    index2 = PSRI.create_element!(data,"PSRBus")
    
    index3 = PSRI.create_element!(data,"PSRSerie")

    PSRI.set_related!(data, "PSRSerie", "PSRBus", 1, 1, relation_type = PSRI.RELATION_FROM)
    PSRI.set_related!(data, "PSRSerie", "PSRBus", 1, 2, relation_type = PSRI.RELATION_TO)

    @test PSRI.hasRelations(data, "PSRSerie", 1)
    @test PSRI.hasRelations(data, "PSRBus", 1)
end

test_relations1()
test_relations2()
test_relations3()