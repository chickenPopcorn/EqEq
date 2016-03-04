# `EqualsEquals` Language Reference Manual (LRM)

TODO:s
- TODO(jon): review TODOs with TA/edwards (email Daniel)
- TODO(jon): move LRM google doc into this doc
  - refactor headers to look like (C LRM)[https://www.bell-labs.com/usr/dmr/www/cman.pdf]
  - expand missing pieces
- TODO(tianci): "declarations" section: "explain *how* users declare each thing
    in our language (functions, variables, equations - like things should be
    single-variable on left-side)
- TODO(nam): address 'Keyword Meanings" TODO
- TODO(jimmy): cleanup/collapse/whatever 'Keyword Meanings" precedence
- TODO(jimmy): address 'Reserved Keywords" TODO
- as group: start scanner.mll based on "Keywords & Expressions" sectinos
    - update this doc based on what works

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

 + **vectors**, like variables, but have a `[]` after their identifier, eg: `myVector[]`

2. **arithmetic** expressions: addition, subtraction, multiplication, division;
3. **comments** characters ignored by the compiler
4. **whitespace** to arbitrary length (eg: `a = 3` is the same as `a   = 3`)
5. **strings** used for printing
6. **equality** operators _(which evaluate to `1` or `0` if both operators are equal)_


#### Reserved Keywords
TODO: explain each
+ `if`
+ `elif`
+ `else`
+ `return`
+ `MyContext:find` and `find`
  Means the following curly-brace enclosed set of statements should be evaluated
  with access to previously declared expressions in an associated "context".
  + `with` optionally specifies any missing identifiers in given context.
      eg: with simple assignment
      ```c
      pendulum: find vector with length = 5 {...}
      ```

      eg:  with vector assignment (causing equiv. of `for` loop in other langs)
      ```c
      pendulum: find vector with length = range(0, 20) {
      ```
+ `function` keyword used to indicate define multi-line equations.

    An identifier followed by the assignment of a `function` keyword indicates
    the remaining expressions will be:
    1. a list of zero or more formal parameters
    2. set of curly brace enclosed statements definiting the equation
    eg:
    ```c
    range = function() {/* definition */}
    ```
+ `print` built-in function that mirrors the C printf API, eg:
    ```
    printf("words here %f.0 and %f here\n", 4, myvar)
    // words here 4 and 3.14159 here
    ```
    Note: we have a subset of the identifier C's printf has, as we only
    use floats.
+ `for` // TODO: not sure yet, decide on this:
+ `range`
    TODO: define this as builtin or stdlib, like this:
    ```c
    range = function(from, to) {
      return range(from, to, vec[to-from], 0);
    }

    range = function(from, to, vec, counter) {
      vec[counter] = from;
      if (from == to) {
        return;
      }
      return range(from+1, to, vec, counter + 1);
    }
    ```

#### Declarations
1. A list of declarator are separated by comma. Formatted as below:Declarator-list:	declarator, declarator, ?2. Variable:To declare a variable, only name of the variable is needed. The data types of the variables are inheritable. Possible inherited data types: +` int +` double +` String

3. Vector:  ```c
  Vector_name[ ]    // an array of zero  Vector_name[i] =  newValue     // change the ith value of the array
  ```i between the [ ] has to be an integer. 


4. Function:
declaration of function has the format as below: 
  `function_name = function (parameter, parameter, ... ) { }`
5. Equations:
Variable = expression / variableOnly variable will be allowed on the left side of the equal sign. 

6. Scope?
  ```
  scope_name {	  list of equation or list of function  }
  scope_name: find ... {  }
  ```

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

##### Keyword Meanings:
Each operator's meaning is defined below:
- TODO someone have a blast! page 3+ of C LRM

Order of precedence of expressions (`expr`), and their meanings:
 + '(' exp ')'
     eg: `( ...)`
   exp here is evaluated before, at which point the parenthesis themselves lose
   their meaning. eg:
   ```
   b * (4 + 5)
   b * 9 // same
   ```
 + `id'['expr?']'`           // TODO: maybe in scanner?
 + `-expr`
 + `!exp`   // eg: `if ((!(a % b))+2)) == (a % !b + 2)`
 + `exp ^ exp` // TODO: is this possible to do in our lang, or do we `C's math.h sqrt(...)`?
 + `exp * exp`, `exp / exp`, `exp % exp`
 + `expr + expr`, `expr - expr`
 + equality/inequality:
   + `exp > exp`, `exp >= exp`, `exp < exp`, `exp <= exp`
     `exp != exp`, `exp == exp`
 + exp && exp
 + expr || expr
 + expr = expr

### Phase 2 of 4: Parser with `yacc`
TODO!

### Phase 3 of 4: Static Semantic Analysis
TODO!

### Phase 4 of 4: Code Generation
TODO!
