# TODO:s
- [ ] TODO(jon): review TODOs with TA/edwards (email Daniel)
- [ ] TODO(jon): move [LRM google doc](https://goo.gl/VJcW5Z) into this doc
  - refactor headers to look like [C LRM](https://www.bell-labs.com/usr/dmr/www/cman.pdf)
   1. Copy/paste old-LRM's content:
     - [x] Introduction
     - [x] Motivation
     - [ ] Language Description
       - [ ] Target Language: Python
       - [ ] Syntax Overview
         - [ ] Data Types
         - [ ] Comments
         - [ ] Code block format
         - [ ] Declaration
         - [ ] Flow control
       - [ ] Language Features
         - [ ] Mathematical Equations
       - [ ] Sample program
   2. refactor *this* LRM's existing content

  - expand missing pieces
- [ ] TODO(tianci): "declarations" section: "explain *how* users declare each thing
    in our language (functions, variables, equations - like things should be
    single-variable on left-side)
- [o] TODO(nam): address 'Keyword Meanings" TODO i.e. statements
  - [ ] should we have for loop?
  - [ ] while loop?
  - [ ] `continue` and `break` inside with range statement?
  - [ ] null statement?
- [ ] TODO(nam): builtin functions
  - [ ] range
  - [ ] print
  - [ ] what else?
- [ ] TODO(jimmy): cleanup/collapse/whatever 'Keyword Meanings" precedence
- [ ] TODO(jimmy): address 'Reserved Keywords" TODO
- [ ] as group: start scanner.mll based on "Keywords & Expressions" sectinos
    - [ ] update this doc based on what works

---

# `EqualsEquals` Language Reference Manual (LRM)

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
+ `find`
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
1. A list of declarator are separated by comma. Formatted as below:
  ```
  Declarator-list:
   declarator, declarator, ...
  ```

2. Variable:

 To declare a variable, only name of the variable is needed. The data types of the variables are inheritable.

 Possible inherited data types:
 + Integer
 + Double
 + String

3. Vector:
  ```c
  V[ ]
  V[constant-expression]
  ```
In the first case, the expression will declare an array with length 1 and initialized with zero, as `[ 0 ]`. In the second case, the expression will declare an array with length that evaluated result of the constant expression and initialized with zeros, as `[ 0, 0, ... , 0]`. The constant expression need to be evaluated to an integer. Such a declarator makes the contained identifier have type `vector`. The declarator `V[ i ]` yields a 1-dimensional array with rank i of objects of type `double`. To declare a vector of vectors, the notation would be like `V[i][j]`.

4. Function:
declaration of function has the format as below:
  ```
  function_name = function (parameter, parameter, ... ) {
    // some operations
    return ...
  }
  ```
  The 'function_name' has the type "...", where "..." indicates the type which the returned variable has. The function will be passed by value.
5. Equations:
  ```
  variable =  variable (value assigned?)
  variable =  some airthmetic expression
  variable =  a function call that return a number
  ```
  Only variable will be allowed on the left side of the equal sign. The expression on the right side can be declared variable, arithmetic expression that returns a number, or a function call that return a number:

  e.g:
       ```
       a = 3; b = a; (return b=3)
       a = 3; b = a*2+1 (return 7)
       a = 3; b = 6; c=gcd(a,b) (return 3).
       ```
  The return type will be checked. If the return type is not floating points numbers (including interger). Then return 0, standing for ERROR.


6. Scope:
  ```
  Scope_name {
    list of equation or list of function
  }

  Scope_name: find ... (with x in range(), ... ,...) {
  }
  ```
  Scope_name is like an object of equations. Equations are put inside the bracket follow Scope_name.

  Scope_name: find... is the evaluation part. A 'with' clause is optional. 'find' will evaluate the following variable using the equations inside the Scope_name part. Once a Scope_name is defined, mutiple 'find...' are allowed to use the equations inside it.

  'with' part is optional. 'with' allow users to specify the values for the variables using to evaluate unknown x. User can define more than one varibale, seperated by comma. If a variable in 'find' or 'with' part is not found in Scope_name {}, 0 will be returned to show ERROR. If insufficent values are provided for the equations (there are remaining variable on the right side of a equation), 0 will be returned for ERROR.

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
 + `'(' exp ')'`
     eg: `( ...)`
   exp here is evaluated before, at which point the parenthesis themselves lose
   their meaning. eg:
   ```
   b * (4 + 5)
   b * 9 // same
   ```
 + `id'['expr?']'`           // TODO: maybe in scanner?

 + `-expr` The result is the negative of the expression with the same type. The type of the expression must be int, or double.

 + `!exp`   // eg: `if ((!(a % b))+2)) == (a % !b + 2)` The result of the logical negation operator ! is 1 if the value of the expression is 0, 0 if the value of the expression
 is non-zero. The type of the result is int. This operator is applicable only to ints.

 + `exp ^ exp` // TODO: is this possible to do in our lang, or do we `C's math.h sqrt(...)`?

 + `exp * exp`, `exp / exp` The binary operator * / indicates multiplication and division operation. If both operands are int, the result is int; if one is int and one double, the former is converted to double, and the result is double; if both are double, the result is double. No other combinations are allowed.

 + `exp % exp` The binary % operator yields the remainder from the division of the first expression by the second. Both operands must be int, and the result is int.

 + `expr + expr`, `expr - expr` The result is the sum or different of the expressions. If both operands are int, the result is int. If both are double, the result is double. If one is int and one is double, the former is converted to double and the result is double.

 + equality/inequality:
   + `exp > exp`, `exp >= exp`, `exp < exp`, `exp <= exp` The operators < (less than), > (greater than), <= (less than or equal to) and >= (greater than or equal to) all yield 0
if the specified relation is false and 1 if it is true. Operand conversion is exactly the same as for the + operator.

   + `exp != exp`, `exp == exp` The != (not equal to) and the == (equal to) operators are exactly analogous to the relational operators except for their lower precedence. (Thus `a < b == c < d` is 1 whenever a < b and c < d have the same truth-value)

 + `expr || expr` The || operator returns 1 if either of its operands is non-zero, and 0 otherwise. It guarantees left-to-right evaluation; moreover, the second operand is not evaluated if the value of the first operand is non-zero.

 + `expr = expr`  It require an lvalue as their left operand, and the type of an assignment expression is that of its left operand. The value is the value stored in the left operand after the assignment has taken place.

 + `expression , expression` A pair of expressions separated by a comma is evaluated left-to-right and the value of the left expression is discarded. The type and value of the result are the type and value of the right operand.

#### Statements
##### Expression Statement
Expression statements are statement that includes an expression and a semicolon at the end:
```
expression;
```
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

##### Return Statement
Return statements are used inside functions. It has two possible forms:
```
return;
return expression;
```

##### Combining Statements
A statement can be the multiple of other statements. `{` and `}` are used to group multiple statements as one statement. So the form of compound statements is:
```
{ statement+ }
```

, which means that a compound statement has an opening curly bracket, one or more statements, and a closing curly bracket.

##### Context statement
A context statement include a context name and a compound statement:
```
context_name compound_statement
```

The statement after the colon will be evaluated in the context given by `context_name`.

##### Find Statement
Statements that are used in find statements:
```
// with_statement
with statement
```

Find statements start with keyword `find`, an expression, optional with_statements, and a statement:
```
find expression with_statement* statement
```

In a find statement, the last statement should be evaluated with access to previously declared expressions.

Examples of find statements:
```c
// a simple example
pendulum {
  velocity = length + 1
}
pendulum:find velocity with length = 5 {
  print(velocity)
} // print 6

// with vector assignment (causing equivalence of `for` loop in other languages)
pendulum:find vector with length = range(0, 5) {
  print(velocity)
} // print from 1 to 6
```

#### Built-in Functions


### Phase 2 of 4: Parser with `yacc`
TODO!

### Phase 3 of 4: Static Semantic Analysis
TODO!

### Phase 4 of 4: Code Generation
TODO!
