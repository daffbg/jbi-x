struct QueryPlan
    join::Union{Tuple{Symbol, Symbol, Symbol, Symbol}, Nothing} # (left_table, right_table, left_key, right_key)
    filter::Union{Expression, Nothing}
    project::Union{Vector{Symbol}, Nothing}
    group_by::Union{Tuple{Symbol, Symbol}, Nothing}
    order_by::Union{Tuple{Symbol, Bool}, Nothing}
end

# Execute against a dictionary of tables
function execute(tables::Dict{Symbol, RecordBatch}, plan::QueryPlan)
    # ১. JOIN অপারেশন
    if plan.join !== nothing
        l_table, r_table, l_key, r_key = plan.join
        current_batch = hash_join(tables[l_table], tables[r_table], l_key, r_key)
    else
        # যদি JOIN না থাকে, তবে প্রথম টেবিলটি ব্যবহার করবে
        current_batch = first(values(tables))
    end
    
    # ২. Filter
    if plan.filter !== nothing
        mask_col = evaluate(plan.filter, current_batch)
        if mask_col.logical_type != BoolTag
            throw(ArgumentError("Filter expression must evaluate to a boolean column"))
        end
        selection = SelectionVector(mask_col.validity .& mask_col.values)
        current_batch = apply_selection(current_batch, selection)
    end
    
    # ৩. Group By
    if plan.group_by !== nothing
        group_col, agg_col = plan.group_by
        current_batch = hash_aggregate_sum(current_batch, group_col, agg_col)
    end
    
    # ৪. Order By
    if plan.order_by !== nothing
        col_name, rev = plan.order_by
        current_batch = sort_batch(current_batch, col_name; rev=rev)
    end
    
    # ৫. Project
    if plan.project !== nothing
        current_batch = project(current_batch, plan.project)
    end
    
    return current_batch
end
