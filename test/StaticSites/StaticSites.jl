using Remarkable.StaticSites
using Logging

mktempdir() do target_root
    source_root = joinpath(@__DIR__, "remark")
    static_root = joinpath(@__DIR__, "static")
    expected_output_root = joinpath(@__DIR__, "expected")
    site = StaticSite(source_root=source_root,
                      static_root=static_root,
                      target_root=target_root)

    @test_logs (:info, "Copying static file") prepare(site)
    @test_logs (:info, "Generated remark page") (
         generate_page(site, "", data=Dict(:pagetitle => "Main page")))

    @testset "Static site generation" begin
        @test Set(readdir(target_root)) == Set(["index.html", "example.html"])
        @test read(joinpath(target_root, "example.html"), String) ==
              read(joinpath(static_root, "example.html"), String)
        @test read(joinpath(target_root, "index.html"), String) ==
              read(joinpath(expected_output_root, "index.html"), String)
    end
end
