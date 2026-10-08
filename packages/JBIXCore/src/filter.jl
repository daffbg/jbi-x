"""
Create a selection vector from a predicate over a column.
"""
function filter_column(
    column::ColumnVector{T},
    predicate::Function
) where {T}

    mask = BitVector(undef, length(column.values))

    @inbounds for i in eachindex(column.values)
        mask[i] =
            column.validity[i] &&
            predicate(column.values[i])
    end

    return SelectionVector(mask)
end
