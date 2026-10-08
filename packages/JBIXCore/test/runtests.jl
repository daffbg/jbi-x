using Test
using JBIXCore

@testset "JBI-X Core" begin

    @testset "Network: Request Processing Simulation" begin
        ids = ColumnVector(Int64[1, 2, 3], Int64Tag)
        names = ColumnVector(String["Alice", "Bob", "Charlie"], StringTag)
        batch = RecordBatch([ids, names], [:id, :name])
        
        # একটি IOBuffer দিয়ে ক্লায়েন্টের রিকোয়েস্ট সিমুলেট করা হচ্ছে
        io = IOBuffer()
        println(io, "SELECT name FROM data WHERE id > 1")
        seekstart(io)
        
        # সার্ভারের প্রসেস ফাংশন কল করা হচ্ছে (এটি io থেকে পড়বে এবং এতেই লিখবে)
        process_request(io, batch)
        
        # রেসপন্স যাচাই করা
        seekstart(io)
        response = read(io, String)
        
        @test occursin("Bob", response)
        @test occursin("Charlie", response)
        @test !occursin("Alice", response)
    end

end
