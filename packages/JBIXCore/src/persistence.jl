"""
Custom binary persistence for RecordBatch.
No external dependencies required.
"""

function save_batch(batch::RecordBatch, path::String)
    open(path, "w") do io
        write(io, batch.nrows)
        write(io, length(batch.columns))
        
        # Write names
        for name in batch.names
            str = String(name)
            write(io, sizeof(str))
            write(io, str)
        end
        
        # Write columns
        for col in batch.columns
            write(io, Int(col.logical_type))
            
            # Write validity as Vector{Bool}
            valid_bools = Vector{Bool}(col.validity)
            write(io, length(valid_bools))
            write(io, valid_bools)
            
            # Write values based on type
            if col.logical_type == Int64Tag
                write(io, length(col.values))
                write(io, col.values)
            elseif col.logical_type == Float64Tag
                write(io, length(col.values))
                write(io, col.values)
            elseif col.logical_type == StringTag
                write(io, length(col.values))
                for v in col.values
                    write(io, sizeof(v))
                    write(io, v)
                end
            elseif col.logical_type == BoolTag
                write(io, length(col.values))
                write(io, col.values)
            else
                throw(ArgumentError("Unsupported type for persistence: $(col.logical_type)"))
            end
        end
    end
    return path
end

function load_batch(path::String)
    open(path, "r") do io
        nrows = read(io, Int)
        ncols = read(io, Int)
        
        names = Vector{Symbol}(undef, ncols)
        for i in 1:ncols
            len = read(io, Int)
            str = String(read(io, len))
            names[i] = Symbol(str)
        end
        
        cols = Vector{ColumnVector}(undef, ncols)
        for i in 1:ncols
            tag = DataTypeTag(read(io, Int))
            
            # Read validity
            valid_len = read(io, Int)
            valid_bools = Vector{Bool}(undef, valid_len)
            read!(io, valid_bools)
            validity = BitVector(valid_bools)
            
            # Read values
            len = read(io, Int)
            if tag == Int64Tag
                vals = Vector{Int64}(undef, len)
                read!(io, vals)
            elseif tag == Float64Tag
                vals = Vector{Float64}(undef, len)
                read!(io, vals)
            elseif tag == StringTag
                vals = Vector{String}(undef, len)
                for j in 1:len
                    slen = read(io, Int)
                    vals[j] = String(read(io, slen))
                end
            elseif tag == BoolTag
                vals = Vector{Bool}(undef, len)
                read!(io, vals)
            else
                throw(ArgumentError("Unsupported type read from disk: $tag"))
            end
            
            cols[i] = ColumnVector(vals, tag; validity=validity)
        end
        
        return RecordBatch(cols, names)
    end
end
