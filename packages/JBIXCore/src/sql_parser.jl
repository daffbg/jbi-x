function parse_sql(query::String)::QueryPlan
    upper_q = uppercase(query)
    
    select_idx = findfirst("SELECT", upper_q)
    from_idx = findfirst("FROM", upper_q)
    where_idx = findfirst("WHERE", upper_q)
    group_idx = findfirst("GROUP BY", upper_q)
    order_idx = findfirst("ORDER BY", upper_q)
    
    if select_idx === nothing || from_idx === nothing
        throw(ArgumentError("Query must contain SELECT and FROM"))
    end
    
    clause_end = length(query) + 1
    for idx in [where_idx, group_idx, order_idx]
        if idx !== nothing && idx[1] > from_idx[end] && idx[1] < clause_end
            clause_end = idx[1]
        end
    end
    
    cols_str = strip(query[select_idx[end]+1:from_idx[1]-1])
    proj = nothing
    if cols_str != "*"
        proj = Symbol[]
        for c in split(cols_str, ",")
            c = strip(c)
            m_sum = match(r"SUM\((\w+)\)", c)
            if m_sum !== nothing
                # SUM(salary) কে sum_salary তে রূপান্তর করা হচ্ছে
                push!(proj, Symbol("sum_" * m_sum.captures[1]))
            else
                push!(proj, Symbol(c))
            end
        end
    end
    
    group_by = nothing
    if group_idx !== nothing
        gb_end = order_idx !== nothing ? order_idx[1] : length(query) + 1
        gb_str = strip(query[group_idx[end]+1:gb_end-1])
        
        m_sum = match(r"SUM\((\w+)\)", cols_str)
        if m_sum !== nothing
            agg_col = Symbol(m_sum.captures[1])
            group_col = Symbol(gb_str)
            group_by = (group_col, agg_col)
        else
            throw(ArgumentError("GROUP BY requires SUM(col) in SELECT"))
        end
    end
    
    order_by = nothing
    if order_idx !== nothing
        ob_str = strip(query[order_idx[end]+1:end])
        parts = split(ob_str)
        col_name = Symbol(parts[1])
        rev = length(parts) > 1 && uppercase(parts[2]) == "DESC"
        order_by = (col_name, rev)
    end
    
    filter_expr = nothing
    if where_idx !== nothing
        w_end = group_idx !== nothing ? group_idx[1] : (order_idx !== nothing ? order_idx[1] : length(query) + 1)
        where_str = strip(query[where_idx[end]+1:w_end-1])
        
        m = match(r"(\w+)\s*(>|<|=)\s*(\d+\.?\d*)", where_str)
        if m !== nothing
            col_name = Symbol(m.captures[1])
            op = m.captures[2]
            val_str = m.captures[3]
            
            if occursin(".", val_str)
                val = parse(Float64, val_str)
                lit = Literal(val, Float64Tag)
            else
                val = parse(Int64, val_str)
                lit = Literal(val, Int64Tag)
            end
            
            if op == ">"
                filter_expr = GreaterThan(ColumnRef(col_name), lit)
            elseif op == "="
                filter_expr = Equal(ColumnRef(col_name), lit)
            else
                throw(ArgumentError("Unsupported operator: $op"))
            end
        else
            throw(ArgumentError("Unsupported WHERE clause: $where_str"))
        end
    end
    
    return QueryPlan(filter_expr, proj, group_by, order_by)
end
