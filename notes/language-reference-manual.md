# `EqualsEquals` Language Reference Manual (LRM)

## Compiler Phases

### Phase 1 of 5: Scanning with `lex`

#### What *Is* An `EqualsEquals` Program?
A valid program is a series of 1 or more `find` expressions. A `find` expression
is authored with a particular "context" (aka "scope") in mind, by default the
global scope. Other than the global scope, a context is a block of curly brace
enclosed code that defines explicit mathematical equations and functions _(or
multi-line equations)_.

An important feature of `EqualsEquals` is that context need not make equations
explicit _(that is, an equation can have multiple unknowns)_ until its
convenient, at the time a `find` block is written. An example of a `find` block
executed on the user-defined `Euclid` context _(where `gcd` is defined as a
multi-line function, or equation)_:
```c
Euclid = { /*... gcd defined here ...*/ }
Euclid:find gcd {
  a = 20; b = 10; print("%d\n", gcd);
}
```

Otherwise, a valid program may also include:

1. **variables** and their assignment operations

 + **vectors**, like variables, but have a `<>` after their identifier, eg: `myVector<>`

2. **arithmetic** expressions: addition, subtraction, multiplication, division;
3. **comments** characters ignored by the compiler
4. **whitespace** to arbitrary length (eg: `a = 3` is the same as `a   = 3`)
5. **strings** used for printing
6. **equality** operators _(which evaluate to `1` or `0` if both operators are equal)_


#### Keywords (Reserved words)
+ `if`
+ `elif`
+ `else`
+ `return`
+ `find`
+ `function`
+ `print`
+ `with`
+ `in`
+ `range`

#### Lexemes/Tokens
1. Floating point numbers, including integers:

  eg: `123`, `1.34e-4`, `0.23`, `.13`, `0e1`.

  Regular expression might be:
  ```ocaml
  let pos = ['1' - '9']                    in
  let dig = '0' | pos                      in
  let exp = ('e' | 'E') ('-' | '+')? pos+  in
  let fra = '.' dig+ exp?                  in
  let num = pos dig*                       in

  let flt = num | ((num | 0)? frac) | (num exp)
  ```
2. Variables: numbes stored with user-defined nams:

  eg: `weight = 100 /*grams*/`

  Regular expression might be:
  ```ocaml
  let aph = ['a'-'z'] | ['A'-'Z']     in

  let var = aph+ ('_' | ['0'-'9'])*
  ```

3. Contexts: blocks of symbols:

  eg: `Euclid: {/* any number of lines of EqualsEquals here */}`

  Regular Expression might be _(builds on variables' expressions)_:
  ```ocaml
  let aph = ['a'-'z'] | ['A'-'Z']     in

  let ctx = ['A'-'Z'] var ':'

  (*note: starts with uppercase letter, ends with ':'*)
  ```

4. Strings: mostly used for printing, results:

  eg: `printf("result of my maths: %d\n", gcd)`

  TODO: double check these regexp. from http://caml.infria.fr/pub/docs/manual-ocaml/lex.html
  TODO: should lexeme include quotes or is that in this regexp?

  Regular Expression might be _(builds on variables' expressions)_:
  ```ocaml
  let chr = \x(0...9|A...F|a...f)(0...9|A...F|a...f) in
  let spc = \(\| "| '| n| t| b| r| space)
  let num = ['0' - '9']                   in 
  let aph = ['a' - 'z'] | ['A' - 'Z']     in

  let str = (aph | num | chr | spc)*
  ```
#### Expressions
  Expressions are groups of lexemes/tokens (defined above), parenthesized `(` and `)` sub-expressions,
  and combinations of expressions and operators:

Each operator's meaning is defined below:
  TODO someone have a blast! page 3+ of C LRM

Order of precedence of expressinos is:
 + ( exp )
 + expr[expr?]
 + - expr
 +  !exp
 +  exp ^ exp // TODO: is this possible to do in our lang, or do we `C's math.h sqrt(...)`?
 +  exp * exp
 +  exp / exp
 + exp % exp
 + expr + expr
 + expr - expr
 + exp > exp
 + exp >= exp
 + exp < exp
 + exp <= exp
 + exp != exp
 + exp == exp
 + exp && exp
 + expr || expr
 + expr = expr







### Phase 2 of 4: Parser with `yacc`
TODO!

### Phase 3 of 4: Static Semantic Analysis
TODO!

### Phase 4 of 4: Code Generation
TODO!