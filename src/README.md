The "EqualsEquals" compiler
-------------------

Coded in OCaml, the "EqualsEquals" (aka "eqeq") language is designed for simple
mathematical equation evaluation. For more details, see its [Reference
Manual](../notes/language-reference-manual.md)
_("LRM" for "Language [RM]" in code and comments)_.

## Status [![Build Status](https://travis-ci.org/rxie25/PLT2016Spring.png?branch=master)](https://travis-ci.org/rxie25/PLT2016Spring)

Currently we're working towards a ["hello world" milestone](https://github.com/rxie25/PLT2016Spring/milestones/Hello%20World); eg:

 - [x] **fixed** in testing: **keeping our build passing** at every commit on `master` branch
 - [x] **fixed** in issues #12 #15:
      - make real phases: slowly [_unraveling TODOs_](https://github.com/rxie25/PLT2016Spring/search?utf8=%E2%9C%93&q=TODO)
      - replace [_hard-coded behaviour_](https://github.com/rxie25/PLT2016Spring/blob/85e99570cd813398/src/codegen.ml#L14-L16)
 - [ ] **adding new** tests: `tests/test-*.eq` and `tests/fail-*eq` for each new bit of functionality
 - [ ] **more interesting**: [semantic analysis:#24](https://github.com/rxie25/PLT2016Spring/issues/24) and [code generation:#14](https://github.com/rxie25/PLT2016Spring/issues/14)

The codebase was recently refactored to represent the eqeq LRM, rather than
MicroC's, so it's safe to assume if a line of code looks too simple, you're
right! We were just trying to get somethin to compile, so we could all run `make
test` reliably.

## Building & Testing

To build, simply: `make`

To Run end-to-end test suite:
```sh
$ make test # or: `make TEST_OPTS=-h test` or any other options it takes

#... {clean, build, etc.}-output snipped...

Running 1 tests:
        tests/test-helloworld.eq,
[1] "test-helloworld"   asserting target's behavior             Result: PASS

Summary: PASSED

```

Be sure to run `make lint` from time to time.

### Writing Tests
So you wrote a feature, like... a `CrazyNewKeyword` that shuts down user's
computer? Great! Do this:
```sh
$ $EDIT tests/test-crazynewkeyword.eq  # ideal case, capturing the complexity you've added (a correct program)
$ $EDIT tests/test-crazynewkeyword.out # what your example compiled eq C program should do (just the output)
$ make test
$ $EDIT tests/fail-crazynewkeyword.eq  # misuse you can think of (an incorrect program)
$ $EDIT tests/fail-crazynewkeyword.err # how our compiler should complain for your example eq source
$ make test
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

### Quickstart

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
