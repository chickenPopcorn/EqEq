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

Most helpful is the table shown in [TODO add link to whiteboard of nam's]()

```c
for CTX'
  for EQ' = { ID', ASSGN, EXPR' } // note: only ASSIGN exprs exist
    if EXPR' contains IDs
      sast.get(CTX').deps.add(ID', getListOfIdsFromExpr(EXPR'))
    else
      sast.get(CTX').indeps.add(ID', EXPR')

  FIND_INDEX = 0
  for FIND' = { CTX', FIND_DECL' }
    NAME = "find_%s_%s_%d" FIND' CTX' FIND_INDEX

    EXPR_INDEX = 0

    FIND_MAP = (sast.get(CTX').deps, sast.get(CTX').indeps)
    EXPR_MAP = <EXPR_INDEX, FIND_MAP>
    sast.get(CTX').FindMap.add(NAME, EXPR_MAP)

    for EXPR'
      EXPR_MAP = sast.get(CTX').FindMap.get(NAME).get(EXPR_INDEX) || EXPR_MAP

      Match EXPR' with:
        | ASSIGN' = { ID', ASSGN, EXPR" } ->
            for ID" in EXPR"
                if ID" is not in FIND_MAP.indeps
                    throw "unresolvable expression"

            if ID' exists in FIND_MAP
              EXPR_MAP = sast.get(CTX').FindMap.get(NAME).add(
                  EXPR_INDEX,
                  copy(EXPR_MAP))

              FIND_MAP.indeps.add(ID', EXPR")
            else
              FIND_MAP.indeps.add(ID', EXPR")
        | _ ->
            for ID' in EXPR'
                throw if ID' unresolvable per FIND_MAP

      ++EXPR_INDEX

    ++FIND_INDEX

```

## Codegen from SAST

```c
for CTX' in AST
  for (EQNAME,DEPS) sast.get(CTX').deps
      C_FUNC_NAME = '%s_eq_%s' CTX' EQNAME
      generate C function called C_FUNC_NAME with params DEPS

FIND_INDEX = 0
for FIND' = {CTX', FIND_TARG} in AST
  FIND_NAME = "find_%s_%d" CTX' FIND_INDEX

  generate C function called FIND_NAME where body is remainder of this for loop:

  EXPR_INDEX = 1 // TODO: fix code above (and here) to use 0-index
  for EXPR' in FIND'
    FIND_MAP = sast.get(CTX').FindMap.get(EXPR_INDEX) || FIND_MAP
    match EXPR' with
      | ASSIGN ->
          {ID', ASSGN, EXPR"} = EXPR'
          for ID' in EXPR"
            if ID' in FIND_DEPS.indeps
              print ID' (in-place) as is
            else
              print ID' (in-place) as a function call with its deps provided
      | _ ->
          for ID' in EXPR'
            if ID' in FIND_DEPS.indeps
              print ID' as is
            else
              print ID' as a function call with its deps provided
    ++EXPR_INDEX

  ++FIND_INDEX
```

### Questions

1. What does the ocaml look like for our SAST struct?
2. What have we not considered for `if`/`else`/`while` statemnets

---

# Whiteboard Photos

TODO: inline whiteboardified photos
