using Test
using JBIXCore

@testset "JBI-X Core" begin

    @testset "IO: Paginated CSV Reader" begin
        # একটি বড় ডামি ফাইল তৈরি করা হচ্ছে (১৫ রো)
        open("/tmp/test_pages.csv", "w") do io
            println(io, "id,val")
            for i in 1:15
                println(io, "$i,data_$i")
            end
        end
        
        # পেজ সাইজ ৫ দিয়ে রিড করা হচ্ছে
        pages = collect(read_csv_pages("/tmp/test_pages.csv", 5))
        
        # ১৫ রো এবং পেজ সাইজ ৫ হলে ৩টি পেজ হওয়ার কথা
        @test length(pages) == 3
        
        # প্রতি পেজে ৫টি রো থাকার কথা
        @test nrows(pages[1]) == 5
        @test nrows(pages[2]) == 5
        @test nrows(pages[3]) == 5
        
        # প্রথম পেজের প্রথম ভ্যালু চেক করা
        @test pages[1].columns[1].values[1] == "1"
        # শেষ পেজের শেষ ভ্যালু চেক করা
        @test pages[3].columns[2].values[5] == "data_15"
    end

end
