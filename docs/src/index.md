# Remarkable.jl

Documentation for Remarkable.jl

## HTML

This package provides a way to write HTML pages using terse s-expression syntax.
This functionality is named Remark. The code:

```racket
(html ([lang "en"])
    (head (title "Hello World!"))
    (body (p "This is my first Remark page.")))
```

turns into

```html
<!DOCTYPE html>
<html lang="en"><head><title>Hello World!</title></head><body><p>This is my first Remark page.</p></body></html>
```

To use Remark, use the `Remarkable.Remark.tohtml` function:

```julia
Remarkable.Remark.tohtml(SExpressions.parses("""
(html ([lang "en"])
    (title "Hello World!")
    (p "This is an example of the " (code "@htsx_str") " string macro."))
""")
```
