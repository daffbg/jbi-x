using Test
using JBIXCore

@testset "JBI-X Core" begin

    @testset "ML: Linear Regression Training" begin
        # Data: y = 2x + 1
        # x = 1, y = 3
        # x = 2, y = 5
        # x = 3, y = 7 (Null, should be ignored)
        # x = 4, y = 9
        x_vals = ColumnVector(Int64[1, 2, 3, 4], Int64Tag; validity=BitVector([true, true, false, true]))
        y_vals = ColumnVector(Int64[3, 5, 7, 9], Int64Tag; validity=BitVector([true, true, true, true]))
        batch = RecordBatch([x_vals, y_vals], [:x, :y])
        
        model = train_linear_regression(batch, :x, :y)
        
        # Expected slope = 2.0, intercept = 1.0
        @test model.slope ≈ 2.0 atol=1e-5
        @test model.intercept ≈ 1.0 atol=1e-5
        
        # Test prediction
        @test predict(model, 5.0) ≈ 11.0 atol=1e-5
    end

end
