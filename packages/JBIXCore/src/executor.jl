struct QueryPlan
    join::Union{Tuple{Symbol, Symbol, Symbol, Symbol}, Nothing}
    base_table::Union{Symbol, Nothing}
    subquery::Union{QueryPlan, Nothing}
    filter::Union{Expression, Nothing}
    project::Union{Vector{Symbol}, Nothing}
    group_by::Union{Tuple{Symbol, Symbol}, Nothing}
    having::Union{Expression, Nothing}
    order_by::Union{Tuple{Symbol, Bool}, Nothing}
    limit::Union{Int, Nothing}
    union_queries::Union{Vector{QueryPlan}, Nothing}
end

function execute(tables::Dict{Symbol, RecordBatch}, plan::QueryPlan)
    if plan.union_queries !== nothing && !isempty(plan.union_queries)
        batches = [execute(tables, p) for p in plan.union_queries]
        current_batch = batches[1]
        for i in 2:length(batches)
            next_batch = batches[i]
            new_cols = Vector{ColumnVector}(undef, ncols(current_batch))
            for c in 1:ncols(current_batch)
                col1, col2 = current_batch.columns[c], next_batch.columns[c]
                vals = vcat(col1.values, col2.values)
                validity = vcat(col1.validity, col2.validity)
                new_cols[c] = ColumnVector(vals, col1.logical_type; validity=validity)
            end
            current_batch = RecordBatch(new_cols, current_batch.names)
        end
        return current_batch
    end
    
    if plan.join !== nothing
        l_table, r_table, l_key, r_key = plan.join
        current_batch = hash_join(tables[l_table], tables[r_table], l_key, r_key)
    elseif plan.subquery !== nothing
        current_batch = execute(tables, plan.subquery)
    elseif plan.base_table !== nothing
        current_batch = tables[plan.base_table]
    else
        current_batch = first(values(tables))
    end
    
    if plan.filter !== nothing
        mask_col = evaluate(plan.filter, current_batch)
        selection = SelectionVector(mask_col.validity .& mask_col.values)
        current_batch = apply_selection(current_batch, selection)
    end
    
    if plan.group_by !== nothing
        group_col, agg_col = plan.group_by
        current_batch = hash_aggregate_sum(current_batch, group_col, agg_col)
    end
    
    if plan.having !== nothing
        mask_col = evaluate(plan.having, current_batch)
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
