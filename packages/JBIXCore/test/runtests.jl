using Test
using JBIXCore

@testset "JBI-X Core" begin

    @testset "ColumnVector" begin
        values = Int64[10, 20, 30, 40]
        column = ColumnVector(values, Int64Tag)
        @test column.values == values
        @test length(column.validity) == 4
        @test all(column.validity)
        @test column.logical_type == Int64Tag
    end

    @testset "RecordBatch" begin
        ids = ColumnVector(Int64[1, 2, 3], Int64Tag)
        amounts = ColumnVector(Float64[10.0, 20.0, 30.0], Float64Tag)
        batch = RecordBatch([ids, amounts], [:id, :amount])
        @test nrows(batch) == 3
        @test ncols(batch) == 2
    end

    @testset "Scalar: Add columns" begin
        col1 = ColumnVector(Int64[1, 2, 3], Int64Tag)
        col2 = ColumnVector(Int64[10, 20, 30], Int64Tag)
        result = add_columns(col1, col2)
        @test result.values == Int64[11, 22, 33]
        @test all(result.validity)
    end

    @testset "Expressions: Evaluate Literal" begin
        ids = ColumnVector(Int64[1, 2, 3], Int64Tag)
        batch = RecordBatch([ids], [:id])
        
        expr = Literal(5, Int64Tag)
        result = evaluate(expr, batch)
        @test result.values == Int64[5, 5, 5]
        @test result.logical_type == Int64Tag
    end

    @testset "Expressions: Evaluate ColumnRef" begin
        ids = ColumnVector(Int64[1, 2, 3], Int64Tag)
        batch = RecordBatch([ids], [:id])
        
        expr = ColumnRef(:id)
        result = evaluate(expr, batch)
        @test result.values == Int64[1, 2, 3]
    end

    @testset "Expressions: Evaluate Add" begin
        col1 = ColumnVector(Int64[1, 2, 3], Int64Tag)
        col2 = ColumnVector(Int64[10, 20, 30], Int64Tag)
        batch = RecordBatch([col1, col2], [:a, :b])
        
        expr = Add(ColumnRef(:a), ColumnRef(:b))
        result = evaluate(expr, batch)
        @test result.values == Int64[11, 22, 33]
    end

    @testset "Expressions: Evaluate GreaterThan" begin
        col1 = ColumnVector(Int64[1, 5, 3], Int64Tag)
        col2 = ColumnVector(Int64[2, 2, 2], Int64Tag)
        batch = RecordBatch([col1, col2], [:a, :b])
        
        # a > b => [1>2, 5>2, 3>2] => [false, true, true]
        expr = GreaterThan(ColumnRef(:a), ColumnRef(:b))
        result = evaluate(expr, batch)
        @test result.values == Bool[false, true, true]
        @test result.logical_type == BoolTag
        @test all(result.validity)
    end

    @testset "Expressions: Evaluate complex (a + b) > 10" begin
        col1 = ColumnVector(Int64[1, 5, 8], Int64Tag)
        col2 = ColumnVector(Int64[2, 2, 2], Int64Tag)
        batch = RecordBatch([col1, col2], [:a, :b])
        
        # a + b => [3, 7, 10]
        # (a + b) > 10 => [false, false, false]
        expr = GreaterThan(Add(ColumnRef(:a), ColumnRef(:b)), Literal(10, Int64Tag))
        result = evaluate(expr, batch)
        @test result.values == Bool[false, false, false]
    end

end
