
function load_chelsa(time, scenario) 
    if time == Pair(Year(1971), Year(2010))
        return load_chelsa_baseline()   
    end 
    layers = [convert(Float16, SimpleSDMPredictor(PROVIDER. Projection(scenario, GFDL_ESM4); layer=l, timespan=time, EXTENT...)) for l in LAYER_NAMES]    
    remove_water(layers)
end

function load_chelsa_baseline()
    layers = [convert(Float16, SimpleSDMPredictor(PROVIDER; layer=l, EXTENT...)) for l in LAYER_NAMES]
    remove_water(layers)
end

function remove_water(layers)
    lc = load_water(layers[begin])
    water_idx = findall(!iszero, lc.grid)
    for l in layers
        l.grid[water_idx] .= nothing
    end
    return layers
end

function load_water(chelsa_template)
    layer = SimpleSDMPredictor(RasterData(EarthEnv, LandCover); layer = "Open Water", EXTENT...)

    lc = nothing
    if CLUSTER 
        # make water layer one layer taller filled with true
        sz = size(layer.grid) .+ (1,0)
        m = zeros(Float16, sz)

        m[begin:end-1, :] .= layer.grid
        m[end, :] .= 100.
        lc = SimpleSDMPredictor(m, SpeciesDistributionToolkit.boundingbox(chelsa_template)...) 
    else
        # Hacky but doesn't matter
        mat = zeros(Float16, size(chelsa_template))
        mat[1:end-1, 1:end-1] .= layer.grid
        lc = SimpleSDMPredictor(mat, SpeciesDistributionToolkit.boundingbox(chelsa_template)...)  
    end
    @info size(chelsa_template), size(lc)
    @assert size(chelsa_template) == size(lc)
    return lc
end
