using Remarkable.Articles
using Remarkable.Tags

@testset "Live Performance" begin
    tagmatrix = TagMatrix()

    metadata = ArticleMetadata("foo",
                               "The Astronomical Canon",
                               ["Hypatia of Alexandria"],
                               DateTime(350, 1, 1, 12, 0, 0))
    object = LivePerformance(metadata, "Alexandria")

    @test location(object) == "Alexandria"
    @test authors(object) == ["Hypatia of Alexandria"]
    @test title(object) == "The Astronomical Canon"

    tag!(object, tagmatrix, ["math"])

    @test tags(object) == [tagobject(tagmatrix, "math")]
    @test collect(tags(tagmatrix)) == tags(object)
    @test Tags.popularity(tagmatrix, "math") == 1
end
