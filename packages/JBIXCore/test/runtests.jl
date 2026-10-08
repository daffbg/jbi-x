using Test
using JBIXCore

@testset "JBI-X Core" begin

    @testset "Sort: Ascending with Nulls" begin
        ids = ColumnVector(Int64[1, 2, 3], Int64Tag)
        vals = ColumnVector(Int64[30, 10, 20], Int64Tag; validity=BitVector([true, false, true]))
        batch = RecordBatch([ids, vals], [:id, :val])
        
        sorted_batch = sort_batch(batch, :val)
        
        @test sorted_batch.columns[1].values == Int64[2, 3, 1]
        @test sorted_batch.columns[2].values == Int64[10, 20, 30]
        @test sorted_batch.columns[2].validity == BitVector([false, true, true])
    end

    @testset "IO: Write CSV" begin
        ids = ColumnVector(Int64[1, 2], Int64Tag)
        names = ColumnVector(String["Alice", "Bob"], StringTag; validity=BitVector([true, false]))
        batch = RecordBatch([ids, names], [:id, :name])
        
        path = "/tmp/test_write.csv"
        write_csv(batch, path)
        
        content = read(path, String)
        expected = "id,name\n1,Alice\n2,\n"
        @test content == expected
    end

    @testset "CLI: Print Batch" begin
        ids = ColumnVector(Int64[1, 2], Int64Tag)
        batch = RecordBatch([ids], [:id])
        
        # io আর্গুমেন্ট ব্যবহার করে আউটপুট ক্যাপচার করা হচ্ছে
        io = IOBuffer()
        print_batch(batch, io)
        output = String(take!(io))
        
        @test occursin("id", output)
        @test occursin("1", output)
        @test occursin("2", output)
    end

end
