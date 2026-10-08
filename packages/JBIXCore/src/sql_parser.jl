"""
Very basic SQL parser.
Supports: SELECT col1, col2 WHERE col > value
Returns a QueryPlan.
"""
function parse_sql(query::String)::QueryPlan
    upper_q = uppercase(query)
    
    select_idx = findfirst("SELECT", upper_q)
    from_idx = findfirst("FROM", upper_q)
    where_idx = findfirst("WHERE", upper_q)
    
    if select_idx === nothing || from_idx === nothing
        throw(ArgumentError("Query must contain SELECT and FROM"))
    end
    
    # Projection কলামগুলো বের করা এবং স্পেস বাদ দেওয়া
    cols_str = strip(query[select_idx[end]+1:from_idx[1]-1])
    if cols_str == "*"
        proj = nothing
    else
        # strip(c) যোগ করা হয়েছে যাতে স্পেস বাদ যায়
        proj = [Symbol(strip(c)) for c in split(cols_str, ",")]
    end
    
    # Filter এক্সপ্রেশন বের করা
    filter_expr = nothing
    if where_idx !== nothing
        where_str = strip(query[where_idx[end]+1:end])
        
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
            else
                throw(ArgumentError("Unsupported operator: $op"))
            end
        else
            throw(ArgumentError("Unsupported WHERE clause: $where_str"))
        end
    end
    
    return QueryPlan(filter_expr, proj)
end
