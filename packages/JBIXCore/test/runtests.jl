using Test
using JBIXCore

@testset "JBI-X Core" begin

    @testset "Window: ROW_NUMBER" begin
        ids = ColumnVector(Int64[10, 20, 30], Int64Tag)
        batch = RecordBatch([ids], [:id])
        
        rn_col = row_number(batch)
        @test rn_col.values == Int64[1, 2, 3]
        @test rn_col.logical_type == Int64Tag
    end

    @testset "Window: RANK with ties" begin
        # Data:
        # name, score
        # Alice, 100
        # Bob, 50
        # Charlie, 100
        # David, 25
        names = ColumnVector(String["Alice", "Bob", "Charlie", "David"], StringTag)
        scores = ColumnVector(Int64[100, 50, 100, 25], Int64Tag)
        batch = RecordBatch([names, scores], [:name, :score])
        
        rank_col = rank(batch, :score)
        
        # Sorted scores: 25(David, rank 1), 50(Bob, rank 2), 100(Alice, rank 3), 100(Charlie, rank 3)
        @test rank_col.values[1] == 3 # Alice
        @test rank_col.values[2] == 2 # Bob
        @test rank_col.values[3] == 3 # Charlie
        @test rank_col.values[4] == 1 # David
    end

end
