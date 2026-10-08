using Test
using JBIXCore

@testset "JBI-X Core" begin

    @testset "IO: Read CSV" begin
        csv_content = """
        id,amount,name
        1,10.5,Alice
        2,20.0,Bob
        3,30.2,Charlie
        """
        open("/tmp/test_jbix.csv", "w") do io
            print(io, csv_content)
        end
        batch = read_csv("/tmp/test_jbix.csv")
        @test nrows(batch) == 3
    end

    @testset "Executor: Execute full pipeline (Filter + Project)" begin
        csv_content = """
        id,amount,name
        1,10.5,Alice
        2,20.0,Bob
        3,30.2,Charlie
        """
        open("/tmp/test_jbix_exec.csv", "w") do io
            print(io, csv_content)
        end
        batch = read_csv("/tmp/test_jbix_exec.csv")
        
        # কোয়েরি: SELECT name, amount WHERE amount > 15.0
        plan = QueryPlan(
            GreaterThan(ColumnRef(:amount), Literal(15.0, Float64Tag)),
            [:name, :amount]
        )
        
        result_batch = execute(batch, plan)
        
        # ১০.৫ বাদ পড়বে, কারণ এটি ১৫ এর চেয়ে বড় নয়
        @test nrows(result_batch) == 2
        @test ncols(result_batch) == 2
        
        # প্রজেকশন ঠিকমতো হয়েছে কিনা
        @test result_batch.names == [:name, :amount]
        @test result_batch.columns[1].values == String["Bob", "Charlie"]
        @test result_batch.columns[2].values == Float64[20.0, 30.2]
    end

    @testset "Executor: Execute only Project" begin
        batch = RecordBatch([
            ColumnVector(Int64[1, 2], Int64Tag),
            ColumnVector(String["A", "B"], StringTag)
        ], [:id, :name])
        
        plan = QueryPlan(nothing, [:name])
        result_batch = execute(batch, plan)
        
        @test nrows(result_batch) == 2
        @test ncols(result_batch) == 1
        @test result_batch.names == [:name]
    end

end
