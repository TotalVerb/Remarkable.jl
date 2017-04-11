module Articles

export Article, ArticleMetadata, title, tags, identifier, location,
       datetime, authors, LivePerformance

using ..Tags: Tag, TagMatrix, populate!, tagobject
import ..Tags: tags, tag!

"""
Common data across all kinds of articles.
"""
struct ArticleMetadata
    "A unique, machine-friendly identifier for the media."
    identifier :: String

    "A friendly human-readable name describing the media."
    title      :: String

    "A list of tags describing the media."
    tags       :: Vector{Tag}

    "Personnel involved in the production of the media."
    authors    :: Vector{String}

    "A time indicating when the event took place."
    datetime   :: DateTime

    ArticleMetadata(identifier, title, authors, datetime) =
        new(identifier, title, Tag[], authors, datetime)
end
identifier(m::ArticleMetadata) = m.identifier
title(m::ArticleMetadata) = m.title
tags(m::ArticleMetadata) = m.tags
authors(m::ArticleMetadata) = m.authors
datetime(m::ArticleMetadata) = m.datetime
function tag!(m::ArticleMetadata, tm::TagMatrix, ts)
    tos = tagobject.(tm, ts)
    append!(m.tags, tos)
    populate!(tm, tos)
end

"""
A particular item of publication.
"""
abstract type Article end
identifier(x::Article) = identifier(metadata(x))
title(x::Article) = title(metadata(x))
tags(x::Article) = tags(metadata(x))
authors(x::Article) = authors(metadata(x))
datetime(x::Article) = datetime(metadata(x))
tag!(x::Article, tm, t) = tag!(metadata(x), tm, t)

"""
A summary or transcript of a live performance.
"""
struct LivePerformance <: Article
    metadata   :: ArticleMetadata
    "Where the physical event took place."
    location   :: String
end
metadata(x::LivePerformance) = x.metadata
location(x::LivePerformance) = x.location

end
