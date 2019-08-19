module Common

using Base.Iterators
using Unicode

export urinormalize

"""
    urinormalize(s::AbstractString)

Normalize `s` in a way expected to be suitable for URIs.
"""
function urinormalize(s::AbstractString)::String
    t = Unicode.normalize(s; compat=true, stripcc=true, rejectna=true,
                             stripignore=true, casefold=true)
    t = replace(t, r"\s" => "-")
    t = filter(c -> isletter(c) || isnumeric(c) || c == '-', t)
    if isempty(t)
        throw(ArgumentError(
            "Argument $(repr(s)) cannot be meaningfully URI-normalized."))
    end
    join(collect(take(t, 30)))
end

end
