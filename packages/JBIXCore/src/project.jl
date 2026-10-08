"""
Project specific columns from a RecordBatch by name.
Returns a new RecordBatch containing only the requested columns
in the requested order.
"""
function project(
    batch::RecordBatch,
    col_names::Vector{Symbol}
)
    isempty(col_names) &&
        throw(ArgumentError("must project at least one column"))

    new_cols = Vector{Any}(undef, length(col_names))

    for (i, name) in enumerate(col_names)
        idx = findfirst(==(name), batch.names)
        if idx === nothing
            throw(ArgumentError("column :$name not found in batch"))
        end
        new_cols[i] = batch.columns[idx]
    end

    return RecordBatch(new_cols, col_names)
end
