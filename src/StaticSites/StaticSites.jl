module StaticSites

using Dates
using ..Remark
export StaticSite, generate_page, prepare

struct StaticSite
    source_root     :: String
    target_root     :: String
    static_root     :: String
    default_modules :: Vector{Module}
    default_page    :: String

    function StaticSite(;
                        source_root="remark/",
                        target_root="target/",
                        static_root="static/",
                        default_modules=[],
                        default_page="main.rem")
        new(source_root,
            target_root,
            static_root,
            default_modules,
            default_page)
    end
end

"""
Prepare the site for page generation by:

 1. Building a directory structure skeleton
 2. Copying static files
"""
function prepare(site::StaticSite)
    mkpath(site.target_root)
    for file in readdir(site.static_root)
        info(file; prefix="COPYING: ")
        cp(joinpath(site.static_root, file),
           joinpath(site.target_root, file);
           remove_destination=true)
    end
end

function generate_page(site::StaticSite,
                       destination, page=site.default_page;
                       data::AbstractDict{Symbol}=Dict{Symbol}(),
                       modules=[])
    start = Dates.now()
    info(isempty(destination) ? "Index Page" : destination;
         prefix="GENERATING: ")

    location = joinpath(site.target_root, destination)
    mkpath(location)

    source = joinpath(site.source_root, page)

    data[:currentpage] = destination
    open(joinpath(location, "index.html"), "w") do f
        Remark.tohtml(f, source, data;
                                 modules=vcat(site.default_modules, modules))
        println(f)
    end

    finish = Dates.now()
    println(lpad("done in $(lpad(finish - start, 17))", displaysize(STDERR)[2]))
end

end
