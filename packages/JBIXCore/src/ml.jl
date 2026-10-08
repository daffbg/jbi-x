"""
Basic Machine Learning integration.
Implements Simple Linear Regression (y = mx + c) directly on a RecordBatch.
Null values are ignored during training.
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
    
    if f_idx === nothing
        throw(ArgumentError("Feature column :$feature_col not found"))
    end
    if t_idx === nothing
        throw(ArgumentError("Target column :$target_col not found"))
    end
    
    f_col = batch.columns[f_idx]
    t_col = batch.columns[t_idx]
    
    # Collect valid pairs
    x_vals = Float64[]
    y_vals = Float64[]
    
    for i in 1:nrows(batch)
        if f_col.validity[i] && t_col.validity[i]
            push!(x_vals, Float64(f_col.values[i]))
            push!(y_vals, Float64(t_col.values[i]))
        end
    end
    
    n = length(x_vals)
    if n < 2
        throw(ArgumentError("Need at least 2 valid data points for linear regression"))
    end
    
    # Calculate means
    mean_x = sum(x_vals) / n
    mean_y = sum(y_vals) / n
    
    # Calculate slope (m) and intercept (c)
    # m = Σ((x - mean_x) * (y - mean_y)) / Σ((x - mean_x)^2)
    numerator = 0.0
    denominator = 0.0
    
    for i in 1:n
        dx = x_vals[i] - mean_x
        dy = y_vals[i] - mean_y
        numerator += dx * dy
        denominator += dx * dx
    end
    
    if denominator == 0.0
        throw(ArgumentError("Cannot fit line, feature column has zero variance"))
    end
    
    m = numerator / denominator
    c = mean_y - m * mean_x
    
    return LinearRegressionModel(m, c)
end

# Prediction function
function predict(model::LinearRegressionModel, x::Number)
    return model.slope * x + model.intercept
end
