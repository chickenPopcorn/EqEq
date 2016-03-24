The "EqualsEquals" compiler
-------------------

Coded in OCaml, the "EqualsEquals" (aka "eqeq") language is designed for simple
mathematical equation evaluation. For more details, see its [Reference
Manual](https://docs.google.com/document/d/1uHGe2qazuy-I7Vem7u8muxDnWaysDX49lKMbMmlDml4)
_("LRM" for "Language [RM]" in code and comments)_.

## Status [![Build Status](https://travis-ci.org/rxie25/PLT2016Spring.png?branch=master)](https://travis-ci.org/rxie25/PLT2016Spring)

Currently the codebase is being refactored to repressent the eqeq LRM, rather
than MicroC's spec, which we forked from. See [microc-to-eqeq](../notes/microc-to-eqeq.md) for the
list of ongoing changes.

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
