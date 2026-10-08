"""
Simple execution pipeline that ties together filtering and projection.
"""
struct QueryPlan
    filter::Union{Expression, Nothing}
    project::Union{Vector{Symbol}, Nothing}
end

function execute(batch::RecordBatch, plan::QueryPlan)
    current_batch = batch
    
    # ১. ফিল্টার অপারেশন (যদি থাকে)
    if plan.filter !== nothing
        mask_col = evaluate(plan.filter, current_batch)
        # নিশ্চিত করছি যে ফিল্টার এক্সপ্রেশনটি বুলিয়ান টাইপ রিটার্ন করেছে
        if mask_col.logical_type != BoolTag
            throw(ArgumentError("Filter expression must evaluate to a boolean column"))
        end
        selection = SelectionVector(mask_col.validity .& mask_col.values)
        current_batch = apply_selection(current_batch, selection)
    end
    
    # ২. প্রজেকশন অপারেশন (যদি থাকে)
    if plan.project !== nothing
        current_batch = project(current_batch, plan.project)
    end
    
    return current_batch
end
