"""
Typed column vector used by the JBI-X execution kernel.
"""
struct ColumnVector{T}
    values::Vector{T}
    validity::BitVector
    logical_type::DataTypeTag
end

function ColumnVector(
    values::Vector{T},
    logical_type::DataTypeTag;
    validity::BitVector=trues(length(values))
) where {T}

    length(values) == length(validity) ||
        throw(ArgumentError(
            "values and validity lengths must match"
        ))

    return ColumnVector{T}(
        values,
        validity,
        logical_type
    )
end
