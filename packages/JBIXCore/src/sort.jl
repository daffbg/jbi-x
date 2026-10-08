"""
Sort a RecordBatch by a specific column.
Null values are treated as the smallest (appear first in ascending order).
"""
function sort_batch(
    batch::RecordBatch,
    sort_col_name::Symbol;
    rev::Bool=false
)
    idx = findfirst(==(sort_col_name), batch.names)
    if idx === nothing
        throw(ArgumentError("Sort column :$sort_col_name not found"))
    end
    
    col = batch.columns[idx]
    
    # নাল ভ্যালুগুলোকে সামনে রাখতে একটি কাস্টম সর্টিং লজিক
    # আমরা sortperm ব্যবহার করব, কিন্তু ভ্যালিডিটির উপর ভিত্তি করে
    indices = collect(1:nrows(batch))
    
    sort!(indices, lt = function(i, j)
        v1, v2 = col.validity[i], col.validity[j]
        if !v1 && !v2 return false end
        if !v1 return !rev end
        if !v2 return rev end
        return rev ? col.values[i] > col.values[j] : col.values[i] < col.values[j]
    end)
    
    new_cols = Vector{Any}(undef, ncols(batch))
    for c in 1:ncols(batch)
        old_col = batch.columns[c]
        T = eltype(old_col.values)
        new_vals = Vector{T}(undef, nrows(batch))
        new_validity = BitVector(undef, nrows(batch))
        
        for (new_row, old_row) in enumerate(indices)
            new_vals[new_row] = old_col.values[old_row]
            new_validity[new_row] = old_col.validity[old_row]
        end
        
        new_cols[c] = ColumnVector(new_vals, old_col.logical_type; validity=new_validity)
    end
    
    return RecordBatch(new_cols, batch.names)
end
