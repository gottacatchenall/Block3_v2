using SpeciesDistributionToolkit
using Clustering
using StatsBase
using CairoMakie
using CSV
using DataFrames
using MultivariateStats
using Dates 

const CLUSTER = "CLUSTER" ∈ keys(ENV) 
const EXTENT = CLUSTER ? (left=-180., bottom=-55.5, right=180., top=83.) : (left = 25, right = 50, bottom = 25, top = 50 )

const CHELSA_DIR = CLUSTER ? "/project/def-gonzalez/mcatchen/ColoradoBumblebees/data/public/chelsa" :  "/home/michael/Papers/ColoradoBumblebees/data/public/chelsa" 

const OUTDIR = CLUSTER ? "/scratch/mcatchen/Block3/" : "./output"

const K_RANGE = 1:15
const PROVIDER = RasterData(CHELSA2, BioClim)
const PROJECTIONS = [Projection(x, GFDL_ESM4) for x in (SSP126, SSP370, SSP585)] 
const TIMESPANS = vcat(Year(1971)=>Year(2010), SpeciesDistributionToolkit.SimpleSDMDatasets.timespans(PROVIDER, PROJECTIONS[1])...)
const LAYER_NAMES = ["BIO$i" for i in 1:19]
const SCENARIOS = [SSP126, SSP245, SSP370]

include("_load_chelsa.jl")
include("_make_climate_uniqueness.jl")
include("_make_climate_velocity.jl")


# A single global layer is 4.5GB as Float32 and 2.71GB as Float16
# Each layer is (20880 x 43200).

# This means the matrix to be PCA'd is (19 x 902016000) entries, which is
# 274 GB as Float16. 

# EarthEnv is consistently 1 pixel taller than chelsa. Idk why, and I don't
# really care, I'm just going to toss the top row. 

# If we drop all open water cells, the matrix to be PCA'd is (19 x 549910231),
# which is 167 GB as Float16.

function convert_layers_to_features_matrix(layers, data_matrix, land_idx)
    for (i,l) in enumerate(layers)
        x = Float32.(vec(l.grid[land_idx]))
        z = StatsBase.fit(ZScoreTransform, x)
        data_matrix[i,:] .= StatsBase.transform(z, x)
    end
    data_matrix
end 

function fill_layer!(empty_layer, vec, land_idx)
    empty_layer.grid .= nothing 
    for (i, idx) in enumerate(land_idx)
        empty_layer.grid[idx] = vec[i]
    end
end

function pca_data_matrix(data_matrix)
    pca = MultivariateStats.fit(PCA, data_matrix)
    MultivariateStats.transform(pca, data_matrix)
end 

function make_pca_matrix(layers, data_matrix, land_idx)  
    pca_mat = pca_data_matrix(convert_layers_to_features_matrix(layers, data_matrix, land_idx))
end

function fill_pca_layers(layers, pca_mat, land_idx)
    pca_layers = [convert(Float32, similar(layers[begin])) for l in 1:size(pca_mat, 1)]
    for (i,pca_layer) in enumerate(pca_layers)
        fill_layer!(pca_layer, pca_mat[i,:], land_idx)
    end 
    pca_layers
end 

function kmeans_and_pca(layers, data_matrix, land_idx, k)
    pca_mat = make_pca_matrix(layers, data_matrix, land_idx)
    pca_layers = fill_pca_layers(layers, pca_mat, land_idx)

    km = Clustering.kmeans(pca_mat, k)
    Λ = collect(eachcol(km.centers))

    pca_layers, Λ
end 

function make_climate_uniqueness(k)
    layers = load_chelsa_baseline()
    @assert allequal([findall(!isnothing, l.grid) for l in layers])

    land_idx = findall(!isnothing, layers[1].grid)
    data_matrix = zeros(Float32, length(layers), length(land_idx))

    pca_layers, Λ = kmeans_and_pca(layers, data_matrix, land_idx, k)

    uniqueness = similar(layers[begin])
    uniqueness.grid .= nothing

    for i in land_idx
        env_vec = [pca_layer.grid[i] for pca_layer in pca_layers]
        _, m = findmin(x-> sum((env_vec .- x).^2), Λ)
        uniqueness.grid[i] = sum( (env_vec .- Λ[m]).^2 )
    end 
    return uniqueness 
end

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

function main()
    mkpath(OUTDIR)

   #= for K in K_RANGE
        u = make_climate_uniqueness(K)
        SpeciesDistributionToolkit.save(joinpath(OUTDIR, "uniqueness_k=$K.tif"), u)
    end

    vel_paths, vel_layers = make_climate_velocity()

    for i in eachindex(vel_paths)
        SpeciesDistributionToolkit.save(joinpath(OUTDIR, vel_paths[i]), vel_layers[i])    
    end =#

    u = make_climate_uniqueness(5)
    SpeciesDistributionToolkit.save(joinpath(OUTDIR, "uniqueness_k=$K.tif"), u)
end


main() 