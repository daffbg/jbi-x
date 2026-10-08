function parse_sql(query::String)::QueryPlan
    upper_q = uppercase(query)
    
    select_idx = findfirst("SELECT", upper_q)
    from_idx = findfirst("FROM", upper_q)
    join_idx = findfirst("JOIN", upper_q)
    on_idx = findfirst("ON", upper_q)
    where_idx = findfirst("WHERE", upper_q)
    group_idx = findfirst("GROUP BY", upper_q)
    having_idx = findfirst("HAVING", upper_q)
    order_idx = findfirst("ORDER BY", upper_q)
    limit_idx = findfirst("LIMIT", upper_q)
    
    if select_idx === nothing || from_idx === nothing
        throw(ArgumentError("Query must contain SELECT and FROM"))
    end
    
    clause_end = length(query) + 1
    for idx in [join_idx, where_idx, group_idx, having_idx, order_idx, limit_idx]
        if idx !== nothing && idx[1] > from_idx[end] && idx[1] < clause_end
            clause_end = idx[1]
        end
    end
    
    tables_str = strip(query[from_idx[end]+1:clause_end-1])
    parts = split(tables_str)
    left_table = Symbol(parts[1])
    
    join_plan = nothing
    if join_idx !== nothing
        right_table = Symbol(strip(query[join_idx[end]+1:on_idx[1]-1]))
        
        on_end = length(query) + 1
        for idx in [where_idx, group_idx, having_idx, order_idx, limit_idx]
            if idx !== nothing && idx[1] > on_idx[end] && idx[1] < on_end
                on_end = idx[1]
            end
        end
        on_str = strip(query[on_idx[end]+1:on_end-1])
        
        m = match(r"(\w+)\.(\w+)\s*=\s*(\w+)\.(\w+)", on_str)
        if m !== nothing
            if Symbol(m.captures[1]) == left_table
                l_key = Symbol(m.captures[2])
                r_key = Symbol(m.captures[4])
            else
                l_key = Symbol(m.captures[4])
                r_key = Symbol(m.captures[2])
            end
            join_plan = (left_table, right_table, l_key, r_key)
        else
            throw(ArgumentError("Unsupported JOIN ON clause: $on_str"))
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
                push!(proj, Symbol("sum_" * m_sum.captures[1]))
            else
                push!(proj, Symbol(c))
            end
        end
    end
    
    group_by = nothing
    if group_idx !== nothing
        gb_end = having_idx !== nothing ? having_idx[1] : (order_idx !== nothing ? order_idx[1] : (limit_idx !== nothing ? limit_idx[1] : length(query) + 1))
        gb_str = strip(query[group_idx[end]+1:gb_end-1])
        m_sum = match(r"SUM\((\w+)\)", cols_str)
        if m_sum !== nothing
            group_by = (Symbol(gb_str), Symbol(m_sum.captures[1]))
        end
    end
    
    having_expr = nothing
    if having_idx !== nothing
        h_end = order_idx !== nothing ? order_idx[1] : (limit_idx !== nothing ? limit_idx[1] : length(query) + 1)
        having_str = strip(query[having_idx[end]+1:h_end-1])
        m = match(r"(\w+)\s*(>|<|=)\s*(\d+\.?\d*)", having_str)
        if m !== nothing
            col_name = Symbol(m.captures[1])
            op = m.captures[2]
            val_str = m.captures[3]
            val = occursin(".", val_str) ? parse(Float64, val_str) : parse(Int64, val_str)
            lit = Literal(val, occursin(".", val_str) ? Float64Tag : Int64Tag)
            having_expr = op == ">" ? GreaterThan(ColumnRef(col_name), lit) : Equal(ColumnRef(col_name), lit)
        end
    end
    
    order_by = nothing
    if order_idx !== nothing
        ob_end = limit_idx !== nothing ? limit_idx[1] : length(query) + 1
        ob_str = strip(query[order_idx[end]+1:ob_end-1])
        p = split(ob_str)
        order_by = (Symbol(p[1]), length(p) > 1 && uppercase(p[2]) == "DESC")
    end
    
    limit_val = nothing
    if limit_idx !== nothing
        limit_str = strip(query[limit_idx[end]+1:end])
        limit_val = parse(Int, limit_str)
    end
    
    filter_expr = nothing
    if where_idx !== nothing
        w_end = group_idx !== nothing ? group_idx[1] : (having_idx !== nothing ? having_idx[1] : (order_idx !== nothing ? order_idx[1] : (limit_idx !== nothing ? limit_idx[1] : length(query) + 1)))
        where_str = strip(query[where_idx[end]+1:w_end-1])
        m = match(r"(\w+)\s*(>|<|=)\s*(\d+\.?\d*)", where_str)
        if m !== nothing
            col_name = Symbol(m.captures[1])
            op = m.captures[2]
            val_str = m.captures[3]
            val = occursin(".", val_str) ? parse(Float64, val_str) : parse(Int64, val_str)
            lit = Literal(val, occursin(".", val_str) ? Float64Tag : Int64Tag)
            filter_expr = op == ">" ? GreaterThan(ColumnRef(col_name), lit) : Equal(ColumnRef(col_name), lit)
        end
    end
    
    return QueryPlan(join_plan, filter_expr, proj, group_by, having_expr, order_by, limit_val)
end
