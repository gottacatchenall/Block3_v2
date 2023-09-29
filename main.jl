const CLUSTER = "CLUSTER" ∈ keys(ENV) 
const EXTENT = CLUSTER ? () : (left = 10, bottom = 10, right = 12, top = 12, )

const CHELSA_DIR = CLUSTER ? "/projects/def-gonzalez/mcatchen/ColoradoBumblebees/data/public/chelsa" :  "/home/michael/Papers/ColoradoBumblebees/data/public/chelsa" 
const OUTDIR = CLUSTER ? "/scratch/mcatchen/Block3/" : "./output"

const K_RANGE = 1:15

using SpeciesDistributionToolkit
using Clustering
using StatsBase
using CairoMakie
using CSV
using DataFrames
using MultivariateStats
using Dates 

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