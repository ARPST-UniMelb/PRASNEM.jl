function createStorages(storages_input_file, units, regions_selected, start_dt, end_dt; 
    scenarios=scenarios, gentech_excluded=gentech_excluded, alias_excluded=alias_excluded)

    return Storages{units.N,units.L,units.T,units.P,units.E}(...), stors_region_attribution
end

# Example
# stors = Storages{N,5,Minute,MW,MWh}(
#    (empty_str for _ in 1:2)..., # Name and categories
#    (empty_int(N) for _ in 1:3)..., # charge, discharge, and energy capacity
#    (empty_float(N) for _ in 1:3)..., # charge, discharge, carryover efficiency
#    (empty_float(N) for _ in 1:2)...) # lambda and mu (failure and repair probability)