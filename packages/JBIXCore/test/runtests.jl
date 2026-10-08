using Test
using JBIXCore

@testset "JBI-X Core" begin

    @testset "Expressions: Evaluate Literal" begin
        ids = ColumnVector(Int64[1, 2, 3], Int64Tag)
        batch = RecordBatch([ids], [:id])
        expr = Literal(5, Int64Tag)
        result = evaluate(expr, batch)
        @test result.values == Int64[5, 5, 5]
    end

    @testset "IO: Read CSV" begin
        # একটি টেম্পরারি CSV ফাইল তৈরি করা হচ্ছে
        csv_content = """
        id,amount,name
        1,10.5,Alice
        2,20.0,Bob
        3,30.2,Charlie
        """
        # ফাইলে লেখা হচ্ছে (Kaggle /tmp ডিরেক্টরিতে রাখবে)
        open("/tmp/test_jbix.csv", "w") do io
            print(io, csv_content)
        end
        
        batch = read_csv("/tmp/test_jbix.csv")
        
        @test nrows(batch) == 3
        @test ncols(batch) == 3
        @test batch.names == [:id, :amount, :name]
        
        # প্রথম কলাম Int64 কি না যাচাই
        @test batch.columns[1].values == Int64[1, 2, 3]
        @test batch.columns[1].logical_type == Int64Tag
        
        # দ্বিতীয় কলাম Float64 কি না যাচাই
        @test batch.columns[2].values == Float64[10.5, 20.0, 30.2]
        @test batch.columns[2].logical_type == Float64Tag
        
        # তৃতীয় কলাম String কি না যাচাই
        @test batch.columns[3].values == String["Alice", "Bob", "Charlie"]
        @test batch.columns[3].logical_type == StringTag
    end

end
