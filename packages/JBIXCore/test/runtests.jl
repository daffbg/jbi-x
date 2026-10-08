using Test
using JBIXCore

@testset "JBI-X Core" begin

    @testset "Indexing: Hash Index Lookup" begin
        ids = ColumnVector(Int64[1, 2, 3, 2, 4], Int64Tag)
        names = ColumnVector(String["A", "B", "C", "D", "E"], StringTag)
        batch = RecordBatch([ids, names], [:id, :name])
        
        index = create_index(batch, :id)
        filtered_batch = filter_using_index(batch, index, 2)
        
        @test nrows(filtered_batch) == 2
        @test filtered_batch.columns[2].values == String["B", "D"]
    end

    @testset "ML: Logistic Regression Training" begin
        x_vals = Int64[1, 2, 3, 5, 6, 7]
        y_vals = Int64[0, 0, 0, 1, 1, 1]
        
        x_col = ColumnVector(x_vals, Int64Tag)
        y_col = ColumnVector(y_vals, Int64Tag)
        batch = RecordBatch([x_col, y_col], [:x, :y])
        
        model = train_logistic_regression(batch, [:x], :y; lr=0.1, epochs=500)
        
        # x=2.0 নিশ্চিতভাবে 0 ক্লাসে এবং x=6.0 নিশ্চিতভাবে 1 ক্লাসে
        prob_low = predict_proba(model, [2.0])
        prob_high = predict_proba(model, [6.0])
        
        @test prob_low < 0.5
        @test prob_high > 0.5
    end

end
