
function test_relations1() # tests _get_target_index_from_relation
    mktempdir() do temp_path
        data = PSRI.create_study(PSRI.OpenInterface(), data_path = temp_path)

        index1 = PSRI.create_element!(data,"PSRBus")
        index2 = PSRI.create_element!(data,"PSRBus")
        
        index3 = PSRI.create_element!(data,"PSRSerie")

        PSRI.set_related!(data, "PSRSerie", "PSRBus", 1, 1, relation_type = PSRI.RELATION_FROM)
        PSRI.set_related!(data, "PSRSerie", "PSRBus", 1, 2, relation_type = PSRI.RELATION_TO)

        target_index = PSRI._get_target_index_from_relation(data, "PSRSerie", 1, "no1")

        @test target_index == [index1]
    end
end


function test_relations2() # tests _get_sources_indices_from_relations
    mktempdir() do temp_path

        data = PSRI.create_study(PSRI.OpenInterface(), data_path = temp_path)

        index1 = PSRI.create_element!(data,"PSRBus")
        index2 = PSRI.create_element!(data,"PSRBus")
        
        index3 = PSRI.create_element!(data,"PSRSerie")

        PSRI.set_related!(data, "PSRSerie", "PSRBus", 1, 1, relation_type = PSRI.RELATION_FROM)
        PSRI.set_related!(data, "PSRSerie", "PSRBus", 1, 2, relation_type = PSRI.RELATION_TO)

        source_indices = PSRI._get_sources_indices_from_relations(data, "PSRSerie", "PSRBus", data.raw["PSRBus"][1]["reference_id"], "no1")

        @test source_indices[1] == index3
    end
end


function test_relations3() # tests has_relations
    mktempdir() do temp_path

        data = PSRI.create_study(PSRI.OpenInterface(), data_path = temp_path)

        index1 = PSRI.create_element!(data,"PSRBus")
        index2 = PSRI.create_element!(data,"PSRBus")
        
        index3 = PSRI.create_element!(data,"PSRSerie")

        PSRI.set_related!(data, "PSRSerie", "PSRBus", index3, index1, relation_type = PSRI.RELATION_FROM)
        PSRI.set_related!(data, "PSRSerie", "PSRBus", index3, index2, relation_type = PSRI.RELATION_TO)

        @test PSRI.has_relations(data, "PSRSerie", 1)
        @test PSRI.has_relations(data, "PSRBus", 1)
    end
end

function test_relations4() # tests has_relations
    mktempdir() do temp_path

        data = PSRI.create_study(PSRI.OpenInterface(), data_path = temp_path)

        PSRI.add_relation!(data,"PSRBus", "PSRBus", PSRI.RELATION_1_TO_1, "test")
        PSRI.add_relation!(data,"PSRSystem", "PSRBus", PSRI.RELATION_1_TO_1, "test")

        @test haskey(PSRI._RELATIONS["PSRBus"], ("PSRBus",PSRI.RELATION_1_TO_1))
        @test haskey(PSRI._RELATIONS["PSRSystem"], ("PSRBus",PSRI.RELATION_1_TO_1))
    end

end

test_relations1()
test_relations2()
test_relations3()
test_relations4()