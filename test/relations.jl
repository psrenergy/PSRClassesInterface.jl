
function test_relations1() # tests _get_target_index_from_relation
    mktempdir() do temp_path
        data = PSRI.create_study(PSRI.OpenInterface(); data_path = temp_path)

        index1 = PSRI.create_element!(data, "PSRBus")
        index2 = PSRI.create_element!(data, "PSRBus")

        index3 = PSRI.create_element!(data, "PSRSerie")

        PSRI.set_related!(
            data,
            "PSRSerie",
            "PSRBus",
            1,
            1;
            relation_type = PSRI.PMD.RELATION_FROM,
        )
        PSRI.set_related!(
            data,
            "PSRSerie",
            "PSRBus",
            1,
            2;
            relation_type = PSRI.PMD.RELATION_TO,
        )

        target_index =
            PSRI.OpenStudy._get_target_indices_from_relation(
                data,
                "PSRSerie",
                1,
                "PSRBus",
                "no1",
            )

        @test target_index == [index1]
    end
end

function test_relations2() # tests _get_sources_indices_from_relations
    mktempdir() do temp_path
        data = PSRI.create_study(PSRI.OpenInterface(); data_path = temp_path)

        index1 = PSRI.create_element!(data, "PSRBus")
        index2 = PSRI.create_element!(data, "PSRBus")

        index3 = PSRI.create_element!(data, "PSRSerie")

        PSRI.set_related!(
            data,
            "PSRSerie",
            "PSRBus",
            1,
            1;
            relation_type = PSRI.PMD.RELATION_FROM,
        )
        PSRI.set_related!(
            data,
            "PSRSerie",
            "PSRBus",
            1,
            2;
            relation_type = PSRI.PMD.RELATION_TO,
        )

        source_indices = PSRI.OpenStudy._get_sources_indices_from_relations(
            data,
            "PSRSerie",
            "PSRBus",
            data.raw["PSRBus"][1]["reference_id"],
            "no1",
        )

        @test source_indices[1] == index3
    end
end

function test_relations3() # tests has_relations, get_map
    mktempdir() do temp_path
        data = PSRI.create_study(PSRI.OpenInterface(); data_path = temp_path)

        serie_1 = PSRI.create_element!(data, "PSRSerie")
        serie_2 = PSRI.create_element!(data, "PSRSerie")
        serie_3 = PSRI.create_element!(data, "PSRSerie")

        bus_1 = PSRI.create_element!(data, "PSRBus")
        bus_2 = PSRI.create_element!(data, "PSRBus")
        bus_3 = PSRI.create_element!(data, "PSRBus")

        # Serie Rel Bus
        # 1 --> 1
        # 2 --> 2
        # 1 <-- 2
        # 2 <-- 3
        for (serie, bus) in [(serie_1, bus_1), (serie_2, bus_2)]
            PSRI.set_related!(
                data,
                "PSRSerie",
                "PSRBus",
                serie,
                bus;
                relation_type = PSRI.PMD.RELATION_TO,
            )
        end

        for (serie, bus) in [(serie_1, bus_2), (serie_2, bus_3)]
            PSRI.set_related!(
                data,
                "PSRSerie",
                "PSRBus",
                serie,
                bus;
                relation_type = PSRI.PMD.RELATION_FROM,
            )
        end

        @test PSRI.has_relations(data, "PSRSerie", 1)
        @test PSRI.has_relations(data, "PSRSerie", 2)
        @test !PSRI.has_relations(data, "PSRSerie", 3)
        @test PSRI.has_relations(data, "PSRBus", 1)
        @test PSRI.has_relations(data, "PSRBus", 2)
        @test PSRI.has_relations(data, "PSRBus", 3)

        for (serie, bus) in [(serie_1, bus_1), (serie_2, bus_2)]
            @test PSRI.get_related(
                data,
                "PSRSerie",
                "PSRBus",
                serie;
                relation_type = PSRI.PMD.RELATION_TO,
            ) == bus
        end

        for (serie, bus) in [(serie_1, bus_2), (serie_2, bus_3)]
            @test PSRI.get_related(
                data,
                "PSRSerie",
                "PSRBus",
                serie;
                relation_type = PSRI.PMD.RELATION_FROM,
            ) == bus
        end

        @test PSRI.get_map(
            data,
            "PSRSerie",
            "PSRBus",
            "no1",
        ) == Int32[2, 3, 0]

        @test PSRI.get_map(
            data,
            "PSRSerie",
            "PSRBus",
            "no2",
        ) == Int32[1, 2, 0]
    end
end

function test_relations4()
    @test_throws ErrorException(
        "Relation of type $(PSRI.PMD.RELATION_1_TO_N) is of type vector, not the expected scalar.",
    ) PSRI.OpenStudy.check_relation_scalar(PSRI.PMD.RELATION_1_TO_N)
    @test_throws ErrorException(
        "Relation of type $(PSRI.PMD.RELATION_BACKED) is of type vector, not the expected scalar.",
    ) PSRI.OpenStudy.check_relation_scalar(PSRI.PMD.RELATION_BACKED)
    @test_throws ErrorException(
        "Relation of type $(PSRI.PMD.RELATION_1_TO_1) is of type scalar, not the expected vector.",
    ) PSRI.OpenStudy.check_relation_vector(PSRI.PMD.RELATION_1_TO_1)
end

function test_relations5()
    mktempdir() do temp_path
        data = PSRI.create_study(PSRI.OpenInterface(); data_path = temp_path)

        PSRI.create_element!(data, "PSRReserveGenerationConstraintData")
        PSRI.create_element!(data, "PSRThermalPlant")
        PSRI.create_element!(data, "PSRThermalPlant")
        PSRI.create_element!(data, "PSRThermalPlant")
        PSRI.create_element!(data, "PSRThermalPlant")

        PSRI.set_vector_related!(
            data,
            "PSRReserveGenerationConstraintData",
            "PSRThermalPlant",
            1,
            [1, 2],
        )
        PSRI.set_vector_related!(
            data,
            "PSRReserveGenerationConstraintData",
            "PSRThermalPlant",
            1,
            [3, 4],
            PSRI.PMD.RELATION_BACKED,
        )

        @test PSRI.get_vector_related(
            data,
            "PSRReserveGenerationConstraintData",
            "PSRThermalPlant",
            1,
        ) == [1, 2]
        @test PSRI.get_vector_related(
            data,
            "PSRReserveGenerationConstraintData",
            "PSRThermalPlant",
            1,
            PSRI.PMD.RELATION_BACKED,
        ) == [3, 4]
    end
end

test_relations1()
test_relations2()
test_relations3()
test_relations4()
test_relations5()
