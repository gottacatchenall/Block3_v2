function make_climate_velocity()
    futures = TIMESPANS[2:end]

    baseline_layers = load_chelsa_baseline()
    baseline_mat = convert_layers_to_features_matrix(baseline_layers)

    paths, velocity_layers = [], []

    for scen in SCENARIOS
        for time in futures
            this_time_layers = load_chelsa(time, scen)
            this_time_mat = convert_layers_to_features_matrix(this_time_layers)

            abs_diff = map(sum, eachcol(abs.(this_time_mat .- baseline_mat)))

            vel_layer = similar(baseline_layers[begin])
            fill_layer!(vel_layer, abs_diff)
            push!(velocity_layers, vel_layer)
            push!(paths, "velocity_$(string(scen))_$(_time_to_string(time)).tif")
        end 
    end
    paths, velocity_layers
end

_time_to_string(years) = string(years[1].value)*"_"*string(years[2].value)