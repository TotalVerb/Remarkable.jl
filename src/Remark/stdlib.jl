module StdLib

export include_markdown, include_text

using ..RemarkStates
using SExpressions.Lists
using Documenter.Writers.HTMLWriter: mdconvert
using Documenter.Utilities.DOM: Node, TEXT
using Markdown

undomify(d::Node) = if d.name === TEXT
    d.text
else
    attributes = convert(list, [list(k, v) for (k, v) in d.attributes])
    undomified = map(undomify, d.nodes)
    if isempty(attributes)
        list(d.name, undomified...)
    else
        list(d.name, attributes, undomified...)
    end
end
rendermd(x) = undomify(mdconvert(Markdown.parse(x)))

let state = nothing
    global function setstate!(st)
        state = st
    end
    global function include_markdown(filename)
        file = relativeto(state, filename)
        StdLib.rendermd(read(file, String))
    end
    global function include_text(filename)
        read(relativeto(state, filename), String)
    end
end

end
