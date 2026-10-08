struct QueryPlan
    filter::Union{Expression, Nothing}
    project::Union{Vector{Symbol}, Nothing}
    group_by::Union{Tuple{Symbol, Symbol}, Nothing} # (group_col, agg_col)
    order_by::Union{Tuple{Symbol, Bool}, Nothing} # (col_name, rev)
end

function execute(batch::RecordBatch, plan::QueryPlan)
    current_batch = batch
    
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
    
    if plan.order_by !== nothing
        col_name, rev = plan.order_by
        current_batch = sort_batch(current_batch, col_name; rev=rev)
    end
    
    if plan.project !== nothing
        current_batch = project(current_batch, plan.project)
    end
    
    return current_batch
end
