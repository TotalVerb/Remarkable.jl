module Remark

using SExpressions.Parser
using SExpressions.Lists
using SExpressions.Keywords
using SchemeSyntax
using Compat
using Hiccup
using FunctionalCollections: PersistentHashMap

include("stdlib.jl")

const ListOrArray = Union{List, Array}

function makeenv(ass=Dict(), modules=[])
    Env = Module(gensym(:Env))
    eval(Env, quote
        using Compat
        using Base.Iterators
        using SExpressions.Lists
        using SExpressions.Keywords
        using SchemeSyntax
        using SchemeSyntax.RacketExtensions
        using SchemeSyntax.R5RS
        import Remarkable.Remark.StdLib
    end)
    for (k, v) in ass
        eval(Env, :($k = $v))
    end
    for touse in modules
        eval(Env, :(const $(module_name(touse)) = $touse))
        eval(Env, :(using .$(module_name(touse))))
    end
    Env
end

struct RemarkState
    env::Module
    file::String
end
getvar(s::RemarkState, v::Symbol) = getfield(s.env, v)
evaluate!(s::RemarkState, ex) = eval(s.env, tojulia(ex))
function evaluateall!(state, ρ)
    local data
    for α in ρ
        data = evaluate!(state, α)
    end
    data
end
relativeto(s::RemarkState, f) = joinpath(dirname(s.file), f)

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
    if kind == Keyword("object")
        data = evaluate!(state, obj)
        tohiccup(data, state)
    elseif kind == Keyword("markdown")
        url = evaluate!(state, obj)
        file = relativeto(state, url)
        data = StdLib.rendermd(readstring(file))
        tohiccup(data, state)
    elseif kind == Keyword("remark")
        url = evaluate!(state, obj)
        file = relativeto(state, url)
        α = Parser.parsefile(file)
        acc2(tohiccup, α, state)
    elseif kind == Keyword("text")
        url = evaluate!(state, obj)
        file = relativeto(state, url)
        readstring(file), state
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
    tohiccup(evaluateall!(state, ρ), state)
end

function handleremarks(ρ, state)
    if isempty(ρ)
        error("remarks requires a nonempty body expression")
    end
    acc2(tohiccup, evaluateall!(state, ρ), state)
end

flattentree(::Void) = []
flattentree(xs::ListOrArray) = vcat((flattentree(x) for x in xs)...)
flattentree(x) = Any[x]

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
        Node(head, Dict(), []), state
    else
        if islisty(car(ρ))  # is a list of attrs
            attrs = Dict(car(β) => cadr(β) for β in car(ρ))
            content, state = acc2(tohiccup, cdr(ρ), state)
        else  # is just another body element
            attrs = Dict()
            content, state = acc2(tohiccup, ρ, state)
        end
        children = flattentree(content)
        Node(head, attrs, children), state
    end
end

quoted(x) = list(:quote, x)
function gethiccupnode(head::Keyword, ρ, state)
    if head == Keyword("template")
        tohiccup(evaluate!(state, cons(car(ρ), quoted ⊚ cdr(ρ))), state)
    elseif head == Keyword("when")
        cond = car(ρ)
        if evaluate!(state, cond)
            acc2(tohiccup, cdr(ρ), state)
        else
            nothing, state
        end
    elseif head == Keyword("each")
        var, array, code = ρ
        doms = eval(state.env, quote
            map($(tojulia(array))) do $var
                $(tojulia(code))
            end
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

function tohiccup(α::List, state)
    len = length(α)
    if len < 1
        error("Empty list not allowed here")
    else
        head = car(α)
        gethiccupnode(head, cdr(α), state)
    end
end

tohiccup(s::String, state) = s, state
tohiccup(s::AbstractString, state) = tohiccup(String(s), state)
tohiccup(i::BigInt, state) = string(i), state
tohiccup(::Void, state) = nothing, state

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
