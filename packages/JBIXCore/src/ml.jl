"""
Basic Machine Learning integration.
"""

struct LinearRegressionModel
    slope::Float64
    intercept::Float64
end

function train_linear_regression(
    batch::RecordBatch,
    feature_col::Symbol,
    target_col::Symbol
)
    f_idx = findfirst(==(feature_col), batch.names)
    t_idx = findfirst(==(target_col), batch.names)
    
    if f_idx === nothing throw(ArgumentError("Feature column not found")) end
    if t_idx === nothing throw(ArgumentError("Target column not found")) end
    
    f_col = batch.columns[f_idx]
    t_col = batch.columns[t_idx]
    
    x_vals = Float64[]
    y_vals = Float64[]
    
    for i in 1:nrows(batch)
        if f_col.validity[i] && t_col.validity[i]
            push!(x_vals, Float64(f_col.values[i]))
            push!(y_vals, Float64(t_col.values[i]))
        end
    end
    
    n = length(x_vals)
    if n < 2 throw(ArgumentError("Need at least 2 valid data points")) end
    
    mean_x = sum(x_vals) / n
    mean_y = sum(y_vals) / n
    
    numerator = 0.0
    denominator = 0.0
    
    for i in 1:n
        dx = x_vals[i] - mean_x
        dy = y_vals[i] - mean_y
        numerator += dx * dy
        denominator += dx * dx
    end
    
    if denominator == 0.0 throw(ArgumentError("Zero variance in feature")) end
    
    m = numerator / denominator
    c = mean_y - m * mean_x
    
    return LinearRegressionModel(m, c)
end

function predict(model::LinearRegressionModel, x::Number)
    return model.slope * x + model.intercept
end

"""
Logistic Regression Model for binary classification.
Uses Gradient Descent.
"""
struct LogisticRegressionModel
    weights::Vector{Float64}
    bias::Float64
end

# Sigmoid helper
function _sigmoid(z::Float64)
    return 1.0 / (1.0 + exp(-z))
end

function train_logistic_regression(
    batch::RecordBatch,
    feature_cols::Vector{Symbol},
    target_col::Symbol;
    lr::Float64=0.1,
    epochs::Int=100
)
    # Extract target (must be 0 or 1)
    t_idx = findfirst(==(target_col), batch.names)
    t_col = batch.columns[t_idx]
    
    # Extract features
    f_indices = [findfirst(==(c), batch.names) for c in feature_cols]
    
    X = Vector{Vector{Float64}}()
    y = Float64[]
    
    for i in 1:nrows(batch)
        if all(idx -> batch.columns[idx].validity[i], f_indices) && t_col.validity[i]
            push!(X, [Float64(batch.columns[idx].values[i]) for idx in f_indices])
            push!(y, Float64(t_col.values[i]))
        end
    end
    
    n_samples = length(y)
    n_features = length(feature_cols)
    
    weights = zeros(n_features)
    bias = 0.0
    
    for epoch in 1:epochs
        for i in 1:n_samples
            z = bias + sum(weights[j] * X[i][j] for j in 1:n_features)
            pred = _sigmoid(z)
            error = pred - y[i]
            
            for j in 1:n_features
                weights[j] -= lr * error * X[i][j]
            end
            bias -= lr * error
        end
    end
    
    return LogisticRegressionModel(weights, bias)
end

function predict_proba(model::LogisticRegressionModel, features::Vector{Float64})
    z = model.bias + sum(model.weights[j] * features[j] for j in 1:length(features))
    return _sigmoid(z)
end
