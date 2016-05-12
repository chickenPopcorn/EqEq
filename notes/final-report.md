# Introduction <!-- { DRI: Lanting -->
## Background && Goals

Current equation solving languages, such as R, Matlab, Mathematica, though powerful, still require users to have a basic understanding for programming. It is hard for young students in high school or college with no programming background to start using programming to solve the calculations from homework and textbooks. However, programming is extremely helpful when they have multiple variables and tens of equations when manually calculation is time consuming and error prone. Therefore, we truly think it will be great if we can create a
programming language that helps students solve tedious and lengthy mathematical equations with very simple and flexible syntax. Our language EqualEqual targets to be an educational tool for students so that students can move their equations on their whiteboard to a EqualEqual program with as little change as possible. We believe that using programming to solve questions should not be an obstacle for students in their studies, and thus have students enjoyed more with their studies.

## Language Evolution

<!-- Reference from the LRM { -->
EqualsEquals - "eqeq" for short - is a language designed for simple equation evaluation. EqualsEquals helps express mathematical equation in ASCII (though UTF-8 string literals are allowed) without straying too far from whiteboard-style notation. Users do not need to be overly careful to perfectly reduce formulas behind. Leaving unknowns for later is possible, without encapsulating equations' unknowns as function parameters. EqualsEquals takes multiple equations as input and can evaluate the value of a certain variables of the equations when the values of other variables are given.
<!-- } -->
<!-- end introduction } -->

# Tutorial <!-- { DRI: Tianci -->
## Environment Setup
The compiler has been built and tested on OS X El Capitan, Ubuntu 15.10. The EqEq compiler Installation of Dependencies below:

**Installation under Ubuntu 15.10**
```bash
$ sudo apt-get install -y ocaml m4 llvm opam
$ opam init
$ eval `opam config env`
```

**Installation under OS X**
```bash
$ brew install opam
$ opam init
$ eval `opam config env`
```

After OPAM is initialized, go to the the directory where you want EqEq installed and clone the git repository:
```bash
$ git clone https://github.com/rxie25/PLT2016Spring.git
```
## Using the Compiler
Inside the directory of the cloned file
```bash
$ cd src
$ make
```
This creates the complier for EqEq that takes in '.eq' files and complies them to corresponding '.c' files as C code files. To run Eqeq executable is:
```
$ ./eqeq.native [options] < [your file name]
```
There are additional flags `-s` for printing the dependency table of the variables.
## Modifying and Testing the Compiler
To run **all end-to-end checks**, simply: `make e2e`.
- or just run `make lint` to see non-test checks
- or just run `make test` to see input/output checks:

```bash
$ make test # or: `make TEST_OPTS=-h test` or any other options it takes

#... {clean, build, etc.}-output snipped...

Running 1 tests:
        tests/test-helloworld.eq,
[1] "test-helloworld"   asserting target\'s behavior             Result: PASS

Summary: PASSED
```

### Faster Code & Test Cycle
**tl;dr** make use of the `TEST_OPTS=...` flag of `make test`

```bash
$ time { make test; }

# ... `make test` output snipped...

Summary of 118 tests:   9 SKIPPED       109 PASSED [87%]

real    0m10.697s
user    0m1.660s
sys     0m0.868s
```
**Problem**: With over a 100 tests, you might want to punt a full `make test`
for later. When you're writing code, you might benefit from **just running your
own tests** _(plus a few super-simple general tests you'd like to see break,
immediately)_.

**Solution**: say you're developing "cool feature" against two new test files,
`fail-cool-feature.eq` and `test-cool-feature.eq` and you want to know
*immediately* if you break `test-helloworld.eq`:

```
$ make TEST_OPTS='-v tests/*cool-feature*.eq tests/test-helloworld.eq' test
Running 3 tests:
  "cool feature"       "cool feature"
  "helloworld"
[ 1] "test-cool-feature"       asserting target's behavior      Result: PASS
[ 2] "fail-cool-feature"       asserting compilation fails      Result: PASS
[ 3] "test-helloworld"         asserting target's behavior      Result: PASS

Summary of 3 tests:     3 PASSED [100%]
```

### Writing Tests
So you wrote a feature, like... a `CrazyNewKeyword` that shuts down user's
computer? Great! Do this:
```sh
$ $EDIT tests/test-crazynewkeyword.eq
  # ... ideal case, capturing the complexity you've added (a correct program)

$ $EDIT tests/test-crazynewkeyword.out
  # ... what your example compiled eq C program should do (just the output)
$ make test # ensure its result is "PASS"!

$ $EDIT tests/fail-crazynewkeyword.eq
  # ... any misuse you can think of (an incorrect program)
$ $EDIT tests/fail-crazynewkeyword.err
  # ... how our compiler should complain for your example eq source
$ make test # ensure its result is "PASS"!
```

Note: currently we're trying to only test the behavior of our *compiled* C
programs _(that is: we're not testing what our compiler outputs, but what its
output programs do)_.

### Debugging Compiler's Phases

#### Scanner: Tokens We Generate
To see what our scanner thinks of source programs, with `debugtokens` target:
```sh
$ make debugtokens && ./debugtokens.native < tests/test-helloworld.eq
# .. snipped ...
CTX
ASSIGN
LBRACE
ID
ASSIGN
LBRACE
# ... snipped ....
ID
LPAREN
STRLIT
COMMA
ID
RPAREN
SEMI
RBRACE
```

#### Parser: Our Grammar
Interactive mode with menhir and our parser:
```sh
$ menhir --interpret --interpret-show-cst parser.mly # note missing ASSIGN
CTX LBRACE ID ASSIGN LITERAL SEMI RBRACE

REJECT
```

#### SAST: Our Semantically-Checked AST
To see the output of our semantic analysis ([as of]):
```bash
make && ./eqeq.native -s < $YOUR_TEST_FILE
```
[as of]: https://github.com/rxie25/PLT2016Spring/commit/6e908c68afdec6fe183db3170f43dddd4c69d11c

#### Codegen: EqualsEquals compiler itself
To get the generated C code (ie. the output of code gen):
```bash
make && ./eqeq.native < $YOUR_TEST_FILE
```

### One-time Setup

The above assumes you've done the one-time installation of dependencies for your
machine, thoroughly documented in `./INSTALL`

#### Quickstart

Can't remember if you've done the one-time setup on your machine?

1. Make sure `git status` shows you're in a clean copy of this repo
2. If you can do the below with all tests passing _(obviously)_ then you
  already setup your machine:
```bash
git checkout 1548af6bc79197445a203 &&
  make test &&
  make clean >/dev/null &&
  git checkout master
```

## Basics and Syntax
### Primitives
All primitive are declared with implicit types by an identification.
### Operators
EqEq supports the fellowing operators:

1. Arithmetic: `+, -, /, *, ^, %, sin, cos, tan, sqrt, log, | ID |`
2. Conditional: `==, !=, <, <=, >, >=, &&, ||, !`
3. Other: `range`

## Control Structures and Built-in Functions

## Example Programs

<!-- Reference from the LRM { -->
## Definition of a Program

The simplest - though contrived - valid program is:
```js
find { printf("Hello, all %.0f readers!\n", 21 * 2); }
```

Which prints the following to standard out: `Hello, all 42 readers!`

Formally, a valid program is a series of:
- one or more `find` blocks.
- zero or more "context" blocks _(aside from the automatic, global context)_

## "Context"s & `find` Blocks

While both types of blocks of code are simply curly brace enclosed listings of
sequential statements, contexts and `find` blocks differ in their use:
- `context`s are expected to layout and define equations for use later.
  Thus they're allowed semantic gaps in their equations; eg: missing solutions.
- `find` blocks on the other hand are expected to be the resolution to "find"
  missing said pieces, or simply apply completed solutions to new inputs.

The `context` block consists of a list of single line and/or multi-line equations.
The single line equations is expressed in assignment format.
```js
SomeCtx = { a = 42; }
```
Multi-line equations, like single line equations, must be expressed in assignment
format, but right hand side is express in `{*... multi-line statements ...*}`. In
this case right hand side variable is treated as a variable. However
nested `{{}}` is considered illegal in eqeq.
```js
multi:{
  // multi-line equation life
  life = {
    if (a == 42) {
      a;
    } else {
      17;
    }
  }
}

multi: find life {
  a = 42;
  print("%.0f\n", life);
  //prints out 42
}
```

It follows then that `find` expressions _apply_ to contexts. Where a context
might be shared for re-use, `find` expressions are designed to make local use of
equations in a given context.

Though the above "Hello World" example executes a `find` on the global context,
users will generally define contexts manually. For example a "Euclid" context,
where `gcd` might be defined:
```js
Euclid = { gcd = /*... defined here ...*/; }
Euclid: find gcd {
  a = 20; b = 10; print("%.0f\n", gcd);
}
```

## Sample program

Below are example programs in EqualsEquals.

### Example of Equations' `find` Use-cases

```js
sum = 0  // initialize a number called sum
pendulum {
  /**
   * Spell out equation for our compiler:
   *   m * g * h = m * v^2 / 2
   */
  m = 10;
  theta = pi / 2;
  g = 9.8;
  h = l - l * cos(theta); // cosine, being a built-in
  v = (2 * g * h) ^ (1 / 2); // square root
  // note: relying on existing libraries for cos
}

// evaluate v in pendulum's equations given that g = 9.8 and l in range(20)
pendulum: find v with l in range(0, 20) {
  // Our compiler now has solutions to: m, g, l (and indirectly h), so v can
  // be solved:

  print("velocity: %f", v);

  // v is automatically evaluated when it's referred to
}

// evaluate v in pendulum's equations given that g in range(4, 15) and l = 10
// take the average of values of v
pendulum: find v with m = 100; g in range(4, 15); {
  l = 10;

  sum += v;
  // scope of sum: global (b/c it's not in the scope of pendulum but would be
  // overwritten by pendulum)
}

average = sum / (15 - 4);

pendulum: find v with v in range(20); {
  // throw a compiler error because can't find v with v's value
}

// Example: tries l = 10, v = 20 in context of pendulum, to see its equations
// are still true. If equations are inconsistent, the program will throw an
// exception.
pendulum: find v {
  l = 10; // by now, v will be calculated
  print(v == 20);  // print 1
  v = 20; // throws an error
}
```

### Example of a multi-line equation to find `gcd` of `a` and `b`
```js
myGCD {
  gcd = {
    if (0 == b) {
      a;  // solution is a
    } elif (a == 0) {
      b;  // solution is b
    }

    if (a > b) {
      a = b, b = a % b;
      // note: multiple assignments on single line
    } else {
      a = b % a, b = a;
    }
    gcd; // solution is gcd w/the current a and b
  }
}

// evaluate gcd of 10 and 20
myGCD: find gcd {
  a = 10;
  b = 20;

  print("gcd of %.0f and %.0f is %.0f\n", a, b, gcd);
}
/* END: Example of a multi-line equations to find gcd of a and b */


/* This works too. In this case, gcd is not in any special scope */
gcd = {
  ...  // same as the above example
}

// evaluate gcd of 10 and 20
find gcd {
  a = 10;
  b = 20;
  print("gcd of %.0f and %.0f is %.0f\n", a, b, gcd);
}
/* END: Example of a multi-line equations to find gcd of a and b */
```
<!-- } -->
<!-- end tutorial } -->

# Reference Manual <!-- { DRI: Jon -->

<!-- Reference from the LRM { -->
## Design Implementation

Within contexts and `find` blocks, valid statements look like many C-style
languages, where expressions are semi-colon (`;`) separated, may be have
sub-expressions using parenthesis (`(`, `)`) and the lexemes of an expression
may be made up of:

1. **variables** to which floating-point numbers are assigned
 + **vectors**, like variables, but have square brackets (`[]`) after their
   identifier is indeed a _vector_ of numbers, eg: `myVector[]`
2. **arithmetic** expressions: addition, subtraction, multiplication, division,
   exponents
3. **comments** characters ignored by the compiler
4. **white-space** to arbitrary length (eg: `a = 3` is the same as `a     = 3`)
5. **string** literals used for printing
6. **equality** operations in `if`/`else` expressions _(which evaluate to `1` or
   `0` if both operators are equal)_

### Tokens: Expressions' Lexemes

Below is the syntax of each type of expression. For the semantic description of
each, refer to the ["Declarations"](#declarations) section, below.

1. Floating point numbers, including integers:

  eg: `123`, `1.34e-4`, `0.23`, `.13`, `0e1`.

  Described by the regular expression `flt` here:
  ```ocaml
  let pos = ['1' - '9']                    in
  let dig = '0' | pos                      in
  let exp = ('e' | 'E') ('-' | '+')? pos+  in
  let fra = '.' dig+ exp?                  in
  let num = pos dig*                       in

  let flt = num | ((num | 0)? fra) | (num exp)
  ```
2. Variable Assignment: numbers stored with user-defined names:

  eg: `weight = 100 /*grams*/`

  Described by the regular expression `var` here:
  ```ocaml
  let aph = ['a'-'z'] | ['A'-'Z']     in

  let var = aph+ ('_' | ['0'-'9'])*
  ```

3. Contexts: blocks of symbols:

  eg: `Euclid: {/* any number of lines of EqualsEquals here */}`

  Building on variables' definition, the regular expression can be described by
  `ctx` here:
  ```ocaml
  let ctx = ['A'-'Z'] var*
  ```

4. Strings: mostly used for printing results:

  eg: `printf("result of my maths: %.0f\n", gcd)`

  String literals can be described by the regular expression `str` here:
  ```ocaml
  let chr = \x(0...9|A...F|a...f)(0...9|A...F|a...f) in
  let spc = \(\n| \t| \b| \r| ' ')
  let num = ['0' - '9']                   in
  let aph = ['a' - 'z'] | ['A' - 'Z']     in

  let str = (aph | num | chr | spc)*
  ```
  <!-- note this means we have to convert UTF-8 chars to escaped ASCII strings -->

### Reserved Keywords

Following are reserved keywords, and have special meaning in the language. See
"Statements" and "Declarations" sections elsewhere for each of their meanings.

+ `if`
+ `elif`
+ `else`
+ `find`
+ `print`
+ `Global`

Eqeq is translated into C, so it has the same set of reserved keyword as in C in additional to the reserved keywords above.
+ `int`
+ `double`
+ `char`
+ `float`
+ `const`
+ `void`
+ `short`
+ `struct`
+ `long`
+ `return`
+ `static`
+ `swtich`
+ `case`
+ `default`
+ `for`
+ `do`
+ `goto`
+ `auto`
+ `signed`
+ `extern`
+ `register`
+ `enum`
+ `sizeof`
+ `typedef`
+ `union`
+ `volatile`


### Declarations
1. A list of declarator are separated by comma. Formatted as below:
  ```
  Declarator-list:
   declarator, declarator, ...
  ```
  For example:
  ```js
  a = 2, b = 3;
  a = b, b = a % b;
  ```

2. Variable:

 To declare a variable, only name of the variable is needed. The data types of
 the variables are inheritable.

 Possible inherited data types:
 + Double
 + String

3. Vector:
  ```js
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
  ```js
  equation_name = {
    // some operations
    var; // a variable, indicating equation_name's value
  }
  ```
  The `equation_name` has the type Double, where `var` indicates
  the name of variable expression holding the desired value. The equation will
  be passed by value. The multi-line equations, like regular equations, can
  only express one value _( or a vector of values)_.

  For example:
  ```js
   gcd = {
     if (0 == b) {
       a;  // solution is a
     } elif (a == 0) {
       b;  // solution is b
     }

     if (a > b) {
       a = b, b = a % b;
       // note: multiple assignments on single line
     } else {
       a = b % a, b = a;
     }
     gcd; // solution is gcd w/the current a and b
   }
   ```
  This example results in an expression `gcd` - similar to a C-style function -
  that can be referred to later, given the necessary inputs `a` and `b` (in
  eqeq's case, the right "context").

5. Equations:
  ```
  variable = variable (value assigned?)
  variable = some arithmetic expression
  variable = { /*some multi-line equation that evaluates to a number*/ }
  ```
  Only variable will be allowed on the left side of the equal sign. The
  expression on the right side can be a declared variable, an arithmetic
  expression that evaluates to a number, or a multi-line equation enclosed in
  curly-braces (see "Multi-line equation" above).

  For example:
  ```js
  a = 3; b = a;          // b == 3
  a = 3; b = a * 2 + 1;  // b == 7
  a = 3; b = 6; c = gcd; // c == 3
  ```

  For analysis of equation arithmetic, see "Expression Precedence & Meaning",
  below.

6. Scopes (access to variables):

  ```js
  VAR = EXPR;

  Scope_name {
    list of equations

    // VAR = EXPR // overwrites global `VAR`
  }

  Scope_name: find VAR [with VAR_B in range()]* ] {
    /** code here has access to `Scope_name`'s equations */
  }
  ```

  Here, `Scope_name` is like an object of equations. Equations are put inside
  the bracket follow `Scope_name`.

  Any variable declared outside of a `Scope_name` is a global variable that can
  be accessed from anywhere within the program. It can evaluate any variable in the global context and overwrite the expressions in the global context. If a variable declared in some `Scope_name` has the same name as some global variable, it will overwrite the value within the `Scope_name`.  After getting out of the `Scope_name`, the variable will restore its value.

  `Scope_name: find VAR [...]` is the evaluation part. A `with` clause is
  optional. See "With Statement" section below. `find` will evaluate the
  variable following it using the equations inside the `Scope_name` block. Once
  a `Scope_name` is defined, multiple `find` are
  allowed to use the equations inside it.


#### Statements
##### Expression Statement
Expression statements are statement that includes an expression and a semicolon
at the end:
```
expression ;
```

##### Combining Statements
A statement can be the multiple of other statements. `{` and `}` are used to
group multiple statements as one statement. So the form of compound statements
is:
```
{ statement+ }
```

, which means that a compound statement has an opening curly bracket, one or
more statements, and a closing curly bracket.

##### Conditional Statement
Statements that are used in conditional statements:
```js
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

, which means that it contains a required if_statement, any number of
elif_statement, and an optional else_statement.

##### While Statement
While statements have the form:
```js
while ( expression ) statement
```

The sub-statement is executed repeatedly so long as the value of the expression
remains non-zero.

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
causes control to pass to the loop-continuation portion of the smallest
enclosing `while` or `with` statement; that is to the end of the loop. More
precisely, in each of the statements.

##### Context statement
A context statement include a context name and a compound statement:
```
context_name compound_statement
```

To access a context, we use a statement with the following form:
```
context_name: statement
```

The sub-statement will be evaluated in the context given by `context_name`.

Examples:
```js
mycontext {
  x = 5;
}

print(x); // throw an exception because x in not defined
mycontext: find x {
  print(x); // prints 5
}
```

##### With Statement
With statements have the form
```
with [variable in expression; ]+ compound_statement
```
, which means that with takes one or more expressions, and a compound
sub-statement. (After each expression, a semicolon is needed after the expression.)

If the expressions have type double, then with will evaluate the expression and
execute the compound sub-statement:
```js
with x = 5; {
  print(x);
}  // 5

with x = 5; y = 6; {
  print(x + y);
}  // 11
```

If the expressions have type vectors, we will execute the compound sub-statement
with all the combinations of values available. Basically, it mirrors multiple
`for` loop in Python:
```js
// with vector assignment (causing equivalence of `for` loop in other languages)
with x in {1, 2, 3} {
  print(x);
}  // print 1, 2, 3 on 3 separate lines

with x in {1, 2}, y in {4, 6} {
  print(x, y);
}  // print 5, 7, 6, 8 on 4 separate lines
```

##### Find Statement
Find statements start with keyword `find` and an expression, followed by a
sub-statement:
```
find expression statement
```

In a find statement, the last statement should be evaluated with access to
previously declared expressions.

Examples of find statements:
```js
// a simple example
velocity = length + 1;

find velocity {
  length = 5;
  print(velocity);
} // print 6

// this block is the same as the one above
find velocity with length = 5; {
  print(velocity);
} // print 6

pendulum:find vector with length in range(0, 5); {
  print(velocity);
} // print 1 to 6
```

##### `range()`
`range()` mimics Python's `range()` function. It takes an optional expression
`start`, an expression `stop`, and an optional expression `step`. It returns a
vector from `stat` to `stop - 1`, with distance `step` between each member of
the vector:
```js
range([start,] stop [,step]);
```

For examples,
```python
range(3);        // same as writing: {0, 1, 2, 3}
range(-3);       // same as writing: {0, -1, -2, -3}
range(2, 5);     // same as writing: {2, 3, 4, 5}
range(2, 8, 3);  // same as writing: {2, 5, 8}
```

Range has to be the last argument in the find block.
For examples,
```
SomeCtx: find a with b = 3; c in range(3); {} // correct syntax
SomeCtx: find a with c in range(3); b = 3; {} // illegal syntax
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
```js
print("words here %f.0 and %f here\n", 4, myvar);
// words here 4 and 3.14159 here
```

Unlike the built-in functions below print function does not support any unary or binary operators.
```js
-print("words here %f.0 and %f here\n", 4, myvar);
// will throw the following error
Fatal error: exception Failure("Illegal use of operator on print, "-"")
```

##### `sin()/cos()/tan()/sqrt()/log()`

`sin()/cos()/tan()/sqrt()/log()` are built-in trigonometry and math functions that mirrors the same functions in C
under `math.h` library. Their arguments include variable names and numbers only. Nested built-in functions are allowed.

Numerical range for sqrt()\log() and is confined to greater or equals to zero and greater than zero respectively and are checked statically at compile time. Like most imperative language illegal argument for the above built-in functions cannot be caught at compile time for variables, will will be reported at C runtime.
```
a = cos(sin(tan(log(sqrt(42)))));
```

functions can be nested like the example above.



<!-- TODO: insert built-in descriptions for cos, sin, sqrt, others.-->

### Expression Precedence & Meaning

Here various expressions' meanings are described, generally shown as `expr`, in
the order of their precedence.

 + `'(' expr ')'`: for sub-expressions. For example, `expr` of `4 + 5` here:
   ```js
   b * (4 + 5); // `expr` should be considered first
   b *  9;      // same as above; note absence of parenthesis
   ```
 + `id '[' expr? ']'`: for vector access.

 + `-expr`: negative. The result is the negative of the expression. Note, the
   type of the expression must be double.

 + `!expr`: logical negation.

   The result of the logical negation operator `!` is `1` if the value of `expr`
   is `0`. If the value of `expr` is anything other than `0`, then `!expr`
   results in `0`.

 + `left_expr ^ right_expr`: exponentiation. Mathematically raises `left_expr`
    to the power, `right_expr`. Note: uses underlying C standard library's
    corresponding power API, eg: `double pow (double base, double power)`.

 + `expr * expr`, `expr / expr` The binary operator * / indicates multiplication
   and division operation. If both operands are double, the result is double.

 + `expr % expr` The binary `%` operator yields the remainder from the division
   of the first expression by the second. Both operands are double, and only
   integer portion of the double will be used for modular operation, and the
   result is a double with fraction equals to zero. eg:
   ```js
   12.0 % 7.0 = 5.0;
   12.3 % 7.5 = 5.0;
   ```

 + `expr + expr`, `expr - expr` The result is the sum or different of the
   expressions. Both are double, the result is double.

 + equality/inequality:
   + `expr > expr`, `expr >= expr`, `expr < expr`, `expr <= expr` The operators
     `<` (less than), `>` (greater than), `<=` (less than or equal to) and `>=`
     (greater than or equal to) all yield 0 if the specified relation is false
     and 1 if it is true. Operand conversion is exactly the same as for the `+`
     operator.

   + `expr != expr`, `expr == expr`: The `!=` (not equal to) and the `==` (equal
     to) operators are exactly analogous to the relational operators except for
     their lower precedence. (Thus `a < b == c < d` is `1` whenever `a < b` and
     `c < d` have the same truth-value).

 + `expr || expr` The `||` operator returns 1 if either of its operands is
   non-zero, and 0 otherwise. It guarantees left-to-right evaluation; moreover,
   the second operand is not evaluated if the value of the first operand is
   non-zero.

 + `expr && expr` The `&&` operator returns 1 if both of its operands is
   non-zero, and 0 if either is 0. It guarantees left-to-right evaluation;
   moreover, the second operand is not evaluated if the value of the first
   operand is 0.

 + `left_expr = right_expr`: assignment. the `left_expr` must be a single
    variable expression. The result of this operation is that `left_expr` holds
    the value of `right_expr` going forward. If `right_expr` contains unknown
    variables, the `left_expr` will not be solvable until a `find` block
    expresses a solution in terms of `left_expr` and provides any missing
    variables from the `right_expr`.

 + `expression , expression` A pair of expressions separated by a comma is
   evaluated left-to-right and the value of the left expression is discarded.
   The type and value of the result are the type and value of the right operand.
<!-- } -->
<!-- end reference manual } -->

# Project Plan <!-- { DRI: Jimmy -->
## Roles and Responsibilities
We assigned four main roles ­ Manager(two), Language Guru, System
Architect, Tester to each member on the team. As we developed our language,
the role were not that clearly divided. The team would help each other when we
ran into particularly difficult problems, and assign each other pull request
to review before merge. The table below illustrates the main
roles and one example of a part we contributed heavily in.

| Name | Responsibilities|
|------|-------|
| Nam Nhat Hoang |  Language Guru,  Code Generation|
| Tianci Zhong   | Manager,  Semantic Analysis, Code Generation |
| Ruicong Xie    | Tester, Code Generation |
| Lanting He     | Tester, Code Geneation |
| Jonathan Zacsh | System Architect, Semantic Analysis |
## Timeline
| Time | Events|
|------|-------|
|Jan 25|First Commit|
|Jan 25|Submitted Project Proposal|
|Mar 7|Submitted Language Reference Manual|
|Mar 27|First Travis CI Build|
|Mar 31|Successfully Generated Code (“Hello World”)|
|April 25|Major Language Features Complete|
|May 7|Variable Dependency Resolved |
|May 9|Presentation Presentation|
|May 11|Project Submission|
## Specification
At the beginning of the semester we had the idea to make a physics language. Later we
realized  a lot of the problem we have to solve are just mathematical equations. That's when
we had the idea to make EqEq, a mathematical language that solves equations. However we later
found symbolic mathematical manipulate was too broad of a topic to tackle, so we scaled our compiler back
to variable resolution in mathematical equation.
## Development
We first worked together on `scanner.mll`, `parser.mly` and `ast.ml`,
as no one on our team had any prior experience  with OCaml. Our first milestone
was to make a very basic scanner, parser, and generator. We built up the basic
pipeline for automated testing on Travis CI. Whenever we worked on a new feature,
we would created a new branch and open a pull request to merge with master. No pull request
was accepted unless it passed all of the tests and was review by one of the team member.
Once we had simple hard coded version of `hell-world.eq` working with our compiler,
we quickly decided to split into smaller groups to tackled some more difficult problems, like
multiple-line equation, context resolution, variable dependency, etc.
We initially added semantic analysis and naive version of variable mapping for scope and
variable resolution. However we soon realized the the problem is more complex, and built
`relation.ml` a variable dependency table to deal with the problem, in which we used DFS to detect
cyclic reference.
## Testing
While developing the code, we concurrently tested what we wrote. When we initially developing our language we had `debugtokenizer.ml` and `debug_frontend.py` to test the font end of our language. The first program splits out correct recognized tokens when fed with source code in eqeq, while the second one runs the tokens through `parser.ml` with `menhir`.   After we Finished the bulk of the front end of our compiler. We set up automated testing on Travis CI with `.travis.yml` to test if our language is compiling properly for each commit. All the testing suite and processes will be discussed in detail later in the testing section of this report.
## Software Development Environment
**Programming Language Stack**
- Git Repository Hosted on Github for version control which contains
the compiler code and test suite
- OCaml for scanning, parsing, and semantically checking eqeq source
code and generation of C target code output
- Bash Shell Scripts for running our program given an input eqeq file (.eqeq) and
an output C file (.c) file, as well as automating testing
- Makefile for all things compiling, linking, and test related


**Tools**
- Travis CI for automated continuous integration testing through Github to make
sure no new code modifies the correct functionality of the language
- Sublime, Atom, Vim for text editing, depending on each team member’s
preference

## Programming Style Guide
While programming, all group members followed these following style guidelines to
ensure our project stayed consistent:
- Lines of code should not be more than 80 characters
- No tabs for indentation
- Indentation is always 4 spaces
- Naming consistency between the different program files
- Newline at the end of each file
- One line between each declaration block
- White space for readability

# Translator Architecture <!-- { DRI: Nam -->
The compiler is, of course, built in OCaml. The architecture of the compiler is demonstrated in the block diagram below. Our compiler source code includes 8 files:
- `eqeq.ml` - main module that calls other modules to produce the output
- `ast.ml` - AST (abstract syntax tree) representation of the language
- `sast.ml` - SAST (semantically checked AST) representation of the language
- `scanner.ml` - tokenizes a source file
- `parser.ml` - constructs an AST from the output tokens of the scanner
- `semant.ml` - checks the incoming AST to make sure that the AST is semanticallly correct, and produces a SAST
- `relation.ml` - an extension of `semant.ml`, used to generate a large part of the SAST
- `codegen.ml` - converts a SAST into a working C code

![](img/2016-05-11_17:49:10.png)

In summary, the source code is passed through the scanner and parser to create an Abstract Syntax Tree, which then went through the Semantic Analyzer to create an modified AST (aka. SAST). The C code is generated from the SAST using a code generator.

## Scanner
The scanner tokenizes the input from the input file. Additionally, it discards unnecessary characters and check the syntax of the program.

## Parser
The parser constructs an abstract syntax tree (AST) with the input token from the scanner. The highest level of the AST contains a global context block, all context blocks and all find blocks. The following figure demonstrates the main structure of the AST. The parser also further checks the syntax of the program. The combination of the parser and the scanner makes sure that the input program is syntactically correct.

![](img/2016-05-11_17:49:51.png)

![](img/2016-05-11_17:50:13.png)

## Semantic Analyzer
The semantic analyzer has two main jobs. The first one is to check for all the semantic errors of the program. The following semantic errors are checked in our compiler:
- Illegal usage of reserved keyword, e.g: break
- Illegal usage of duplicate context block
- Illegal usage of mathematical equation, e.g: cos(3,4,5)
- Lower case Context name
- Bad syntax of if / if-elseif /if-else
- Undeclared variables and undeclared context
- Illegal use of build-in function (e.g: `print("%0.0f ", a)-print("%0.0f ", a)`; `range(3, 5, "abc")`)
- Illegal return
- Illegal find block declaration
- Cyclic dependency

The second job of the semantic analyzer is taking the parser's AST and producing an SAST. Our SAST contains the AST, a multi-line equation dependency structure, a context variable map, and a library list.
- **Multi-line equation dependency structure** - At the high level, the multi-line equation dependency structure can be understood as a structure of graphs where each node is a variable, and each edge is the dependency between two variables. The multi-line equation dependency structure contains all the variables that are declared for each context block and its corresponding find blocks. The structure indicates whether a variable is dependent on other variables or not. If a variable `x` is independent of other variables, the structure shows the expression assigned to `x`. If a variable `y` is independent of other variables, the structure shows the list of variables that `y` depends on.
- **Context variable map** - This is a structure that contains information of the variables for each context. The generator uses the information provided by the context variable map to generate definitions for variables (e.g. "double x;") and to match the name of the variables with the corresponding names in the generated code in C (e.g. a variable `a` in context `MyCtx` could be named as `MyCtx_a_<counter_number_to_avoid_duplicates>`).
- **Library list** - blah blah blah. <!-- DRI: Lanting - 1 sentence about the library list -->

## Code Generator
The code generator uses the SAST provided by the semantic analyzer to construct the `C` instructions for the `eqeq` program.
- **Global context and context blocks** - Multi-line equations in both global context and context blocks are generated as functions in the output C program. The return value of a function will be the the result of the multi-line equation. To be unique, a function name includes the corresponding context name and a counter (e.g. `MyCtx_a_0()`).
- **Find blocks** - Find blocks are generated as a function in the output C program (e.g. `find_MyCtx_1()`). In find blocks, variables that are defined and used locally will be assigned to the corresponding functions in global context (e.g. `a = MyCtx_a_0(b, d);`).
- **Dependency Generation** - The multi-line equations are resolved when a new variable is declared. The functions needed to be regenerated will be generated using the multi-line equation dependency structure, as mentioned in the above section (Semantic Analyzer). Since efficiency is not a priority, the dependency generation might generate duplicated assignments.
- **Range** - blah blah. Those functions will be called by `main()`. <!-- DRI: Jimmy - 1 sentence about codegen for range -->

## Utilities
The compiler can generate pretty-print strings for AST and SAST with flags `-a` and `-s`. The printed AST and SAST show us the output of the program through different phases and help debugging much faster.
<!-- end translator architecture } -->

# Test Plan <!-- { DRI: Jon -->
## Testing Phases
## Automation
## Test Suites
## Examples
<!-- end test plan and scripts } -->
<!-- end project plan } -->

# Lesson Learned <!-- { -->
## Tianci <!-- DRI: Tianci -->
## Jimmy <!-- DRI: Jimmy -->
Importance of having a seamless workflow and communication when collaborating for large scale development.
Also don't be afraid to tackle bigger problems.

## Jon <!-- DRI: Jon -->
## Nam <!-- DRI: Nam -->
## Lanting <!-- DRI: Lanting -->
<!-- } -->

# Conclusions <!-- { DRI: Lanting -->

As stated at the beginning, EqualEqual aims to provide students an easy tool to solve lengthy and error-prone mathematical equations. With all the features we mentioned above, we belive that EqualEqual has succeeded in becoming such a user-friendly and smart language. Due to the time manner, we are not able to have it been extremly powerful. However, We expect it to be more powerful, e.g: solve complex variable circular dependency functions,  in the future by using more sophisticated algorithms.

<!-- end conclusions } -->

# Full Code Listing <!-- { DRI: Nam -->
## Commit summary
## Project Log
## Codes
<!-- end full code listing } -->


<!--
sample (starred) reports:
http://www.cs.columbia.edu/~sedwards/classes/2015/4115-fall/reports/Dice.pdf
http://www.cs.columbia.edu/~sedwards/classes/2014/w4115-fall/reports/Qlang.pdf
http://www.cs.columbia.edu/~sedwards/classes/2015/4115-fall/reports/superscript.pdf
-->
