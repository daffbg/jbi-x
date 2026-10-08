using Test
using JBIXCore

@testset "JBI-X Core" begin

    @testset "Join: Hash Inner Join" begin
        order_ids = ColumnVector(Int64[1, 2, 3, 4], Int64Tag)
        cust_ids = ColumnVector(Int64[101, 102, 101, 103], Int64Tag)
        left_batch = RecordBatch([order_ids, cust_ids], [:order_id, :cust_id])
        
        r_cust_ids = ColumnVector(Int64[101, 102], Int64Tag)
        names = ColumnVector(String["Alice", "Bob"], StringTag)
        right_batch = RecordBatch([r_cust_ids, names], [:cust_id, :name])
        
        joined_batch = hash_join(left_batch, right_batch, :cust_id, :cust_id)
        
        @test nrows(joined_batch) == 3
        @test ncols(joined_batch) == 4
        
        # কলামের নাম ঠিক করা হয়েছে (name_right)
        @test joined_batch.names == [:order_id, :cust_id, :cust_id_right, :name_right]
        
        # name_right খুঁজে বের করা হচ্ছে
        order_id_idx = findfirst(==(:order_id), joined_batch.names)
        name_idx = findfirst(==(:name_right), joined_batch.names)
        
        result_pairs = Dict(
            joined_batch.columns[order_id_idx].values[i] => joined_batch.columns[name_idx].values[i]
            for i in 1:nrows(joined_batch)
        )
        
        @test result_pairs[1] == "Alice"
        @test result_pairs[2] == "Bob"
        @test result_pairs[3] == "Alice"
    end

    @testset "Join: Validation" begin
        ids = ColumnVector(Int64[1, 2], Int64Tag)
        left = RecordBatch([ids], [:id])
        right = RecordBatch([ids], [:id])
        
        @test_throws ArgumentError hash_join(left, right, :nonexistent, :id)
        @test_throws ArgumentError hash_join(left, right, :id, :nonexistent)
    end

end
