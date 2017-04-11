using Remarkable
using Base.Test
using Distances

using Remarkable.Common
@testset "Common" begin
    @test urinormalize("Hello, World!") == "hello-world"
    @test urinormalize("p-adic numbers") == "p-adic-numbers"
    @test urinormalize("München") == "münchen"
    @test urinormalize("Weierstraß M-test") == "weierstrass-m-test"
end

using Remarkable.Tags

@testset "Tags" begin
    m = TagMatrix()

    # populate with a single item
    populate!(m, ["car", "vehicle"])
    @test map(tagname, Set(tags(m))) == Set(["car", "vehicle"])

    # populate with an item of higher weight
    populate!(m, ["bicycle", "vehicle"], 2)
    @test map(tagname, Set(tags(m))) == Set(["car", "bicycle", "vehicle"])
    @test Tags.popularity(m, "bicycle") == 2
    @test Tags.popularity(m, "vehicle") == 3
    @test tagname.(popular(m)) == ["vehicle", "bicycle", "car"]

    populate!(m, ["segway", "vehicle", "electric"])
    populate!(m, ["computer", "electric"])
    populate!(m, ["appliance", "toaster", "electric"])
    populate!(m, ["appliance", "oven", "gas"])
    populate!(m, ["vehicle", "car", "electric-car", "electric"])
    populate!(m, ["vehicle", "car", "gasoline"])
    f = forest(m)
    @test tagname(root(f[1])) == "vehicle"
    @test tagname(root(children(f[1])[1])) == "car"

    @test_throws ErrorException populate!(m, ["CAR", "gasoline"])

    # test similarity metrics
    populate!(m, ["banana", "fruit", "food"])
    populate!(m, ["cabbage", "food"])
    banana = tagobject(m, "banana")
    fruit = tagobject(m, "fruit")
    food = tagobject(m, "food")
    cabbage = tagobject(m, "cabbage")
    @test Tags.distance(m, Jaccard(), banana, fruit) ≈ 0
    @test Tags.distance(m, CosineDist(), banana, fruit) ≈ 0
    @test Tags.distance(m, Jaccard(), banana, food) ≈ 0.5
    @test Tags.distance(m, CosineDist(), banana, food) ≈ 1 - 1/√2
    @test Tags.distance(m, Jaccard(), banana, cabbage) ≈ 1
    @test Tags.distance(m, CosineDist(), banana, cabbage) ≈ 1
end

include("articles.jl")
include("remark.jl")
