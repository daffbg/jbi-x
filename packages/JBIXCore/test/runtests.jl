using Test
using JBIXCore

@testset "JBI-X Core" begin

    @testset "Aggregate: Group By and Sum" begin
        # ডেটা: 
        # dept, salary
        # IT,   100
        # HR,   50
        # IT,   200
        # HR,   (null)
        # IT,   300
        depts = ColumnVector(String["IT", "HR", "IT", "HR", "IT"], StringTag)
        salaries = ColumnVector(
            Int64[100, 50, 200, 0, 300], 
            Int64Tag; 
            validity=BitVector([true, true, true, false, true])
        )
        batch = RecordBatch([depts, salaries], [:dept, :salary])
        
        result_batch = hash_aggregate_sum(batch, :dept, :salary)
        
        # দুটি গ্রুপ থাকার কথা (IT এবং HR)
        @test nrows(result_batch) == 2
        @test ncols(result_batch) == 2
        @test :sum_salary in result_batch.names
        
        # রেজাল্ট আউটপুট যাচাই করা (অর্ডার র‍্যান্ডম হতে পারে, তাই ডিকশনারি ব্যবহার করা হলো)
        res_dict = Dict(
            result_batch.columns[1].values[i] => result_batch.columns[2].values[i]
            for i in 1:nrows(result_batch)
        )
        
        # IT এর যোগফল হওয়া উচিত 100 + 200 + 300 = 600
        @test res_dict["IT"] == 600
        # HR এর যোগফল হওয়া উচিত 50 + 0 (null কে ০ ধরা হয়েছে) = 50
        @test res_dict["HR"] == 50
    end

    @testset "Aggregate: Validation" begin
        ids = ColumnVector(Int64[1, 2], Int64Tag)
        batch = RecordBatch([ids], [:id])
        
        @test_throws ArgumentError hash_aggregate_sum(batch, :nonexistent, :id)
        @test_throws ArgumentError hash_aggregate_sum(batch, :id, :nonexistent)
    end

end
