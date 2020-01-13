using SExpressions
using EnglishText

function rem(s::String)
    Remarkable.Remark.tohtml(SExpressions.parseall(s))
end

@testset "Remark" begin

@testset "Just HTML" begin
@test sx"""
(html ([lang "en"])
  (head (title "Hello World!"))
  (body (p "This is my first Remark page")))
""" == SExpression((
        :html, ((:lang, "en"),),
        (:head, (:title, "Hello World!")),
        (:body, (:p, "This is my first Remark page"))))

@test rem("""
(html ([lang "en"])
  (head (title "Page"))
  (body
    (p "This is a poem" (br) "Line 2"
       (button ([disabled]) "disabled button"))))
""") == """
<!DOCTYPE html>
<html lang="en"><head><title>Page</title></head><body><p>This is a poem<br/>Line 2<button disabled>disabled button</button></p></body></html>"""
end

@test rem("""
(remark
  (define (foo-bar x y) (string (+ x y))))
(html ([lang "en"])
  (head (title "Page " (remark (foo-bar 1 1))))
  (body (p "This is page " (remark (foo-bar 1 1)) ".")))
""") == """
<!DOCTYPE html>
<html lang="en"><head><title>Page 2</title></head><body><p>This is page 2.</p></body></html>"""

@test rem("""
(remark
  (define (sqr x) (* x x))
  (define (n^4 x) (* (sqr x) (sqr x)))
  (define (test x) (string (n^4 x))))
(html ([lang "en"])
  (title (remark (test 10)))
  (p "test"))
""") == """
<!DOCTYPE html>
<html lang="en"><title>10000</title><p>test</p></html>"""

@testset "When" begin
@test rem("""
(remark (when (defined? x)
               `(p "yes 1")))
(remark (define (x y) y))
(remark (when (defined? x)
              `(p "yes 2")))
""") == """
<!DOCTYPE html>
<p>yes 2</p>"""

@test rem("""
(p (remark (when (< 1 2) (define x 1) (+ x x))))
""") == """
<!DOCTYPE html>
<p>2</p>"""

@test rem("""
(p (remark (when (> 1 2) "Hello")))
""") == """
<!DOCTYPE html>
<p></p>"""
end

@testset "Remark" begin
@test rem("""
(remark
  (define x "Hello, World"))
(p (remark (string x "!")))
""") == """
<!DOCTYPE html>
<p>Hello, World!</p>"""

@test rem("""
(remark
  (define x "Hello, ")
  (define y "World"))
(p (remark (string x y "!")))
""") == """
<!DOCTYPE html>
<p>Hello, World!</p>"""

@test rem("""
(remark (define (foo x) 0))
(p (remark (foo 1)))
""") == """
<!DOCTYPE html>
<p>0</p>"""

sprint() do io
    Remarkable.Remark.tohtml(io, SExpressions.parseall("""
    (p (remark (ItemList "x" "y")))
    """); modules=[EnglishText])
end == """
<!DOCTYPE html>
<p>x and y</p>"""
end

@testset "Remarks" begin
@test rem("""
(remarks
 (define n 7000000000)
 `((p "Hello World")
   (p "All " ,n " are welcome!")))
""") == """
<!DOCTYPE html>
<p>Hello World</p><p>All 7000000000 are welcome!</p>"""
end

@test Remarkable.Remark.tohtml("data/file1.rem") == """
<!DOCTYPE html>
<p>File 2: 100</p><p>File 1: 20</p>"""

@test Remarkable.Remark.tohtml("data/test-dispatch.rem") == """
<!DOCTYPE html>
<p>12</p>"""

@test Remarkable.Remark.tohtml("data/test-markdown.rem") == """
<!DOCTYPE html>
<h1>Some Markdown</h1><p><strong>Test</strong>.</p>"""

@testset "Each" begin
@test rem("""
(#:each x (List "x" "y" "z")
  `((p ,x)))
""") == """
<!DOCTYPE html>
<p>x</p><p>y</p><p>z</p>"""
end

@testset "Files" begin
@test Remarkable.Remark.tohtml("data/literal-test.rem") == """
<!DOCTYPE html>
<script>alert(\"Hello, World!\");
</script>"""
end

@testset "Markdown Render" begin
@test Remarkable.Remark.tohtml("data/markdown-render.rem") == """
<!DOCTYPE html>
<p>my <a href="http://example.com">link to</a></p>"""
end

@testset "Object Include" begin
@test Remarkable.Remark.tohtml("data/object-include.rem") == """
<!DOCTYPE html>
<p>Hello, World!</p>"""
end

@testset "Attributes" begin
    @test rem("""
(html ([lang "en"])
  (body (textarea ([cols 10]))))
""") == """
<!DOCTYPE html>
<html lang="en"><body><textarea cols="10"></textarea></body></html>"""
end

end
