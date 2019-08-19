"""
Remarkable tagging system.
"""
module Tags

import Base: isless
using Base.Iterators
using AutoHashEquals
using DataStructures
using Distances
using Unicode
using ..Common

"""
An individual tag object representing a category that objects can be classified
under.
"""
@auto_hash_equals struct Tag
    name::String
end

"""
    tagname(::Tag)

Return the canonical, user-friendly name of this tag.
"""
tagname(t::Tag) = t.name
isless(t::Tag, u::Tag) = isless(tagname(t), tagname(u))

struct TagMatrix
    popularity::DefaultDict{Tag,Int,Int}
    correlation::DefaultDict{Tuple{Tag,Tag},Int,Int}
    uritable::Dict{String,Tag}

    TagMatrix() = new(
        DefaultDict{Tag,Int}(0),
        DefaultDict{Tuple{Tag,Tag}, Int}(0),
        Dict{String,Tag}())
end

"""
    tagobject(m::TagMatrix, t::AbstractString)

Obtain the `Tag` object corresponding to `t` from matrix `m`.
"""
function tagobject(m::TagMatrix, t::AbstractString)
    # Normalize the display name of the tag
    t = Unicode.normalize(t, :NFKC)

    # Normalize the tag name further to a URI-suitable variant
    uri = urinormalize(t)
    if haskey(m.uritable, uri)
        candidate = m.uritable[uri]
        if tagname(candidate) == t
            candidate
        else
            error("Cannot retrieve tag $(repr(t)) because it conflicts with tag $(candidate)")
        end
    else
        m.uritable[uri] = Tag(t)
    end
end
tagobject(::TagMatrix, t::Tag) = t

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
popularity(m::TagMatrix, t) = popularity(m, tagobject(m, t))

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
joint(m::TagMatrix, t1, t2) = joint(m, tagobject(m, t1), tagobject(m, t2))


"""
    distance(m::TagMatrix, dist::SemiMetric, t::Tag, u::Tag)

Compute the total distance between tags `t` and `u` using the given metric.
Allowed metrics are Jaccard() and CosineDist() (which reduces to Ochiai
coefficient).
"""
function distance(m::TagMatrix, ::Jaccard, t::Tag, u::Tag)
    num = joint(m, t, u)
    den = popularity(m, t) + popularity(m, u) - num
    return 1.0 - num / den
end

function distance(m::TagMatrix, ::CosineDist, t::Tag, u::Tag)
    num = joint(m, t, u)
    den = √popularity(m, t) * √popularity(m, u)
    return 1.0 - num / den
end

"""
    relatedto(m::TagMatrix, tag, num=8)

Return up to the top `num` tags related to `tag`.
"""
function relatedto(m::TagMatrix, t::Tag, num=8)
    top = [(tag, distance(m, Jaccard(), t, tag))
           for tag in tags(m) if tag != t]
    filter!(x -> x[2] < 1, top)
    sort!(top, by=x -> x[2])
    take(top, num)
end
relatedto(m::TagMatrix, t, num=8) = relatedto(m, tagobject(m, t), num)

"""
    issubtag(m::TagMatrix, a, b)

Return `true` if `a` is a subtag of `b`. A tag `a` is defined to be a subtag of
`b` if at least 75% of items tagged with `a`, plus 0.75, are also tagged with
`b`, or if `a == b`.
"""
issubtag(m::TagMatrix, a::Tag, b::Tag) = a == b ||
    joint(m, a, b) >= 0.75 * popularity(m, a) + 0.75
issubtag(m::TagMatrix, a, b) = issubtag(m, tagobject(m, a), tagobject(m, b))

"""
    subtags(m::TagMatrix, tag)

Return all subtags of this tag, in order of size.
"""
function subtags(m::TagMatrix, t::Tag)
    result = [tag for tag in tags(m) if tag != t && issubtag(m, tag, t)]
    sort!(result; by=x -> popularity(m, x), rev=true)
    result
end
subtags(m::TagMatrix, t) = subtags(m, tagobject(m, t))

"""
    populate!(m::TagMatrix, tags, value=1)

Add an entry to the tag matrix, whose tags are given by `tags`, and whose
weight is given by `value`.
"""
function populate!(m::TagMatrix, tags::Vector{Tag}, value=1)
    for a in tags
        m.popularity[a] += value
        for b in tags
            if b > a
                m.correlation[(a, b)] += value
            end
        end
    end
end
populate!(m::TagMatrix, tags, value=1) =
    populate!(m, [tagobject(m, t) for t in tags], value)

struct TagTree
    root::Tag
    children::Vector{TagTree}
end
root(tr::TagTree) = tr.root
children(tr::TagTree) = tr.children

const TagForest = Vector{TagTree}

function forest(m::TagMatrix, rset=collect(tags(m)))
    rset = sort(rset; by=x -> popularity(m, x), rev=true)
    result = TagForest()
    while !isempty(rset)
        top = popfirst!(rset)
        lower = filter(x -> issubtag(m, x, top), rset)
        rset = filter(x -> !issubtag(m, x, top), rset)
        push!(result, TagTree(top, forest(m, lower)))
    end
    result
end

function tag! end

export TagMatrix, joint, relatedto, populate!, popular, subtags, tags, forest,
       root, children, tagname, Tag, tagobject, tag!

end
