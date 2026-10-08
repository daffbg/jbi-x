"""
CLI / Formatting interface to view RecordBatches in a table format.
"""
function print_batch(batch::RecordBatch, io::IO=stdout)
    n = nrows(batch)
    c = ncols(batch)
    
    # String representation of all values
    str_vals = Vector{Vector{String}}(undef, c)
    for i in 1:c
        col = batch.columns[i]
        str_vals[i] = [col.validity[j] ? string(col.values[j]) : "NULL" for j in 1:n]
    end
    
    # Calculate column widths
    widths = [length(String(batch.names[i])) for i in 1:c]
    for i in 1:c
        for j in 1:n
            widths[i] = max(widths[i], length(str_vals[i][j]))
        end
    end
    
    # Format header
    header = join([rpad(String(batch.names[i]), widths[i]) for i in 1:c], " | ")
    separator = join(["-" ^ widths[i] for i in 1:c], "-+-")
    
    println(io, header)
    println(io, separator)
    
    for j in 1:n
        row = join([rpad(str_vals[i][j], widths[i]) for i in 1:c], " | ")
        println(io, row)
    end
end
