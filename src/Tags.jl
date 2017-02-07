"""
Remarkable tagging system.
"""
module Tags

import Base: isless
using Base.Iterators
using AutoHashEquals
using DataStructures

"""
An individual tag object representing a category that objects can be classified
under.
"""
@auto_hash_equals immutable Tag
    name::String
end
tagname(t::Tag) = t.name
isless(t::Tag, u::Tag) = isless(tagname(t), tagname(u))

immutable TagMatrix
    popularity::DefaultDict{Tag,Int,Int}
    correlation::DefaultDict{Tuple{Tag,Tag},Int,Int}
    
    TagMatrix() = new(
        DefaultDict{Tag,Int}(0),
        DefaultDict{Tuple{Tag,Tag}, Int}(0))
end

tag(m::TagMatrix, t::AbstractString) = Tag(t)
tag(::TagMatrix, t::Tag) = t

"""
    tags(m::TagMatrix)

Return an iterable over all tags seen in the TagMatrix `m`.
"""
tags(m::TagMatrix) = keys(m.popularity)

"""
    popularity(m::TagMatrix, t::AbstractString)

Return the popularity of tag `t` in `m`.
"""
popularity(m::TagMatrix, t::Tag) = m.popularity[t]
popularity(m::TagMatrix, t) = popularity(m, tag(m, t))

"""
    popular(m::TagMatrix)

Return a `Vector` of tags, ordered from most popular to least.
"""
popular(m::TagMatrix) = sort(collect(tags(m)), by=t -> -popularity(m, t))

"""
    joint(m::TagMatrix, t1, t2)

Return the total weight of entries which have both `t1` and `t2` as tags.
"""
joint(m::TagMatrix, t1::Tag, t2::Tag) =
    m.correlation[tuple(sort([t1, t2])...)]
joint(m::TagMatrix, t1, t2) = joint(m, tag(m, t1), tag(m, t2))

"""
    relatedto(m::TagMatrix, tag, num=8)

Return up to the top `num` tags related to `tag`.
"""
function relatedto(m::TagMatrix, t::Tag, num=8)
    top = [(tag, joint(m, t, tag)^2 / (popularity(m, tag) + 2))
           for tag in tags(m) if tag != t]
    filter!(x -> x[2] > 0, top)
    sort!(top, by=x -> -x[2])
    take(top, num)
end
relatedto(m::TagMatrix, t, num=8) = relatedto(m, tag(m, t), num)

"""
    issubtag(m::TagMatrix, a, b)

Return `true` if `a` is a subtag of `b`. A tag `a` is defined to be a subtag of
`b` if at least 75% of items tagged with `a`, plus 0.75, are also tagged with
`b`, or if `a == b`.
"""
issubtag(m::TagMatrix, a::Tag, b::Tag) = a == b ||
    joint(m, a, b) >= 0.75 * popularity(m, a) + 0.75
issubtag(m::TagMatrix, a, b) = issubtag(m, tag(m, a), tag(m, b))

"""
    subtags(m::TagMatrix, tag)

Return all subtags of this tag, in order of size.
"""
function subtags(m::TagMatrix, t::Tag)
    result = [tag for tag in tags(m) if tag != t && issubtag(m, tag, t)]
    sort!(result; by=x -> popularity(m, x), rev=true)
    result
end
subtags(m::TagMatrix, t) = subtags(m, tag(m, t))

"""
    populate!(m::TagMatrix, tags, value=1)

Add an entry to the tag matrix, whose tags are given by `tags`, and whose
weight is given by `value`.
"""
function populate!(m::TagMatrix, tags, value=1)
    for str in tags
        a = tag(m, str)
        m.popularity[a] += value
        for str2 in tags
            if str2 > str
                b = tag(m, str2)
                m.correlation[(a, b)] += value
            end
        end
    end
end

immutable TagTree
    root::Tag
    children::Vector{TagTree}
end
root(tr::TagTree) = tr.root
children(tr::TagTree) = tr.children

typealias TagForest Vector{TagTree}

function forest(m::TagMatrix, rset=collect(tags(m)))
    rset = sort(rset; by=x -> popularity(m, x), rev=true)
    result = TagForest()
    while !isempty(rset)
        top = shift!(rset)
        lower = filter(x -> issubtag(m, x, top), rset)
        rset = filter(x -> !issubtag(m, x, top), rset)
        push!(result, TagTree(top, forest(m, lower)))
    end
    result
end

export TagMatrix, joint, relatedto, populate!, popular, subtags, tags, forest,
       root, children

end
