"""
Simple Hash Index for fast equality lookups.
Maps a column value to a list of row indices.
"""
struct HashIndex
    index::Dict{Any, Vector{Int}}
    col_name::Symbol
end

function create_index(batch::RecordBatch, col_name::Symbol)
    idx = findfirst(==(col_name), batch.names)
    if idx === nothing
        throw(ArgumentError("column :$col_name not found"))
    end
    
    col = batch.columns[idx]
    index_dict = Dict{Any, Vector{Int}}()
    
    for i in 1:nrows(batch)
        if col.validity[i]
            val = col.values[i]
            if haskey(index_dict, val)
                push!(index_dict[val], i)
            else
                index_dict[val] = [i]
            end
        end
    end
    
    return HashIndex(index_dict, col_name)
end

"""
Filter a batch using a pre-built HashIndex. Much faster than scanning.
"""
function filter_using_index(
    batch::RecordBatch,
    index::HashIndex,
    value
)
    if haskey(index.index, value)
        row_indices = index.index[value]
        selected_n = length(row_indices)
        
        new_cols = Vector{ColumnVector}(undef, ncols(batch))
        for c in 1:ncols(batch)
            old_col = batch.columns[c]
            T = eltype(old_col.values)
            vals = Vector{T}(undef, selected_n)
            validity = BitVector(undef, selected_n)
            
            for (i, r_idx) in enumerate(row_indices)
                vals[i] = old_col.values[r_idx]
                validity[i] = old_col.validity[r_idx]
            end
            
            new_cols[c] = ColumnVector(vals, old_col.logical_type; validity=validity)
        end
        
        return RecordBatch(new_cols, batch.names)
    else
        # No matches, return empty batch
        new_cols = Vector{ColumnVector}(undef, ncols(batch))
        for c in 1:ncols(batch)
            old_col = batch.columns[c]
            T = eltype(old_col.values)
            new_cols[c] = ColumnVector(T[], old_col.logical_type; validity=BitVector([]))
        end
        return RecordBatch(new_cols, batch.names)
    end
end
