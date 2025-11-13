

function NEUE_area(sys, sf; bus_file_path::String="../sample_data/nem12/Bus.csv")

    bus_info = CSV.read(bus_file_path, DataFrame)
    
    area_ids = unique(bus_info.id_area)
    area_names = Dict{Int,String}(1=>"QLD", 2=>"NSW", 3=>"VIC", 4=>"TAS", 5=>"SA")

    neue_areas = zeros(length(area_ids))

    for area_id in area_ids
        area_buses = bus_info.id_bus[bus_info.id_area .== area_id]
        bus_names = string.(area_buses)
        if !isempty(area_buses)
            neue_bus = val.(NEUE.(sf, bus_names))
            load_weights = sum(sys.regions.load[area_buses,:], dims=2) ./ sum(sys.regions.load[area_buses,:])
            avg_neue = sum(neue_bus .* load_weights ) / length(neue_bus)
            neue_areas[area_id] = avg_neue
            println("$(area_names[area_id]) - Average NEUE: $(round(avg_neue, digits=2)) ppm")
        end
    end

    return neue_areas
end