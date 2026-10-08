using Test
using JBIXCore
using Dates

@testset "JBI-X Core" begin

    @testset "IO: Read CSV with Bool" begin
        csv_content = """
        id,is_active
        1,true
        2,false
        3,true
        """
        open("/tmp/test_bool.csv", "w") do io
            print(io, csv_content)
        end
        batch = read_csv("/tmp/test_bool.csv")
        @test batch.columns[2].logical_type == BoolTag
        @test batch.columns[2].values == Bool[true, false, true]
    end

    @testset "Expressions: Evaluate Equal" begin
        col1 = ColumnVector(Int64[1, 5, 3], Int64Tag)
        col2 = ColumnVector(Int64[1, 2, 3], Int64Tag)
        batch = RecordBatch([col1, col2], [:a, :b])
        
        expr = Equal(ColumnRef(:a), ColumnRef(:b))
        result = evaluate(expr, batch)
        @test result.values == Bool[true, false, true]
    end

    @testset "SQL Parser: GROUP BY and ORDER BY" begin
        csv_content = """
        id,dept,salary
        1,IT,100
        2,HR,50
        3,IT,200
        4,HR,150
        """
        open("/tmp/test_groupby.csv", "w") do io
            print(io, csv_content)
        end
        batch = read_csv("/tmp/test_groupby.csv")
        
        # SELECT dept, SUM(salary) FROM data GROUP BY dept ORDER BY sum_salary DESC
        query = "SELECT dept, SUM(salary) FROM data GROUP BY dept ORDER BY sum_salary DESC"
        plan = parse_sql(query)
        result = execute(batch, plan)
        
        # IT: 300, HR: 200. Descending order -> IT first, then HR
        @test nrows(result) == 2
        @test result.columns[1].values == String["IT", "HR"]
        @test result.columns[2].values == Int64[300, 200]
    end

end
