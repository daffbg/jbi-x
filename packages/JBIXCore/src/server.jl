"""
Process a single request from an IO stream (TCP socket, pipe, or buffer).
Reads a query, executes it, and writes the result back to the IO stream.
"""
function process_request(io::IO, batch::RecordBatch)
    query = readline(io)
    plan = parse_sql(query)
    
    # execute ফাংশনটি এখন Dict গ্রহণ করে, তাই batch কে Dict এ মোড়ানো হচ্ছে
    tables = Dict(:data => batch)
    result = execute(tables, plan)
    
    print_batch(result, io)
end

"""
Starts a TCP server using the Sockets standard library.
"""
function start_server(batch::RecordBatch, port::Int=8081)
    @eval using Sockets
    server = listen(port)
    println("JBI-X Server listening on port $port...")
    
    sock = accept(server)
    try
        process_request(sock, batch)
    catch e
        println("Error: ", e)
    finally
        close(sock)
        close(server)
        println("Server shut down.")
    end
end
