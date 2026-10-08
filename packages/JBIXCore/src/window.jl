"""
Window functions for analytical queries.
"""

"""
Generates a column with sequential row numbers (1 to N).
"""
function row_number(batch::RecordBatch)
    n = nrows(batch)
    vals = collect(1:n)
    return ColumnVector(vals, Int64Tag; validity=trues(n))
end

"""
Generates a rank for each row based on a specific column's value.
Rows with the same value get the same rank. The next rank skips numbers.
(e.g., 1, 2, 2, 4)
"""
function rank(batch::RecordBatch, col_name::Symbol)
    idx = findfirst(==(col_name), batch.names)
    if idx === nothing
        throw(ArgumentError("column :$col_name not found"))
    end
    
    col = batch.columns[idx]
    n = nrows(batch)
    
    # Sort indices based on the column value (ascending)
    indices = collect(1:n)
    sort!(indices, lt = function(i, j)
        v1, v2 = col.validity[i], col.validity[j]
        if !v1 && !v2 return false end
        if !v1 return true end # Nulls come first
        if !v2 return false end
        return col.values[i] < col.values[j]
    end)
    
    ranks = Vector{Int64}(undef, n)
    current_rank = 1
    
    for (i, row_idx) in enumerate(indices)
        if i > 1
            prev_idx = indices[i-1]
            v1_valid = col.validity[row_idx]
            v2_valid = col.validity[prev_idx]
            
            # Check if values are different to update the rank
            if v1_valid && v2_valid
                if col.values[row_idx] != col.values[prev_idx]
                    current_rank = i
                end
            elseif !v1_valid && !v2_valid
                # Both nulls, rank doesn't change
            else
                # One null, one valid, rank changes
                current_rank = i
            end
        end
        ranks[row_idx] = current_rank
    end
    
    return ColumnVector(ranks, Int64Tag; validity=trues(n))
end
