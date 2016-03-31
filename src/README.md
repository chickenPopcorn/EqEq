The "EqualsEquals" compiler
-------------------

Coded in OCaml, the "EqualsEquals" (aka "eqeq") language is designed for simple
mathematical equation evaluation. For more details, see its [Reference
Manual](../notes/language-reference-manual.md)
_("LRM" for "Language [RM]" in code and comments)_.

# Status [![Build Status](https://travis-ci.org/rxie25/PLT2016Spring.png?branch=master)](https://travis-ci.org/rxie25/PLT2016Spring)

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

# Development Workflow

To write code, please **read these quick-guides** below

1. [How & Where to Code](#how--where-to-code)
2. [Building & Testing](#building--testing)

## How & Where to Code

Use any editor you like, but **follow these steps for `git`**.

### Code in Branches

Say you're working on `fancyNewBuiltin()`

1. ensure your git repo is clean: `git status` _(and no output)_
2. `git checkout -b [yourhandle]-add-fancy-new-builtin`
3. before writing code:
  1. [write tests](#writing-tests)
  2. ensure they `FAIL`, since you haven't coded yet
  3. `git push origin [yourhandle]-add-fancy-new-builtin`
4. [open a pull request](https://help.github.com/articles/creating-a-pull-request/)
5. do these **until tests pass** and you're done:
  1. write code
  2. `make test`
  3. commit as you like
  4. address questions in pull request
6. [merge your branch](https://help.github.com/articles/merging-a-pull-request/)
  when its: **green** and **comments are resolved**
7. `git branch -d [yourhandle]-add-fancy-new-builtin`
8. back to step #1 with for **new branch name**

### Collaborating in Branches

Say tianci is working on "cool-feature". I (jon) want to use her work:

Q: How do I work with someone else's in-progress branch, `tianci-cool-feature`?
A:

1. ensure you're in a clean repo: `git status` _(should output nothing)_
2. ensure your laptop's updated: `git fetch --all`
3. **start your own branch**, eg: for `jon-cool-feature` do:
   `git checkout -b jon-cool-feature origin/tianci-cool-feature`

Now just continue with a normal ["Code in Branches"](#code-in-branches) process.

Q: I'm Tianci, how do I get Jon's fork back into my branch? A:

1. ensure you're in a clean repo: `git status` _(should output nothing)_
2. ensure your laptop's updated: `git fetch --all`
3. ensure your'e in original branch: `git branch` outputs  `tianci-cool-feature`
4. Merge the fork of your branch back in: `git merge origin/jon-cool-feature`

It helps if you're talking to each other, of course, to avoid confusion :)

## Building & Testing

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
