<!--
# TODO:s
- [ ] TODO(jon): review TODOs with TA/edwards (email Daniel)
- [ ] TODO(jon): move [LRM google doc](https://goo.gl/VJcW5Z) into this doc
  - refactor headers to look like [C LRM](https://www.bell-labs.com/usr/dmr/www/cman.pdf)
   1. Copy/paste old-LRM's content:
       - [ ] Sample program
   2. refactor *this* LRM's existing content

  - expand missing pieces
- [ ] as group: start scanner.mll based on "Keywords & Expressions" sectinos
    - [ ] update this doc based on what works

-->

# `EqualsEquals` Language Reference Manual

EqualsEquals is a language designed for simple equation evaluation.
EqualsEquals helps express mathematical equation in ASCII without straying too
far from whiteboard-style notation. Users do not need to be overly careful to
perfectly reduce formulas behind. Leaving unknowns for later is possible,
without encapsulating equations's unknowns as function parameters. EqualsEquals
takes multiple equations as input and can evaluate the value of a certain
variables of the equations when the values of other variables are given.

## Motivation

Reducing mathematical formulas can be really painful and tedious. We want to
simplify the process of evaluating equations. With our language we take a step
to help users leave their formula in a similar format to what they'd normally
have on paper.

## Overview

Valid source programs will compile down to
[C](https://www.bell-labs.com/usr/dmr/www/cman.pdf).

### Definition of a Program

The simplest - though contrived - valid program is:
```c
find { printf("Hello, all %.0f readers!\n", 21 * 2); }
```

Which prints the following to standard out:
```
Hello, all 42 readers!
```

Formally, a valid program is a series of:
- one or more `find` blocks.
- zero or more "context" blocks _(aside from the automatic, global context)_

### "Context"s & `find` Blocks

While both types of blocks of code are simply curly brace enclosed listings of
sequential statements, contexts and `find` blocks differ in their use:
- **context**s are expected to layout and define equations for use later.
  Thus they're allowed semantic gaps in their equations; eg: missing solutions.
- `find` blocks on the other hand are expected to be the resolution to "find"
  missing said pieces, or simply apply completed solutions to new inputs.

It follows then that `find` expressions _apply_ to contexts. Where a context
might be shared for re-use, `find` expressions are designed to make local use of
equations in a given context.

Though the above "Hello World" example executes a `find` on the global context,
users will generally define contexts manually. For example a "Euclid" context,
where `gcd` might be defined:
```c
Euclid = { gcd = /*... defined here ...*/ }
Euclid:find gcd {
  a = 20; b = 10; print("%.0f\n", gcd);
}
```

## Design Implementation

Within contexts and `find` blocks, valid statements look like many C-style
languages, where expressions are semi-colon (`;`) separated, may be have
sub-expessions using parenthesis (`(`, `)`) and the lexemes of an expression
may be made up of:

1. **variables** to which floating-point numbers are assigned

 + **vectors**, like variables, but have square brackets (`[]`) after their
   identifier is indeed a _vector_ of numbers, eg: `myVector[]`

2. **arithmetic** expressions: addition, subtraction, multiplication, division, exponents
3. **comments** characters ignored by the compiler
4. **whitespace** to arbitrary length (eg: `a = 3` is the same as `a   = 3`)
5. **string** literals used for printing
6. **equality** operations in `if`/`else` expressions _(which evaluate to `1` or
   `0` if both operators are equal)_

### Expressions' Lexemes or Tokens

Below the syntax of each type of expression is provided. For the semantic
description of each, refer to the ["Declarations"](#declrations) section,
below.

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
2. Variable Assignment: numbes stored with user-defined nams:

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
  - maybe just simplify hex to a readable list of "special" chars
  TODO: should lexeme include quotes or is that in this regexp?

  Regular Expression might be _(builds on variables' expressions)_:
  ```ocaml
  let chr = \x(0...9|A...F|a...f)(0...9|A...F|a...f) in
  let spc = \(\| "| '| n| t| b| r| space)
  let num = ['0' - '9']                   in
  let aph = ['a' - 'z'] | ['A' - 'Z']     in

  let str = (aph | num | chr | spc)*
  ```

### Reserved Keywords

The following keywords are, and have special meaning in the language. See
"Statements" and "Declarations" sections elsewhere for each of their meanings.

+ `if`
+ `elif`
+ `else`
+ `find`
+ `print`


### Declarations
1. A list of declarator are separated by comma. Formatted as below:
  ```
  Declarator-list:
   declarator, declarator, ...
  ```
  For example:
  ```
  a = 2, b = 3
  a = b, b = a % b
  ```

2. Variable:

 To declare a variable, only name of the variable is needed. The data types of
 the variables are inheritable.

 Possible inherited data types:
 + Double
 + String

3. Vector:
  ```c
  V[ ]
  V[constant-expression]
  V = {a, b, c, ...}
  ```
  In the first case, the expression will declare an array with length 1 and
  initialized with zero, as `[ 0 ]`. In the second case, the expression will
  declare an array with length that evaluated result of the constant expression
  and initialized with zeros, as `[ 0, 0, ... , 0]`. The constant expression
  need to be evaluated to an integer. Such a declarator makes the contained
  identifier have type `vector`. The declarator `V[ i ]` yields a 1-dimensional
  array with rank i of objects of type `double`. To declare a vector of vectors,
  the notation would be like `V[i][j]`. In the third case, the expression will declare
  an array with length, the number of elements inside the "{}". It will initialize
  the array with the elements in the "{}". The elements have to be either Double
  or String and could not be fixed of both.

4. Multi-line equation: declaration of multi-line equation has the format:
  ```
  equation_name = {
    // some operations
    ... // some return value
  }
  ```
  The 'equation_name' has the type Double, where "..." indicates
  the returned variable. The equation will be passed by value. The multi-line
  equation can only return one variable.

  For example:
    ```
      gcd = {
        if (0 == b) {
          a
        } elif (a == 0) {
          b
        }

        if (a > b) {
            a = b, b = a % b  // note: multiple assignments on single line
        } else {
            a = b % a, b = a
        }
        gcd // call gcd() with the current values of a and b
      }
    ```
  “gcd” is similar to a function in C with parameter a and b.


5. Equations:
  ```
  variable =  variable (value assigned?)
  variable =  some airthmetic expression
  variable =  a function call that return a number
  ```
  Only variable will be allowed on the left side of the equal sign. The
  expression on the right side can be declared variable, arithmetic expression
  that returns a number, or a function call that return a number:

  For example:
       ```
       a = 3; b = a; (return b=3)
       a = 3; b = a*2+1 (return 7)
       a = 3; b = 6; c=gcd(a,b) (return 3).
       ```
  The return type will be checked. If the return type is not floating points
  numbers (including interger). Then return 0, standing for ERROR.

  For analysis of equation arithmetic, see "Expression Precedence & Meaning", below.

6. Scope:
  ```
  Variable =

  Scope_name {
    list of equation or list of function
  }

  Scope_name: find ... (with x in range(), ... ,...) {
  }


  ```
  Here, `Scope_name` is like an object of equations. Equations are put inside
  the bracket follow `Scope_name`.

  Any varibale declared outside of a `Scope_name` is a global variable that can be
  accessed from anywhere within the program.
  If a variable declared in some `Scope_name` has the same name as some global variable,
  it will overwite the value within the Scope_name.
  After getting out of the Scope_name, the variable will restore its value.

  `Scope_name: find [...]` is the evaluation part. A `with` clause is optional.
  `find` will evaluate the following variable using the equations inside the
  `Scope_name` part. Once a `Scope_name` is defined, mutiple `find...` are
  allowed to use the equations inside it.

  `with` part is optional. `with` allow users to specify the values for the
  variables using to evaluate unknown x. User can define more than one varibale,
  seperated by comma. If a variable in `find` or `with` part is not found in
  `Scope_name {}`, `0` will be returned to show ERROR. If insufficent values are
  provided for the equations (there are remaining variable on the right side of
  a equation), 0 will be returned for ERROR.



#### Statements
##### Expression Statement
Expression statements are statement that includes an expression and a semicolon at the end:
```
expression ;
```

##### Combining Statements
A statement can be the multiple of other statements. `{` and `}` are used to group multiple statements as one statement. So the form of compound statements is:
```
{ statement+ }
```

, which means that a compound statement has an opening curly bracket, one or more statements, and a closing curly bracket.

##### Conditional Statement
Statements that are used in conditional statements:
```
// if_statement
if ( expression ) statement

// elif_statement
elif ( expression ) statement

// else_statement
else statement
```

Conditional statements have the following form:
```
if_statement elif_statement* else_statement?
```

, which means that it contains a required if_statement, any number of elif_statement, and an optional else_statement.

##### While Statement
While statements have the form:
```
while ( expression ) statement
```

The substatement is executed repeatedly so long as the value of the expression remains non-zero.

##### Break Statement
The statement
```
break ;
```
causes termination of the smallest enclosing `while`, or `with` statement.

##### Continue Statement
The statement
```
continue ;
```
causes control to pass to the loop-continuation portion of the smallest enclosing `while` or `with` statement; that is to the end of the loop. More precisely, in each of the statements.

##### Context statement
A context statement include a context name and a compound statement:
```
context_name compound_statement
```

To access a context, we use a statement with the following form:
```
context_name: statement
```

The substatement will be evaluated in the context given by `context_name`.

Examples:
```
mycontext {
  x = 5
}

print(x) // throw an exception because x in not defined
mycontext: print(x) // prints 5
```

##### With Statement
With statements have the form
```
with [variable in expression]+ compound_statement
```
, which means that with takes one ore more expressiosn, and a compound substatement.

If the expressions have type double, then with will evaluate the expression and execute the compound substatement:
```c
with x in 5 {
  print(x)
}  // 5

with x in 5, y in 6 {
  print(x + y)
}  // 11
```

If the expressions have type vectors, we will execute the compound substatement with all the combinations of values avaiable. Basically, it mirrors multiple `for` loop in Python:
```c
// with vector assignment (causing equivalence of `for` loop in other languages)
with x in {1, 2, 3} {
  print(x)
}  // print 1, 2, 3 on 3 separate lines

with x in {1, 2}, y in {4, 6} {
  print(x, y)
}  // print 5, 7, 6, 8 on 4 separate lines
```

##### Find Statement
Find statements start with keyword `find` and an expression, followed by a substatement:
```
find expression statement
```

In a find statement, the last statement should be evaluated with access to previously declared expressions.

Examples of find statements:
```c
// a simple example
velocity = length + 1

find velocity {
  length = 5
  print(velocity)
} // print 6

// this block is the same as the one above
find velocity with length in 5 {
  print(velocity)
} // print 6

pendulum:find vector with length in range(0, 5) {
  print(velocity)
} // print 1 to 6
```

#### Built-ins
##### `print()`

`print()` is built-in function that mirrors the C `printf()` API. `print()`'s
arguments include a string, and optional expressions:
```
print( a_string_with_formatters [, expressions]* )
```

`print()` prints the formatted string to the screen.

Users can format strings in `print()` with `%f` and `%s` formatter (and but not
`%d`, since `eqeq` only uses float). For example,
```
print("words here %f.0 and %f here\n", 4, myvar)
// words here 4 and 3.14159 here
```


##### `range()`
`range()` mimics Python's `range()` function. It takes an optional expression
`start`, an expression `stop`, and an optional expression `step`. It returns a
vector from `stat` to `stop - 1`, with distance `step` between each member of
the vector:
```c
range([start,] stop [,step])
```

For examples,
```python
range(3)       // same as writing: {0, 1, 2}
range(2, 5)    // same as writing: {2, 3, 4}
range(2, 8, 3) // same as writing: {2, 5, 8}
```

##### Expression Precedence & Meaning

Order of precedence of expressions (`expr`), and their meanings:
 + `'(' exp ')'`
     eg: `( ...)`
   exp here is evaluated before, at which point the parenthesis themselves lose
   their meaning. eg:
   ```
   b * (4 + 5)
   b * 9 // same
   ```
 + `id'['expr?']'`    // TODO: maybe in scanner?

 + `-expr` The result is the negative of the expression with the same type. The
   type of the expression must be double.

 + `!exp`   // eg: `if ((!(a % b))+2)) == (a % !b + 2)` The result of the
   logical negation operator ! is 1 if the value of the expression is 0, 0 if
   the value of the expression is non-zero. The type of the result is double. This
   operator is applicable only to double.

 + `exp ^ exp` // TODO: is this possible to do in our lang, or do we `C's math.h sqrt(...)`?

 + `exp * exp`, `exp / exp` The binary operator * / indicates multiplication and
   division operation. If both operands are double, the result is double.

 + `exp % exp` The binary `%` operator yields the remainder from the division of
   the first expression by the second. Both operands are double, and only integer portion of the double will be used for modular operation, and the result is a double with fraction equals to zero. eg:
   ```
   12.0 % 7.0 = 5.0
   12.3 % 7.5 = 5.0
   ```

 + `expr + expr`, `expr - expr` The result is the sum or different of the
   expressions. Both are double, the result is double.

 + equality/inequality:
   + `exp > exp`, `exp >= exp`, `exp < exp`, `exp <= exp` The operators `<`
     (less than), `>` (greater than), `<=` (less than or equal to) and `>=`
     (greater than or equal to) all yield 0 if the specified relation is false
     and 1 if it is true. Operand conversion is exactly the same as for the `+`
     operator.

   + `exp != exp`, `exp == exp` The != (not equal to) and the == (equal to)
     operators are exactly analogous to the relational operators except for
     their lower precedence. (Thus `a < b == c < d` is `1` whenever `a < b` and
     `c < d` have the same truth-value)

 + `expr || expr` The `||` operator returns 1 if either of its operands is
   non-zero, and 0 otherwise. It guarantees left-to-right evaluation; moreover,
   the second operand is not evaluated if the value of the first operand is
   non-zero.

 + `expr && expr` The `&&` operator returns 1 if both of its operands is
    non-zero, and 0 if either is 0. It guarantees left-to-right evaluation; moreover,
    the second operand is not evaluated if the value of the first operand is 0.

 + `expr = expr`  It require an lvalue as their left operand, and the type of an
   assignment expression is that of its left operand. The value is the value
   stored in the left operand after the assignment has taken place.

 + `expression , expression` A pair of expressions separated by a comma is
   evaluated left-to-right and the value of the left expression is discarded.
   The type and value of the result are the type and value of the right operand.
