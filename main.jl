using SpeciesDistributionToolkit
using Clustering
using StatsBase
using CairoMakie
using CSV
using DataFrames
using MultivariateStats
using Dates 

const CLUSTER = "CLUSTER" ∈ keys(ENV) 
const EXTENT = CLUSTER ? () : (left = 0, bottom = 0, right = 15, top = 15, )

const CHELSA_DIR = CLUSTER ? "/project/def-gonzalez/mcatchen/ColoradoBumblebees/data/public/chelsa" :  "/home/michael/Papers/ColoradoBumblebees/data/public/chelsa" 

const OUTDIR = CLUSTER ? "/scratch/mcatchen/Block3/" : "./output"

const K_RANGE = 1:15
const PROVIDER = RasterData(CHELSA2, BioClim)
const PROJECTIONS = [Projection(x, GFDL_ESM4) for x in (SSP126, SSP370, SSP585)] 
const TIMESPANS = vcat(Year(1971)=>Year(2010), SpeciesDistributionToolkit.SimpleSDMDatasets.timespans(PROVIDER, PROJECTIONS[1])...)
const LAYER_NAMES = ["BIO$i" for i in 1:19]
const SCENARIOS = [SSP126, SSP245, SSP370]

include("_climate_scenarios.jl")
include("_make_climate_uniqueness.jl")
include("_make_climate_velocity.jl")

function main()
    mkpath(OUTDIR)

    for K in K_RANGE
        u = make_climate_uniqueness(K)
        SpeciesDistributionToolkit.save(joinpath(OUTDIR, "uniqueness_k=$K.tif"), u)
    end

    vel_paths, vel_layers = make_climate_velocity()

    for i in eachindex(vel_paths)
        SpeciesDistributionToolkit.save(joinpath(OUTDIR, vel_paths[i]), vel_layers[i])    
    end
end


main() 