function test_fixed_duration()
    data = PSRI.initialize_study(
        PSRI.OpenInterface(),
        data_path = joinpath(".", "data", "caso1")
    )

    @test data.duration_mode == PSRI.FIXED_DURATION

    @test PSRI.stage_duration(data, 1) == 744
    @test PSRI.block_duration(data, 1, 1) == 744 * 0.15
    @test PSRI.block_duration(data, 1, 2) == 744 * 0.25
    @test PSRI.block_duration(data, 1, 3) == 744 * 0.60
    @test_throws ErrorException PSRI.block_duration(data, 1, 4)
    @test PSRI.stage_duration(data, 2) == 672
    @test PSRI.block_duration(data, 2, 1) == 672 * 0.15
    @test PSRI.stage_duration(data, 12) == 744
    @test PSRI.block_duration(data, 12, 1) == 744 * 0.15
    @test PSRI.block_duration(data, 12, 2) == 744 * 0.25
    @test_throws ErrorException PSRI.block_duration(data, 12, 4)
    # this just works due to no data limitations
    @test PSRI.block_duration(data, 13, 1) == 744 * 0.15

    @test_throws ErrorException PSRI.block_from_stage_hour(data, 1, 1)
end

test_fixed_duration()

function test_hour_block_map_duration()
    data = PSRI.initialize_study(
        PSRI.OpenInterface(),
        data_path = joinpath(".", "data", "caso2")
    )

    @test data.duration_mode == PSRI.HOUR_BLOCK_MAP

    @test PSRI.stage_duration(data, 1) == 744
    @test PSRI.block_duration(data, 1, 1) == 744
    @test PSRI.stage_duration(data, 2) == 672
    @test PSRI.block_duration(data, 2, 1) == 672
    @test PSRI.stage_duration(data, 12) == 744
    @test PSRI.block_duration(data, 12, 1) == 744
    @test_throws ErrorException PSRI.block_duration(data, 12, 2) == 744
    @test_throws AssertionError PSRI.block_duration(data, 13, 1) == 744

    @test PSRI.block_from_stage_hour(data, 1, 1) == 1 # ?
    @test PSRI.block_from_stage_hour(data, 1, 744) == 1
    @test_throws AssertionError PSRI.block_from_stage_hour(data, 1, 745) == 1
    @test PSRI.block_from_stage_hour(data, 2, 672) == 1 # ?
    @test_throws AssertionError PSRI.block_from_stage_hour(data, 2, 673) == 1 # ?
    @test_throws AssertionError PSRI.block_from_stage_hour(data, 13, 1) == 1 #?
end

test_hour_block_map_duration()

function test_variable_duration()
    data = PSRI.initialize_study(
        PSRI.OpenInterface(),
        data_path = joinpath(".", "data", "caso3")
    )

    @test data.duration_mode == PSRI.VARIABLE_DURATION

    @test PSRI.stage_duration(data, 1) == 2
    @test PSRI.block_duration(data, 1, 1) == 2
    @test PSRI.stage_duration(data, 2) == 3
    @test PSRI.block_duration(data, 2, 1) == 3
    @test PSRI.stage_duration(data, 12) == 13
    @test PSRI.block_duration(data, 12, 1) == 13
    @test_throws ErrorException PSRI.block_duration(data, 12, 2)
    @test_throws AssertionError PSRI.block_duration(data, 13, 1)
    @test_throws ErrorException PSRI.block_from_stage_hour(data, 1, 1)

end

test_variable_duration()