The "EqualsEquals" compiler
-------------------

Coded in OCaml, the "EqualsEquals" (aka "eqeq") language is designed for simple
mathematical equation evaluation. For more details, see its [Reference Manual]
_("LRM" for "Language [RM]" in code and comments)_.

- [Status](#status-)
- [Coding, Building, Testing](#coding-building-testing)
  - [Writing Tests](#writing-tests)
  - [Debugging Tools](#debugging-tools)
  - [One-time Setup](#one-time-setup)
    - [Quickstart](#quickstart)

## Status [![Build Status][buildbadge]][travisci]

Currently we're working towards a ["final report" milestone][milestone]; eg:

 - [x] **fixed** ~~in testing: keeping our build passing at every commit on `master` branch~~
 - [x] **fixed** ~~in issues #12 #15:~~
      - ~~make real phases~~
      - ~~replace [_hard-coded behaviour_][dummycodegen]~~
 - [ ] **adding new** [tests for each new feature](#writing-tests)
 - [ ] **more interesting**: [semantic analysis:#24][GH24] and [code generation:#14][GH14]
 - [ ] [unraveling TODOs] and large [meta-issues]

The codebase was recently refactored to represent the eqeq LRM, rather than
MicroC's, so it's safe to assume if a line of code looks too simple, you're
right! We were just trying to get somethin to compile, so we could all run `make
test` reliably.

## Coding, Building, Testing

To **code**, please see [contributing](CONTRIBUTING.md) quickguide.

To **build**, simply: `make`

To run **all end-to-end checks**, simply: `make e2e`.
- or just run `make lint` to see non-test checks
- or just run `make test` to see input/output checks:

  ```sh
  $ make test # or: `make TEST_OPTS=-h test` or any other options it takes

  #... {clean, build, etc.}-output snipped...

  Running 1 tests:
          tests/test-helloworld.eq,
  [1] "test-helloworld"   asserting target's behavior             Result: PASS

  Summary: PASSED
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

### Debugging Tools
See what our scanner thinks of source programs, with `debugtokens` target:
```sh
$ make debugtokens && ./debugtokens.native < tests/test-helloworld.eq
bash -c 'source ~/.opam/opam-init/init.sh && ocamlbuild -use-ocamlfind ./debugtokens.native'
# .. snipped `ocamlfind` commands ...
File "ast.ml", line 68, characters 25-390:
Warning 8: this pattern-matching is not exhaustive.
Here is an example of a value that is not matched:
Strlit _
/usr/bin/ocamllex.opt -q scanner.mll
# .. snipped `ocamlfind` commands ...
File "ast.ml", line 68, characters 25-390:
Warning 8: this pattern-matching is not exhaustive.
Here is an example of a value that is not matched:
Strlit _
# .. snipped `ocamlfind` commands ...
CTX
ASSIGN
LBRACE
ID
ASSIGN
LBRACE
LITERAL
SEMI
RBRACE
RBRACE
CTX
COLON
FIND
ID
LBRACE
ID
LPAREN
STRLIT
COMMA
ID
RPAREN
SEMI
RBRACE
```

Interactive mode with menhir and our parser:
```sh
$ menhir --interpret --interpret-show-cst parser.mly # note missing ASSIGN
CTX LBRACE ID ASSIGN LITERAL SEMI RBRACE

REJECT
```

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

[buildbadge]: https://travis-ci.org/rxie25/PLT2016Spring.png?branch=master
[travisci]: https://travis-ci.org/rxie25/PLT2016Spring
[milestone]: https://github.com/rxie25/PLT2016Spring/milestones/DUE:%20Final%20Report
[Reference Manual]: ../notes/language-reference-manual.md
[unraveling TODOs]: https://github.com/rxie25/PLT2016Spring/search?utf8=%E2%9C%93&q=TODO
[dummycodegen]: https://github.com/rxie25/PLT2016Spring/blob/85e99570cd813398/src/codegen.ml#L14-L16
[GH24]: https://github.com/rxie25/PLT2016Spring/issues/24
[GH14]: https://github.com/rxie25/PLT2016Spring/issues/14
[meta-issues]: https://github.com/rxie25/PLT2016Spring/issues?q=is%3Aissue+is%3Aopen+label%3A%22issue+compilation%22
