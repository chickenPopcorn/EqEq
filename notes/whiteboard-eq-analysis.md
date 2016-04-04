# Brainstorm Whiteboarding & Notes

Below we describe the API between semantic analysis and codegen of equations
_(with dependencies full features allowed in our LRM, ie: dependencies)_.

Note "SAST" below refers to Edwards' "semanticly-annotated"-AST _(ie: whatever
our semantic analysis outputs for codegen's use)_.

## EqualsEquals Demonstration

```js
FooCtx = { y = mx + 3; }

FooCtx:find {
  m = 3; x = 4;  // expresions 1 and 2
  print(y);      // expresion  3
  y = 8;         // expresion  4
  print(y);      // expresion  5
}

FooCtx:find { print(99); }
```

## Semantic Analysis

### SAST API Exposed to Codegen
Our SAST makes repeated use of a `(deps, indeps)` tuple where `deps` is a map
describing dependent equations and `indeps` is a map describing independent
equations.

For a snippet `a = b + c + 3;` a `deps` entry might look like:
```c
"a" : ["b"; "c"]
```

For a snippet `y = 4;` an `indeps` entry might look like:
```c
"y" : Ast.Expr(Ast.Lit(4))
```

The output of our algorithm _(below)_ will be a map keyed by context name (eg:
the string `FooCtx`), where values are tuples with three items:
  1. `deps` built for `FooCtx` _(described above)_
  2. `indeps` built for `FooCtx` _(described above)_
  3. "FindMap": a map specific to `FootCtx`, described below.

"FindMap" is a map of our analsys of each `Ast.find_decl` for a given context.
The keys of a "FindMap" map are the relative expression index in said
`find_decl` where value is `(deps, indeps)` as inherited and modified up to that
particular expression in the find block. This is the key design choice that
allows users to reassign symbols previously representing equations in a context
_(eg: "expression 4" in our main example doesn't interfere with "expression
3")_.

### Algorithm in Pseudocode

TODO: explain

## Codegen from SAST

TODO: explain

### Questions

1. What does the ocaml look like for our SAST struct?
2. What have we not considered for `if`/`else`/`while` statemnets

---

# Whiteboard Photos

TODO: inline whiteboardified photos
