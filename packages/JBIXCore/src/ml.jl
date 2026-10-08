"""
Basic Machine Learning integration.
"""

struct LinearRegressionModel
    slope::Float64
    intercept::Float64
end

function train_linear_regression(batch::RecordBatch, feature_col::Symbol, target_col::Symbol)
    f_idx = findfirst(==(feature_col), batch.names)
    t_idx = findfirst(==(target_col), batch.names)
    f_col = batch.columns[f_idx]
    t_col = batch.columns[t_idx]
    x_vals, y_vals = Float64[], Float64[]
    for i in 1:nrows(batch)
        if f_col.validity[i] && t_col.validity[i]
            push!(x_vals, Float64(f_col.values[i])); push!(y_vals, Float64(t_col.values[i]))
        end
    end
    n = length(x_vals)
    mean_x, mean_y = sum(x_vals)/n, sum(y_vals)/n
    num, den = 0.0, 0.0
    for i in 1:n; dx=x_vals[i]-mean_x; dy=y_vals[i]-mean_y; num+=dx*dy; den+=dx*dx; end
    m = num/den; c = mean_y - m*mean_x
    return LinearRegressionModel(m, c)
end

predict(model::LinearRegressionModel, x::Number) = model.slope * x + model.intercept

struct LogisticRegressionModel
    weights::Vector{Float64}
    bias::Float64
end

_sigmoid(z::Float64) = 1.0 / (1.0 + exp(-z))

function train_logistic_regression(batch::RecordBatch, feature_cols::Vector{Symbol}, target_col::Symbol; lr::Float64=0.1, epochs::Int=100)
    t_idx = findfirst(==(target_col), batch.names)
    t_col = batch.columns[t_idx]
    f_indices = [findfirst(==(c), batch.names) for c in feature_cols]
    X, y = Vector{Vector{Float64}}(), Float64[]
    for i in 1:nrows(batch)
        if all(idx -> batch.columns[idx].validity[i], f_indices) && t_col.validity[i]
            push!(X, [Float64(batch.columns[idx].values[i]) for idx in f_indices])
            push!(y, Float64(t_col.values[i]))
        end
    end
    n_samples, n_features = length(y), length(feature_cols)
    weights, bias = zeros(n_features), 0.0
    for _ in 1:epochs, i in 1:n_samples
        z = bias + sum(weights[j] * X[i][j] for j in 1:n_features)
        pred = _sigmoid(z); err = pred - y[i]
        for j in 1:n_features; weights[j] -= lr * err * X[i][j]; end
        bias -= lr * err
    end
    return LogisticRegressionModel(weights, bias)
end

predict_proba(model::LogisticRegressionModel, features::Vector{Float64}) = _sigmoid(model.bias + sum(model.weights[j] * features[j] for j in 1:length(features)))

"""
K-Means Clustering Model.
"""
struct KMeansModel
    centroids::Vector{Vector{Float64}}
end

function train_kmeans(batch::RecordBatch, feature_cols::Vector{Symbol}, k::Int; max_iters::Int=100)
    f_indices = [findfirst(==(c), batch.names) for c in feature_cols]
    X = Vector{Vector{Float64}}()
    for i in 1:nrows(batch)
        if all(idx -> batch.columns[idx].validity[i], f_indices)
            push!(X, [Float64(batch.columns[idx].values[i]) for idx in f_indices])
        end
    end
    
    n_samples = length(X)
    if n_samples == 0 return KMeansModel(Vector{Vector{Float64}}()) end
    
    # Initialize centroids randomly
    centroids = [copy(X[rand(1:n_samples)]) for _ in 1:k]
    
    for _ in 1:max_iters
        assignments = zeros(Int, n_samples)
        for i in 1:n_samples
            min_dist, best_c = Inf, 1
            for c in 1:k
                dist = sum((X[i] .- centroids[c]).^2)
                if dist < min_dist; min_dist = dist; best_c = c; end
            end
            assignments[i] = best_c
        end
        
        new_centroids = [zeros(length(feature_cols)) for _ in 1:k]
        counts = zeros(Int, k)
        for i in 1:n_samples
            c = assignments[i]
            new_centroids[c] .+= X[i]
            counts[c] += 1
        end
        
        changed = false
        for c in 1:k
            if counts[c] > 0
                new_centroids[c] ./= counts[c]
                if new_centroids[c] != centroids[c]; changed = true; end
                centroids[c] = new_centroids[c]
            end
        end
        if !changed break end
    end
    return KMeansModel(centroids)
end

function predict_cluster(model::KMeansModel, features::Vector{Float64})
    if isempty(model.centroids) return 0 end
    min_dist, best_c = Inf, 0
    for (c, centroid) in enumerate(model.centroids)
        dist = sum((features .- centroid).^2)
        if dist < min_dist; min_dist = dist; best_c = c; end
    end
    return best_c
end
