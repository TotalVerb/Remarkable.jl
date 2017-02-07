module Common

using Base.Iterators

export urinormalize

"""
    urinormalize(s::AbstractString)

Normalize `s` in a way expected to be suitable for URIs.
"""
function urinormalize(s::AbstractString)::String
    t = normalize_string(s;
                         compat=true, stripcc=true, rejectna=true,
                         stripignore=true, casefold=true)
    t = replace(t, r"\s", "-")
    t = filter(c -> isalnum(c) || c == '-', t)
    if isempty(t)
        throw(ArgumentError(
            "Argument $(repr(s)) cannot be meaningfully URI-normalized."))
    end
    join(collect(take(t, 30)))
end

end
