function _get_position(graf, t::Integer, s::Integer, b::Integer)
    if PSRI.is_hourly(graf)
        # hours in weekly = 52 * 168 = 8736
        # hours in monthly = 8760
        pos = 4 * (
            graf.blocks_until_stage[t] * graf.agents_total * graf.scenario_total +
            (s - 1) * graf.agents_total * graf.blocks_per_stage[t] +
            (b - 1) * graf.agents_total)
        return pos + graf.hs
    else
        pos = 4 * (
            (t - 1) * graf.agents_total * graf.block_total * graf.scenario_total +
            (s - 1) * graf.agents_total * graf.block_total +
            (b - 1) * graf.agents_total)
        return pos + graf.hs
    end
end