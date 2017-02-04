using Remarkable
using Base.Test

using Remarkable.Tags

# write your own tests here
@testset "Tags" begin
    m = TagMatrix()

    # populate with a single item
    populate!(m, ["car", "vehicle"])
    @test Set(tags(m)) == Set(["car", "vehicle"])

    # populate with an item of higher weight
    populate!(m, ["bicycle", "vehicle"], 2)
    @test Set(tags(m)) == Set(["car", "bicycle", "vehicle"])
    @test Tags.popularity(m, "bicycle") == 2
    @test Tags.popularity(m, "vehicle") == 3
    @test popular(m) == ["vehicle", "bicycle", "car"]

    populate!(m, ["segway", "vehicle", "electric"])
    populate!(m, ["computer", "electric"])
    populate!(m, ["food", "toaster", "electric"])
    populate!(m, ["food", "fruit", "tomato"])
    populate!(m, ["vehicle", "car", "electric-car", "electric"])
    populate!(m, ["vehicle", "car", "gasoline"])
    f = forest(m)
    @test root(f[1]) == "vehicle"
    @test root(children(f[1])[1]) == "car"
end
