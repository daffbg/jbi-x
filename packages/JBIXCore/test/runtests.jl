using Test
using JBIXCore

@testset "JBI-X Core" begin

    @testset "SQL: UNION clause" begin
        # Table 1
        ids1 = ColumnVector(Int64[1, 2], Int64Tag)
        names1 = ColumnVector(String["Alice", "Bob"], StringTag)
        batch1 = RecordBatch([ids1, names1], [:id, :name])
        
        # Table 2
        ids2 = ColumnVector(Int64[3, 4], Int64Tag)
        names2 = ColumnVector(String["Charlie", "David"], StringTag)
        batch2 = RecordBatch([ids2, names2], [:id, :name])
        
        tables = Dict(:data1 => batch1, :data2 => batch2)
        
        query = "SELECT name FROM data1 UNION SELECT name FROM data2"
        plan = parse_sql(query)
        result = execute(tables, plan)
        
        @test nrows(result) == 4
        @test result.names == [:name]
        @test result.columns[1].values == String["Alice", "Bob", "Charlie", "David"]
    end

end
