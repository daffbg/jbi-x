"""
Apply a SelectionVector to a RecordBatch, materializing a new
RecordBatch containing only the selected (active) rows.
"""
function apply_selection(
    batch::RecordBatch,
    selection::SelectionVector
)
    nrows(batch) == length(selection.mask) ||
        throw(ArgumentError("batch and selection must have the same number of rows"))

    selected_n = selected_count(selection)
    new_cols = Vector{Any}(undef, length(batch.columns))
    
    @inbounds for (i, col) in enumerate(batch.columns)
        T = eltype(col.values)
        new_values = Vector{T}(undef, selected_n)
        new_validity = BitVector(undef, selected_n)
        
        idx = 1
        for row in 1:nrows(batch)
            if selection.mask[row]
                new_values[idx] = col.values[row]
                new_validity[idx] = col.validity[row]
                idx += 1
            end
        end
        
        # এখানে {T} বাদ দেওয়া হয়েছে যাতে আউটার কনস্ট্রাক্টর কল হয়
        new_cols[i] = ColumnVector(new_values, col.logical_type; validity=new_validity)
    end
    
    return RecordBatch(new_cols, batch.names)
end
