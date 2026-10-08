"""
Simple CSV reader and writer.
"""
function read_csv(
    path::String;
    delim::Char=',',
    has_header::Bool=true
)
    lines = readlines(path)
    isempty(lines) && throw(ArgumentError("CSV file is empty"))

    header = has_header ? split(replace(lines[1], "\r" => ""), delim) : String[]
    data_lines = has_header ? lines[2:end] : lines
    ncols = length(header)
    nrows = length(data_lines)
    
    raw_data = Vector{Vector{String}}(undef, ncols)
    for i in 1:ncols
        raw_data[i] = Vector{String}(undef, nrows)
    end
    
    @inbounds for (r, line) in enumerate(data_lines)
        parts = split(replace(line, "\r" => ""), delim)
        for c in 1:ncols
            raw_data[c][r] = parts[c]
        end
    end
    
    columns = Vector{Any}(undef, ncols)
    names = Vector{Symbol}(undef, ncols)
    
    for c in 1:ncols
        names[c] = Symbol(header[c])
        col_strs = raw_data[c]
        
        is_int = all(x -> occursin(r"^-?\d+$", x), col_strs)
        is_float = all(x -> occursin(r"^-?\d+(\.\d+)?([eE][-+]?\d+)?$", x), col_strs)
        
        if is_int
            vals = parse.(Int64, col_strs)
            columns[c] = ColumnVector(vals, Int64Tag)
        elseif is_float
            vals = parse.(Float64, col_strs)
            columns[c] = ColumnVector(vals, Float64Tag)
        else
            vals = String.(col_strs)
            columns[c] = ColumnVector(vals, StringTag)
        end
    end
    
    return RecordBatch(columns, names)
end

"""
Write a RecordBatch to a CSV file.
Null values are written as empty strings.
"""
function write_csv(
    batch::RecordBatch,
    path::String;
    delim::Char=','
)
    open(path, "w") do io
        # Write header
        println(io, join(String.(batch.names), delim))
        
        # Write rows
        for r in 1:nrows(batch)
            row_vals = String[]
            for c in 1:ncols(batch)
                col = batch.columns[c]
                if col.validity[r]
                    push!(row_vals, string(col.values[r]))
                else
                    push!(row_vals, "") # Null represented as empty
                end
            end
            println(io, join(row_vals, delim))
        end
    end
    return path
end
