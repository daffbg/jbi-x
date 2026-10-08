"""
Expression tree for evaluating complex predicates and projections.
"""
abstract type Expression end

struct Literal <: Expression
    value::Any
    logical_type::DataTypeTag
end

struct ColumnRef <: Expression
    name::Symbol
end

struct Add <: Expression
    left::Expression
    right::Expression
end

struct GreaterThan <: Expression
    left::Expression
    right::Expression
end

struct Equal <: Expression
    left::Expression
    right::Expression
end

function evaluate(expr::Literal, batch::RecordBatch)
    n = nrows(batch)
    T = typeof(expr.value)
    vals = fill(expr.value, n)
    return ColumnVector(vals, expr.logical_type; validity=trues(n))
end

function evaluate(expr::ColumnRef, batch::RecordBatch)
    idx = findfirst(==(expr.name), batch.names)
    if idx === nothing
        throw(ArgumentError("column :$(expr.name) not found in batch"))
    end
    return batch.columns[idx]
end

function evaluate(expr::Add, batch::RecordBatch)
    left_col = evaluate(expr.left, batch)
    right_col = evaluate(expr.right, batch)
    return add_columns(left_col, right_col)
end

function greater_than_columns(left::ColumnVector{L}, right::ColumnVector{R}) where {L, R}
    n = length(left.values)
    vals = Vector{Bool}(undef, n)
    validity = BitVector(undef, n)
    
    @inbounds for i in 1:n
        if left.validity[i] && right.validity[i]
            vals[i] = left.values[i] > right.values[i]
            validity[i] = true
        else
            vals[i] = false
            validity[i] = false
        end
    end
    
    return ColumnVector(vals, BoolTag; validity=validity)
end

function evaluate(expr::GreaterThan, batch::RecordBatch)
    left_col = evaluate(expr.left, batch)
    right_col = evaluate(expr.right, batch)
    return greater_than_columns(left_col, right_col)
end

function equal_columns(left::ColumnVector{L}, right::ColumnVector{R}) where {L, R}
    n = length(left.values)
    vals = Vector{Bool}(undef, n)
    validity = BitVector(undef, n)
    
    @inbounds for i in 1:n
        if left.validity[i] && right.validity[i]
            vals[i] = left.values[i] == right.values[i]
            validity[i] = true
        else
            vals[i] = false
            validity[i] = false
        end
    end
    
    return ColumnVector(vals, BoolTag; validity=validity)
end

function evaluate(expr::Equal, batch::RecordBatch)
    left_col = evaluate(expr.left, batch)
    right_col = evaluate(expr.right, batch)
    return equal_columns(left_col, right_col)
end
