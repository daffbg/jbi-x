"""
Simple Hash Join (Inner Join) between two RecordBatches.
Joins on a single column. 
Null keys are ignored in the join condition.
"""
function hash_join(
    left::RecordBatch,
    right::RecordBatch,
    left_key::Symbol,
    right_key::Symbol;
    suffix_left::String="_left",
    suffix_right::String="_right"
)
    l_idx = findfirst(==(left_key), left.names)
    r_idx = findfirst(==(right_key), right.names)
    
    if l_idx === nothing
        throw(ArgumentError("Join key :$left_key not found in left batch"))
    end
    if r_idx === nothing
        throw(ArgumentError("Join key :$right_key not found in right batch"))
    end
    
    l_key_col = left.columns[l_idx]
    r_key_col = right.columns[r_idx]
    
    # ১. ডান ব্যাচের উপর হ্যাশ টেবিল তৈরি করা (key -> array of row indices)
    # একই key এর একাধিক row থাকতে পারে, তাই Vector ব্যবহার করা হয়েছে
    hash_map = Dict{eltype(r_key_col.values), Vector{Int}}()
    
    @inbounds for i in 1:nrows(right)
        if r_key_col.validity[i]
            key = r_key_col.values[i]
            if haskey(hash_map, key)
                push!(hash_map[key], i)
            else
                hash_map[key] = [i]
            end
        end
    end
    
    # ২. বাম ব্যাচ স্ক্যান করে ম্যাচিং রো খুঁজে বের করা
    # প্রথমে আমরা কতগুলো রো ম্যাচ করবে তা জানি না, তাই ডাইনামিক অ্যারে ব্যবহার করছি
    matched_rows = Int[]
    for i in 1:nrows(left)
        if l_key_col.validity[i]
            key = l_key_col.values[i]
            if haskey(hash_map, key)
                for r in hash_map[key]
                    push!(matched_rows, i)  # left row index
                    push!(matched_rows, r)  # right row index
                end
            end
        end
    end
    
    num_matches = div(length(matched_rows), 2)
    
    # ৩. নতুন কলাম তৈরি করা
    new_cols = Vector{Any}(undef, ncols(left) + ncols(right))
    new_names = Vector{Symbol}(undef, length(new_cols))
    
    # বাম ব্যাচের কলামগুলো
    for c in 1:ncols(left)
        T = eltype(left.columns[c].values)
        vals = Vector{T}(undef, num_matches)
        validity = BitVector(undef, num_matches)
        
        for m in 1:num_matches
            l_row = matched_rows[2*m - 1]
            vals[m] = left.columns[c].values[l_row]
            validity[m] = left.columns[c].validity[l_row]
        end
        
        new_cols[c] = ColumnVector(vals, left.columns[c].logical_type; validity=validity)
        new_names[c] = left.names[c]
    end
    
    # ডান ব্যাচের কলামগুলো (নামের কনফ্লিক্ট এড়াতে suffix যোগ করা হয়েছে)
    offset = ncols(left)
    for c in 1:ncols(right)
        T = eltype(right.columns[c].values)
        vals = Vector{T}(undef, num_matches)
        validity = BitVector(undef, num_matches)
        
        for m in 1:num_matches
            r_row = matched_rows[2*m]
            vals[m] = right.columns[c].values[r_row]
            validity[m] = right.columns[c].validity[r_row]
        end
        
        new_cols[offset + c] = ColumnVector(vals, right.columns[c].logical_type; validity=validity)
        
        # key কলামটি ডান ব্যাচেও থাকলে, সেটি ডান ব্যাচের সাথে suffix দিয়ে রাখা হবে
        new_names[offset + c] = Symbol(String(right.names[c]) * suffix_right)
    end
    
    return RecordBatch(new_cols, new_names)
end
