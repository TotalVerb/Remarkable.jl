module StaticSites

using Dates
using Logging
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
        @info "Copying static file" file
        cp(joinpath(site.static_root, file),
           joinpath(site.target_root, file);
           force=true)
    end
end

function generate_page(site::StaticSite,
                       destination, page=site.default_page;
                       data::AbstractDict{Symbol}=Dict{Symbol}(),
                       modules=[])
    start = Dates.now()
    description = isempty(destination) ? "Index page" : destination
    @debug "Started generating remark page" start page=description

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
    @info "Generated remark page" elapsed=(finish - start) page=description
end

end
