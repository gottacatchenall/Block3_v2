
function load_chelsa(time, scenario) 
    if time == Pair(Year(1971), Year(2010))
        proj = Projection(scenario, GFDL_ESM4)
        return [SimpleSDMPredictor(PROVIDER; layer=l, EXTENT...) for l in LAYER_NAMES]    
    end 
    return [convert(Float32, SimpleSDMPredictor(PROVIDER; layer=l, EXTENT...)) for l in LAYER_NAMES]    
end

function load_chelsa_baseline()
    [convert(Float32, SimpleSDMPredictor(PROVIDER; layer=l, EXTENT...)) for l in LAYER_NAMES]
end

