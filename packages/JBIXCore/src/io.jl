"""
Simple CSV reader to load data into a RecordBatch.
Supports Int64, Float64, and String columns.
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
    
    # র ডেটা স্ট্রিং হিসেবে স্টোর করছি
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
    
    # টাইপ ইনফারেন্স এবং কলাম তৈরি
    columns = Vector{Any}(undef, ncols)
    names = Vector{Symbol}(undef, ncols)
    
    for c in 1:ncols
        names[c] = Symbol(header[c])
        col_strs = raw_data[c]
        
        # সবগুলো কি Int64?
        is_int = all(x -> occursin(r"^-?\d+$", x), col_strs)
        # সবগুলো কি Float64?
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
