"""
A simple interactive REPL to load a CSV and run SQL queries.
"""
function start_repl(csv_path::String)
    println("Loading $csv_path...")
    batch = read_csv(csv_path)
    println("Loaded $(nrows(batch)) rows.")
    println("Type SQL query (or 'exit' to quit):")
    
    while true
        print("jbi-x> ")
        query = readline()
        
        if strip(lowercase(query)) == "exit"
            println("Goodbye!")
            break
        end
        
        try
            plan = parse_sql(query)
            result = execute(batch, plan)
            print_batch(result)
        catch e
            println("Error: ", e)
        end
    end
end
