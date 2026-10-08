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

    @testset "ColumnVector nullability" begin
        values = Int64[10, 20, 30, 40]
        validity = BitVector([true, false, true, true])
        column = ColumnVector(values, Int64Tag; validity=validity)
        @test column.validity == validity
    end

    @testset "ColumnVector validation" begin
        values = Int64[1, 2, 3]
        validity = BitVector([true, false])
        @test_throws ArgumentError ColumnVector(values, Int64Tag; validity=validity)
    end

    @testset "RecordBatch" begin
        ids = ColumnVector(Int64[1, 2, 3], Int64Tag)
        amounts = ColumnVector(Float64[10.0, 20.0, 30.0], Float64Tag)
        batch = RecordBatch([ids, amounts], [:id, :amount])
        @test nrows(batch) == 3
        @test ncols(batch) == 2
        @test batch.names == [:id, :amount]
    end

    @testset "RecordBatch validation" begin
        ids = ColumnVector(Int64[1, 2, 3], Int64Tag)
        amounts = ColumnVector(Float64[10.0, 20.0], Float64Tag)
        @test_throws ArgumentError RecordBatch([ids, amounts], [:id, :amount])
    end

    @testset "SelectionVector" begin
        selection = SelectionVector(BitVector([true, false, true, false, true]))
        @test selected_count(selection) == 3
    end

    @testset "Filter" begin
        column = ColumnVector(Int64[10, 20, 30, 40, 50], Int64Tag)
        selection = filter_column(column, x -> x >= 30)
        @test selected_count(selection) == 3
        @test selection.mask == BitVector([false, false, true, true, true])
    end

    @testset "Filter respects null validity" begin
        column = ColumnVector(Int64[10, 20, 30, 40], Int64Tag; validity=BitVector([true, false, true, true]))
        selection = filter_column(column, x -> x >= 20)
        @test selection.mask == BitVector([false, false, true, true])
    end

    @testset "Apply Selection (Materialization)" begin
        ids = ColumnVector(Int64[1, 2, 3, 4], Int64Tag)
        amounts = ColumnVector(Float64[10.0, 20.0, 30.0, 40.0], Float64Tag)
        batch = RecordBatch([ids, amounts], [:id, :amount])
        selection = filter_column(amounts, x -> x >= 20.0)
        filtered_batch = apply_selection(batch, selection)
        @test nrows(filtered_batch) == 3
        @test ncols(filtered_batch) == 2
        @test filtered_batch.columns[1].values == Int64[2, 3, 4]
        @test filtered_batch.columns[2].values == Float64[20.0, 30.0, 40.0]
    end

    @testset "Apply Selection with nulls" begin
        ids = ColumnVector(Int64[1, 2, 3, 4], Int64Tag)
        amounts = ColumnVector(Float64[10.0, 20.0, 30.0, 40.0], Float64Tag; validity=BitVector([true, false, true, true]))
        batch = RecordBatch([ids, amounts], [:id, :amount])
        selection = filter_column(amounts, x -> x >= 20.0)
        filtered_batch = apply_selection(batch, selection)
        @test nrows(filtered_batch) == 2
        @test filtered_batch.columns[1].values == Int64[3, 4]
        @test filtered_batch.columns[2].values == Float64[30.0, 40.0]
        @test all(filtered_batch.columns[2].validity)
    end

    @testset "Project columns" begin
        ids = ColumnVector(Int64[1, 2, 3], Int64Tag)
        amounts = ColumnVector(Float64[10.0, 20.0, 30.0], Float64Tag)
        names = ColumnVector(String["A", "B", "C"], StringTag)
        batch = RecordBatch([ids, amounts, names], [:id, :amount, :name])
        projected_batch = project(batch, [:amount, :id])
        @test ncols(projected_batch) == 2
        @test nrows(projected_batch) == 3
        @test projected_batch.names == [:amount, :id]
        @test projected_batch.columns[1].values == Float64[10.0, 20.0, 30.0]
        @test projected_batch.columns[2].values == Int64[1, 2, 3]
    end

    @testset "Project validation" begin
        ids = ColumnVector(Int64[1, 2, 3], Int64Tag)
        amounts = ColumnVector(Float64[10.0, 20.0, 30.0], Float64Tag)
        batch = RecordBatch([ids, amounts], [:id, :amount])
        @test_throws ArgumentError project(batch, [:id, :nonexistent])
    end

    @testset "Scalar: Add columns" begin
        col1 = ColumnVector(Int64[1, 2, 3], Int64Tag)
        col2 = ColumnVector(Int64[10, 20, 30], Int64Tag)
        result = add_columns(col1, col2)
        @test result.values == Int64[11, 22, 33]
        @test result.logical_type == Int64Tag
        @test all(result.validity)
    end

    @testset "Scalar: Add columns with null propagation" begin
        col1 = ColumnVector(Int64[1, 2, 3], Int64Tag; validity=BitVector([true, false, true]))
        col2 = ColumnVector(Int64[10, 20, 30], Int64Tag)
        result = add_columns(col1, col2)
        @test result.values == Int64[11, 0, 33] # Null slot can be anything internally
        @test result.validity == BitVector([true, false, true])
    end

    @testset "Scalar: Multiply scalar" begin
        col = ColumnVector(Float64[1.5, 2.5, 3.5], Float64Tag; validity=BitVector([true, false, true]))
        result = multiply_scalar(col, 2)
        @test result.values == Float64[3.0, 5.0, 7.0]
        @test result.validity == BitVector([true, false, true])
        @test result.logical_type == Float64Tag
    end

end
