"""
Vectorized scalar operations on ColumnVectors.
Includes basic arithmetic with proper validity (null) propagation.
"""

# Helper to infer logical type from Julia type
function _infer_logical_type(::Type{Int64})
    return Int64Tag
end
function _infer_logical_type(::Type{Float64})
    return Float64Tag
end
function _infer_logical_type(::Type{T}) where {T}
    throw(ArgumentError("Unsupported type for scalar operation: $T"))
end

"""
Add two ColumnVectors element-wise.
If either operand is null, the result is null.
"""
function add_columns(
    left::ColumnVector{L},
    right::ColumnVector{R}
) where {L, R}
    length(left.values) == length(right.values) ||
        throw(ArgumentError("columns must have the same length for addition"))
    
    T = promote_type(L, R)
    n = length(left.values)
    new_values = Vector{T}(undef, n)
    new_validity = BitVector(undef, n)
    
    @inbounds for i in 1:n
        v1 = left.validity[i]
        v2 = right.validity[i]
        if v1 && v2
            new_values[i] = left.values[i] + right.values[i]
            new_validity[i] = true
        else
            new_values[i] = zero(T)
            new_validity[i] = false
        end
    end
    
    return ColumnVector(new_values, _infer_logical_type(T); validity=new_validity)
end

"""
Multiply a ColumnVector by a scalar constant.
Preserves the original validity (nulls remain nulls).
"""
function multiply_scalar(
    col::ColumnVector{T},
    scalar::Number
) where {T}
    # Broadcast multiplication
    new_values = col.values .* scalar
    
    # Determine new logical type
    R = eltype(new_values)
    return ColumnVector(new_values, _infer_logical_type(R); validity=copy(col.validity))
end
