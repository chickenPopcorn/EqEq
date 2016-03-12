The "EqualsEquals" compiler
-------------------

Coded in OCaml, the "EqualsEquals" (aka "eqeq") language is designed for simple
mathematical equation evaluation. For more details, see its [Reference
Manual](https://docs.google.com/document/d/1uHGe2qazuy-I7Vem7u8muxDnWaysDX49lKMbMmlDml4)
_("LRM" for "Language [RM]" in code and comments)_.

## Building & Testing

To build and run end-to-end test suite:
```sh
$ make test # ie: `make && ./testall.sh`
ocamlbuild -use-ocamlfind -pkgs llvm,llvm.analysis -cflags -w,+a-4 microc.native
Finished, 22 targets (0 cached) in 00:00:01.
./testall.sh
test-arith1...OK
test-arith2...OK
test-arith3...OK
test-fib...OK
...
fail-while1...OK
fail-while2...OK
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
