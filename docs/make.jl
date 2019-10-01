using Documenter, Remarkable

makedocs(;
    modules  = [Remarkable],
    format   = Documenter.HTML(analytics = "UA-68884109-1"),
    pages    = [
        "Home" => "index.md",
    ],
    repo     = "https://github.com/TotalVerb/Remarkable.jl/blob/{commit}{path}#L{line}",
    sitename = "Remarkable.jl",
    authors  = "Fengyang Wang",
)

deploydocs(
    repo = "github.com/TotalVerb/Remarkable.jl",
)
