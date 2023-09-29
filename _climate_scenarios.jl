abstract type Scenario end 

struct Baseline <: Scenario end 
struct SSP1_26 <: Scenario end 
struct SSP2_45 <: Scenario end 
struct SSP3_70 <: Scenario end 

struct Timespan{Y,Z} end
Base.string(::Type{Timespan{Y,Z}}) where {Y,Z} = string(Y.value)*"_"*string(Z.value)

const TIMESPANS = vcat(Timespan{Year(2000), Year(2015)}, [Timespan{Year(2000+i),Year(2000+i+9)} for i in 20:10:90]...)
const SCENARIOS = [SSP1_26, SSP2_45, SSP3_70]

baseline() = Timespan{Year(2000), Year(2015)}

chelsa_dir() = CHELSA_DIR

dirname(::Type{SSP1_26}) = "ssp126"
dirname(::Type{SSP2_45}) = "ssp245"
dirname(::Type{SSP3_70}) = "ssp370"

function load_layer(path)
    df = CSV.read(path, DataFrame)
    bot,top = Float32.(extrema(df[!,:lat]))
    left, right = extrema(parse.(Float32, names(df)[2:end]))
    return SimpleSDMPredictor(Float32.(Matrix(df)), left=left, right=right, bottom=bot, top=top)
end

function load_layers(paths)
    layers = load_layer.(paths)
    for l in layers
        l.grid .= Float32.(l.grid)
    end
    layers
end

function _chelsa_dir_path(::Type{Timespan{S,E}}, s::Type{SC}) where {S,E,SC<:Scenario}
    startyear, endyear = S.value, E.value
    isbaseline = Timespan{S,E} == baseline()
    dirpath = isbaseline ? "baseline" : dirname(s)
    yrpath = isbaseline ? "" : "$startyear-$endyear"
    joinpath(chelsa_dir(), dirpath, yrpath)
end 

function load_chelsa(::Type{Timespan{S,E}}, s::Type{SC}) where {S,E, SC<:Scenario}
    dir = _chelsa_dir_path(Timespan{S,E}, s) 
    load_layers([joinpath(dir, x) for x in readdir(dir)])
end

function load_chelsa_baseline()
    load_chelsa(baseline(), Baseline)
end

load_chelsa(::Type{SC}, ::Type{Timespan{S,E}}) where {S,E, SC<:Scenario} = load_chelsa(Timespan{S,E}, SC)