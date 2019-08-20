module Remark

using Base64
using Dates
using Documenter.Utilities.DOM
using EnglishText: SemanticText
using FunctionalCollections: PersistentHashMap
using SchemeSyntax
using SExpressions.Parser
using SExpressions.Lists
using SExpressions.Keywords

include("RemarkStates.jl")
include("stdlib.jl")
using .RemarkStates

const ListOrArray = Union{List, Array}

function makeenv(ass=Dict(), modules=[])
    Env = Module(gensym(:Env))
    Core.eval(Env, quote
        using Compat
        using Base.Iterators
        using SExpressions.Lists
        using SExpressions.Keywords
        using SchemeSyntax
        using SchemeSyntax.RacketExtensions
        using SchemeSyntax.R5RS
        using Remarkable.Remark.StdLib
    end)
    for (k, v) in ass
        Core.eval(Env, :(const $k = $v))
    end
    for touse in modules
        Core.eval(Env, :(const $(nameof(touse)) = $touse))
        Core.eval(Env, :(using .$(nameof(touse))))
    end
    Env
end


setindex(x, y, z) = assoc(x, z, y)

"""
Return `true` if `α` is a list, and each element in `α` is a list.
"""
islisty(α::List) = all(β -> isa(β, List), α)
islisty(_) = false

"""
Monad-ish: thread second argument through successive calls of `f` to elements
of `xs`.
"""
function acc2(f, xs, acc)
    res = []
    for x in xs
        r, acc = f(x, acc)
        push!(res, r)
    end
    res, acc
end

function handleinclude(obj, kind::Keyword, state)
    if kind == Keyword("remark")
        url = evaluate!(state, obj)
        file = relativeto(state, url)
        α = Parser.parsefile(file)
        acc2(tohiccup, α, state)
    else
        error("Unknown included object type $state")
    end
end

function handleinclude(ρ, state)
    if length(ρ) ≠ 2
        error("include must take exactly two arguments")
    end
    handleinclude(car(ρ), cadr(ρ), state)
end

function handleremark(ρ, state)
    if isempty(ρ)
        error("remark requires a nonempty body expression")
    end
    StdLib.setstate!(state)
    tohiccup(evaluateall!(state, ρ), state)
end

function handleremarks(ρ, state)
    if isempty(ρ)
        error("remarks requires a nonempty body expression")
    end
    StdLib.setstate!(state)
    result = evaluateall!(state, ρ)
    if result === nothing
        nothing, state
    else
        acc2(tohiccup, result, state)
    end
end

flattentree(::Nothing) = DOM.Node[]
flattentree(xs::ListOrArray)::Vector{DOM.Node} =
    vcat((flattentree(x) for x in xs)...)
flattentree(x) = DOM.Node[x]

function gethiccupnode(head, ρ, state)
    error("Invalid HTSX head: $head")
end

function gethiccupnode(head::Symbol, ρ, state)
    if head == :include
        handleinclude(ρ, state)
    elseif head == :remark
        handleremark(ρ, state)
    elseif head == :remarks
        handleremarks(ρ, state)
    elseif isnil(ρ)
        DOM.Node(head, DOM.Attributes(undef, 0), DOM.Node[]), state
    else
        if islisty(car(ρ))  # is a list of attrs
            attrs = [car(β) => string(evaluate!(state, cadr(β)))
                     for β in car(ρ)]
            content, state = acc2(tohiccup, cdr(ρ), state)
        else  # is just another body element
            attrs = DOM.Attributes(undef, 0)
            content, state = acc2(tohiccup, ρ, state)
        end
        children = flattentree(content)
        DOM.Node(head, attrs, collect(DOM.Node, children)), state
    end
end

quoted(x) = list(:quote, x)
function gethiccupnode(head::Keyword, ρ, state)
    if head == Keyword("template")
        Base.depwarn("#:template is deprecated, use (remark) instead", :template)
        tohiccup(evaluate!(state, cons(car(ρ), quoted ⊚ cdr(ρ))), state)
    elseif head == Keyword("each")
        var, array, code = ρ
        doms = Core.eval(state.env, quote
            [$(tojulia(code)) for $var in $(tojulia(array))]
        end)
        objects = []
        for dom in doms
            res, state = acc2(tohiccup, dom, state)
            push!(objects, res)
        end
        objects, state
    else
        error("Unsupported HTSX keyword $head")
    end
end

tohiccup(::Nil, state) = error("Empty list not allowed here")
function tohiccup(α::Cons, state)
    head = car(α)
    gethiccupnode(head, cdr(α), state)
end

tohiccup(s::String, state) = DOM.Node(s), state
tohiccup(s::AbstractString, state) = tohiccup(String(s), state)
tohiccup(s::SemanticText, state) = tohiccup(string(s), state)
tohiccup(i::Number, state) = tohiccup(string(i), state)
tohiccup(::Nothing, state) = nothing, state

tohiccup(x, state) = error("Can’t serialize $(repr(x))")

function show_html(io::IO, ashiccup)
    join(io, (stringmime("text/html", p) for p in ashiccup))
end

function tohtml(io::IO, α::List, tmpls=PersistentHashMap{Symbol,Any}();
                file=joinpath(pwd(), "_implicit.rem"),
                modules=[])
    println(io, "<!DOCTYPE html>")
    state = RemarkState(makeenv(tmpls, modules), file)
    ashiccup, _ = acc2(tohiccup, α, state)
    show_html(io, flattentree(ashiccup))
end

function tohtml(io::IO, f::AbstractString,
                tmpls=PersistentHashMap{Symbol,Any}();
                modules=[])
    tohtml(io, Parser.parsefile(f), tmpls; file=abspath(f), modules=modules)
end

tohtml(α::Union{List,AbstractString}, tmpls=PersistentHashMap{Symbol,Any}()) =
    sprint(tohtml, α, tmpls)

end
