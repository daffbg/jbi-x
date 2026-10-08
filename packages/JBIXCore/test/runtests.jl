using Test
using JBIXCore

@testset "JBI-X Core" begin

    @testset "Persistence: Save and Load Batch" begin
        ids = ColumnVector(Int64[1, 2, 3], Int64Tag)
        names = ColumnVector(String["Alice", "Bob", "Charlie"], StringTag)
        batch = RecordBatch([ids, names], [:id, :name])
        
        path = "/tmp/test_batch.bin"
        save_batch(batch, path)
        
        loaded_batch = load_batch(path)
        
        @test nrows(loaded_batch) == 3
        @test loaded_batch.names == [:id, :name]
        @test loaded_batch.columns[2].values == String["Alice", "Bob", "Charlie"]
    end

    @testset "SQL: LIMIT clause" begin
        ids = ColumnVector(Int64[1, 2, 3, 4, 5], Int64Tag)
        batch = RecordBatch([ids], [:id])
        tables = Dict(:data => batch)
        
        query = "SELECT id FROM data LIMIT 2"
        plan = parse_sql(query)
        result = execute(tables, plan)
        
        @test nrows(result) == 2
        @test result.columns[1].values == Int64[1, 2]
    end

    @testset "SQL: HAVING clause" begin
        depts = ColumnVector(String["IT", "HR", "IT", "HR", "IT"], StringTag)
        salaries = ColumnVector(Int64[100, 50, 200, 150, 300], Int64Tag)
        batch = RecordBatch([depts, salaries], [:dept, :salary])
        tables = Dict(:data => batch)
        
        # Group by dept, sum salary, keep only sums > 400
        query = "SELECT dept, SUM(salary) FROM data GROUP BY dept HAVING sum_salary > 400"
        plan = parse_sql(query)
        result = execute(tables, plan)
        
        # IT: 600, HR: 200. Only IT should remain
        @test nrows(result) == 1
        @test result.columns[1].values[1] == "IT"
        @test result.columns[2].values[1] == 600
    end

end
