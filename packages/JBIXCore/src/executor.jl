struct QueryPlan
    join::Union{Tuple{Symbol, Symbol, Symbol, Symbol}, Nothing}
    filter::Union{Expression, Nothing}
    project::Union{Vector{Symbol}, Nothing}
    group_by::Union{Tuple{Symbol, Symbol}, Nothing}
    having::Union{Expression, Nothing}
    order_by::Union{Tuple{Symbol, Bool}, Nothing}
    limit::Union{Int, Nothing}
end

function execute(tables::Dict{Symbol, RecordBatch}, plan::QueryPlan)
    if plan.join !== nothing
        l_table, r_table, l_key, r_key = plan.join
        current_batch = hash_join(tables[l_table], tables[r_table], l_key, r_key)
    else
        current_batch = first(values(tables))
    end
    
    if plan.filter !== nothing
        mask_col = evaluate(plan.filter, current_batch)
        if mask_col.logical_type != BoolTag
            throw(ArgumentError("Filter expression must evaluate to a boolean column"))
        end
        selection = SelectionVector(mask_col.validity .& mask_col.values)
        current_batch = apply_selection(current_batch, selection)
    end
    
    if plan.group_by !== nothing
        group_col, agg_col = plan.group_by
        current_batch = hash_aggregate_sum(current_batch, group_col, agg_col)
    end
    
    if plan.having !== nothing
        mask_col = evaluate(plan.having, current_batch)
        if mask_col.logical_type != BoolTag
            throw(ArgumentError("Having expression must evaluate to a boolean column"))
        end
        selection = SelectionVector(mask_col.validity .& mask_col.values)
        current_batch = apply_selection(current_batch, selection)
    end
    
    if plan.order_by !== nothing
        col_name, rev = plan.order_by
        current_batch = sort_batch(current_batch, col_name; rev=rev)
    end
    
    if plan.project !== nothing
        current_batch = project(current_batch, plan.project)
    end
    
    if plan.limit !== nothing
        n = min(plan.limit, nrows(current_batch))
        new_cols = [ColumnVector(c.values[1:n], c.logical_type; validity=c.validity[1:n]) for c in current_batch.columns]
        current_batch = RecordBatch(new_cols, current_batch.names)
    end
    
    return current_batch
end
