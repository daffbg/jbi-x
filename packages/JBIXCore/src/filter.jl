"""
Create a selection vector from a predicate over a column.
Rows that are invalid/null are automatically excluded.
Uses multi-threading for performance.
"""
function filter_column(
    column::ColumnVector{T},
    predicate::Function
) where {T}
    n = length(column.values)
    # BitVector is not thread-safe for writes, so we use Vector{Bool}
    bool_mask = Vector{Bool}(undef, n)
    
    Threads.@threads for i in 1:n
        bool_mask[i] = column.validity[i] && predicate(column.values[i])
    end
    
    return SelectionVector(BitVector(bool_mask))
end
