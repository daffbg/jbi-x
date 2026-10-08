using Test
using JBIXCore

@testset "JBI-X Core" begin

    @testset "End-to-End: Iris Dataset with JOIN, FILTER, GROUP BY, ORDER BY" begin
        # Load Iris and Species Meta
        iris = read_csv("/tmp/iris.csv")
        species_meta = read_csv("/tmp/species_meta.csv")
        
        tables = Dict(:iris => iris, :species_meta => species_meta)
        
        # Query: 
        # SELECT species, sum_petal_length 
        # FROM iris JOIN species_meta ON iris.species = species_meta.species 
        # WHERE petal_length > 1.5 
        # GROUP BY species 
        # ORDER BY sum_petal_length DESC
        query = "SELECT species, SUM(petal_length) FROM iris JOIN species_meta ON iris.species = species_meta.species WHERE petal_length > 1.5 GROUP BY species ORDER BY sum_petal_length DESC"
        
        plan = parse_sql(query)
        result = execute(tables, plan)
        
        @test nrows(result) == 3
        @test ncols(result) == 2
        
        # Virginica has the largest petals, so it should be first after DESC sort
        @test result.columns[1].values[1] == "virginica"
        # Check if sum is greater than 0
        @test result.columns[2].values[1] > 50.0
    end

end
