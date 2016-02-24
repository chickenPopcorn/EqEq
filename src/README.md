The MicroC compiler
-------------------

Coded in OCaml, this takes a highly stripped-down subset of C (ints,
bools, and void types, arithmetic, if-else, for, and while statements,
and user-defined functions) and compiles it into LLVM IR.

## Building Testing

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
