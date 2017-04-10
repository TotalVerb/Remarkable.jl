module StaticSites

export StaticSite, generate_page

struct StaticSite
    default_modules :: Vector{Module}
end

function generate_page(site::StaticSite,
                       root, page="remark/core.rem";
                       data::Associative{Symbol}=Dict{Symbol}(),
                       modules=[])
    start = Dates.now()
    info(isempty(root) ? "Index Page" : root; prefix="GENERATING: ")

    try mkdir("public/$root") end
    data[:currentpage] = root
    open("public/$root/index.html", "w") do f
        Remarkable.Remark.tohtml(f, page, data;
                                 modules=vcat(site.default_modules, modules))
        println(f)
    end

    finish = Dates.now()
    println(lpad("done in $(lpad(finish - start, 17))", displaysize(STDERR)[2]))
end

end
