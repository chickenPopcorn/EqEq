# Brainstorm White-boarding & Notes

Below we describe the API between semantic analysis and codegen of equations
_(with dependencies full features allowed in our LRM, ie: dependencies)_.

Note "SAST" below refers to Edwards' "semantically-annotated"-AST _(ie: whatever
our semantic analysis outputs for codegen's use)_.

  - [EqualsEquals Demonstration](#equalsequals-demonstration)
  - [Semantic Analysis](#semantic-analysis)
    - [SAST API Exposed to Codegen](#sast-api-exposed-to-codegen)
    - [Algorithm in Pseudocode](#algorithm-in-pseudocode)
  - [Codegen from SAST](#codegen-from-sast)
    - [Questions](#questions)

---

## EqualsEquals Demonstration

Examples below may make note of this EqualsEquals example:
```c
FooCtx = {
  y = m * x + 3;
  w = 2;
}

FooCtx:find {
  m = 3; x = 4;  // expressions 1 and 2
  print(y);      // expression  3
  y = 8;         // expression  4
  print(y);      // expression  5
}

FooCtx:find { print(99); }
```

Such an EqualsEquals program would generate the SAST, described below, _(written
as JSON for convenience here)_:
```js
{
  "FooCtx": [
    { "y": ["m", "x"] },
    { "w": Ast.Expr(Ast.Lit(2)) },
    {
      "find_FooCtx_0": {
        1: [
          { "y": ["m", "x"] },
          {
            "w": Ast.Expr(Ast.Lit(2)),
            "m": Ast.Expr(Ast.Lit(3)),
            "x": Ast.Expr(Ast.Lit(4))
          },
        ]
        4: [
          { },
          {
            "w": Ast.Expr(Ast.Lit(2)),
            "m": Ast.Expr(Ast.Lit(3)),
            "x": Ast.Expr(Ast.Lit(4)),
            "y": Ast.Expr(Ast.Lit(8))
          },
        ]
      },
      "find_FooCtx_1": [
        { "y": ["m", "x"] },
        { "w": Ast.Expr(Ast.Lit(2)) }
      ]
    }
  ]
}
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

"FindMap" is a map of our analysis of each `Ast.find_decl` for a given context.
The keys of a "FindMap" map are the relative expression index in said
`find_decl` where value is `(deps, indeps)` as inherited and modified up to that
particular expression in the find block. This is the key design choice that
allows users to reassign symbols previously representing equations in a context
_(eg: "expression 4" in our main example doesn't interfere with "expression
3")_.

### Algorithm in Pseudocode

```c
for CTX'
  for EQ' = { ID', ASSGN, EXPR' } // note: only ASSIGN exprs exist
    if EXPR' contains IDs
      sast.get(CTX').deps.add(ID', getListOfIdsFromExpr(EXPR'))
    else
      sast.get(CTX').indeps.add(ID', EXPR')

FIND_INDEX = 0
for FIND' = { CTX', FIND_DECL' }
  NAME = "find_%s_%d" CTX' FIND_INDEX

  EXPR_INDEX = 0

  FIND_MAP = (sast.get(CTX').deps, sast.get(CTX').indeps)
  EXPR_MAP = <EXPR_INDEX, FIND_MAP>
  sast.get(CTX').FindMap.add(NAME, EXPR_MAP)

  for STMT' in FIND_DECL'
    for EXPR' in STMT'
      EXPR_MAP = sast.get(CTX').FindMap.get(NAME).get(EXPR_INDEX) || EXPR_MAP

      Match EXPR' with:
        | ASSIGN' = { ID', ASSGN, EXPR" } ->
            // NOTE: edge-caes below, not described in this pseudo-code

            for ID" in EXPR"
                if ID" is not in FIND_MAP.indeps
                    throw "unresolvable expression"

            if ID' exists in FIND_MAP
              EXPR_MAP = sast.get(CTX').FindMap.get(NAME).add(
                  EXPR_INDEX,
                  copy(EXPR_MAP))

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
 - will 430dbdf7f02965f work?
2. What have we not considered for `if`/`else`/`while` statements
