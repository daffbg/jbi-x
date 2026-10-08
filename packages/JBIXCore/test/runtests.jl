using Test
using JBIXCore
using Dates

@testset "JBI-X Core" begin

    @testset "IO: Read CSV with Date" begin
        csv_content = """
        id,event_date
        1,2023-01-01
        2,2023-02-15
        3,2023-03-20
        """
        open("/tmp/test_dates.csv", "w") do io
            print(io, csv_content)
        end
        batch = read_csv("/tmp/test_dates.csv")
        @test batch.columns[2].logical_type == DateTag
        @test batch.columns[2].values == [Date(2023,1,1), Date(2023,2,15), Date(2023,3,20)]
    end

    @testset "SQL Parser: Basic Query" begin
        csv_content = """
        id,amount,name
        1,10.5,Alice
        2,20.0,Bob
        3,30.2,Charlie
        """
        open("/tmp/test_sql.csv", "w") do io
            print(io, csv_content)
        end
        batch = read_csv("/tmp/test_sql.csv")
        
        query = "SELECT name, amount FROM data WHERE amount > 15"
        plan = parse_sql(query)
        result = execute(batch, plan)
        
        @test nrows(result) == 2
        @test result.names == [:name, :amount]
        @test result.columns[1].values == String["Bob", "Charlie"]
    end

end
