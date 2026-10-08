using Test
using JBIXCore

@testset "JBI-X Core" begin

    @testset "SQL: Subquery in FROM clause" begin
        ids = ColumnVector(Int64[1, 2, 3, 4, 5], Int64Tag)
        batch = RecordBatch([ids], [:id])
        tables = Dict(:data => batch)
        
        query = "SELECT id FROM (SELECT id FROM data WHERE id > 2)"
        plan = parse_sql(query)
        result = execute(tables, plan)
        
        @test nrows(result) == 3
        @test result.columns[1].values == Int64[3, 4, 5]
    end

    @testset "ML: K-Means Clustering" begin
        # 2 clear clusters: points near (0,0) and points near (10,10)
        x = Float64[0.1, 0.2, 0.3, 9.8, 9.9, 10.0]
        y = Float64[0.1, 0.2, 0.3, 9.8, 9.9, 10.0]
        x_col = ColumnVector(x, Float64Tag)
        y_col = ColumnVector(y, Float64Tag)
        batch = RecordBatch([x_col, y_col], [:x, :y])
        
        model = train_kmeans(batch, [:x, :y], 2; max_iters=50)
        
        # Check if 2 centroids are formed
        @test length(model.centroids) == 2
        
        # A point near (0,0) and a point near (10,10) should be in different clusters
        c1 = predict_cluster(model, [0.0, 0.0])
        c2 = predict_cluster(model, [10.0, 10.0])
        @test c1 != c2
    end

end
