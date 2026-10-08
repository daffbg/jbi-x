"""
Simple Hash Aggregation.
Groups rows by a specified column and calculates the sum of another column.
Null values in the group key are dropped (standard SQL behavior for simplicity).
Null values in the sum column are treated as 0.
"""
function hash_aggregate_sum(
    batch::RecordBatch,
    group_col_name::Symbol,
    agg_col_name::Symbol
)
    group_idx = findfirst(==(group_col_name), batch.names)
    agg_idx = findfirst(==(agg_col_name), batch.names)
    
    if group_idx === nothing
        throw(ArgumentError("Group column :$group_col_name not found"))
    end
    if agg_idx === nothing
        throw(ArgumentError("Aggregation column :$agg_col_name not found"))
    end
    
    group_col = batch.columns[group_idx]
    agg_col = batch.columns[agg_idx]
    
    # হ্যাশ ম্যাপ দিয়ে গ্রুপ এবং যোগফল ট্র্যাক করা হচ্ছে
    sums = Dict{eltype(group_col.values), eltype(agg_col.values)}()
    
    @inbounds for i in 1:nrows(batch)
        # গ্রুপ কী যদি Null থাকে, তবে স্কিপ করবে
        if !group_col.validity[i]
            continue
        end
        
        key = group_col.values[i]
        
        # যোগফলের ভ্যালু যদি Null থাকে, তবে ০ ধরে নেবে
        val = agg_col.validity[i] ? agg_col.values[i] : zero(eltype(agg_col.values))
        
        if haskey(sums, key)
            sums[key] += val
        else
            sums[key] = val
        end
    end
    
    # নতুন রেকর্ড ব্যাচ তৈরি করা
    n = length(sums)
    group_keys = Vector{eltype(group_col.values)}(undef, n)
    sum_vals = Vector{eltype(agg_col.values)}(undef, n)
    
    i = 1
    for (k, v) in sums
        group_keys[i] = k
        sum_vals[i] = v
        i += 1
    end
    
    # নতুন কলাম তৈরি (সবগুলো ভ্যালু valid)
    new_group_col = ColumnVector(group_keys, group_col.logical_type; validity=trues(n))
    new_agg_col = ColumnVector(sum_vals, agg_col.logical_type; validity=trues(n))
    
    return RecordBatch(
        [new_group_col, new_agg_col], 
        [group_col_name, Symbol("sum_" * String(agg_col_name))]
    )
end
