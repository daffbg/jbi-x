"""
RecordBatch is the fundamental vectorized execution unit.
"""
struct RecordBatch
    columns::Vector{Any}
    names::Vector{Symbol}
    nrows::Int
end

function RecordBatch(
    columns::Vector,
    names::Vector{Symbol}
)
    isempty(columns) &&
        throw(ArgumentError(
            "RecordBatch must contain at least one column"
        ))

    length(columns) == length(names) ||
        throw(ArgumentError(
            "columns and names must have equal length"
        ))

    row_count = length(first(columns).values)

    for column in columns
        length(column.values) == row_count ||
            throw(ArgumentError(
                "all columns must have identical row counts"
            ))
    end

    return RecordBatch(
        Any[columns...],
        names,
        row_count
    )
end

ncols(batch::RecordBatch) = length(batch.columns)
nrows(batch::RecordBatch) = batch.nrows
