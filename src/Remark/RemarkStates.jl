module RemarkStates

using SchemeSyntax

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

export RemarkState, relativeto, getvar, evaluate!, evaluateall!

end
