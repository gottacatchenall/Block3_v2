function convert_layers_to_features_matrix(layers)
    I = findall(!isnothing, layers[1].grid)
    data_matrix = zeros(Float32, length(layers), length(I))
    for (i,l) in enumerate(layers)
        x = Float32.(vec(l.grid[I]))
        z = StatsBase.fit(ZScoreTransform, x)
        data_matrix[i,:] .= StatsBase.transform(z, x)
    end
    data_matrix
end 

function fill_layer!(empty_layer, vec)
    m = reshape(vec, size(empty_layer))
    for j in eachindex(empty_layer.grid)
        empty_layer.grid[j] = m[j]
    end
end

function pca_data_matrix(data_matrix)
    pca = MultivariateStats.fit(PCA, data_matrix)
    MultivariateStats.transform(pca, data_matrix)
end 

function make_pca_layers(layers)  
    pca_mat = pca_data_matrix(convert_layers_to_features_matrix(layers))
    pca_layers = [convert(Float32, similar(layers[begin])) for l in 1:size(pca_mat, 1)]
    for (i,pca_layer) in enumerate(pca_layers)
        fill_layer!(pca_layer, pca_mat[i,:])
    end 
    pca_layers, pca_mat
end

function make_climate_uniqueness(k)
    layers = load_chelsa_baseline()
    @assert allequal([findall(!isnothing, l.grid) for l in layers])

    pca_layers, pca_data_matrix = make_pca_layers(layers)
    uniqueness = similar(pca_layers[begin])
    km = Clustering.kmeans(pca_data_matrix, k)
    Λ = collect(eachcol(km.centers))

    for i in eachindex(pca_layers[begin].grid)
        env_vec = [pca_layer.grid[i] for pca_layer in pca_layers]
        _, m = findmin(x-> sum((env_vec .- x).^2), Λ)
        uniqueness.grid[i] = sum( (env_vec .- Λ[m]).^2 )
    end 
    return uniqueness 
end

