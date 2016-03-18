# Changes to MicroC Codebase

At a high-level, this refactor:
- Rebrands to "microc" where convenient (eg: in comments, just in files touched)
- updates scanner and parser to adhere to our LRM (everything described below)

Below was written while trying to keep track of removals that are taking place,
in refactoring MicroC to match our LRM. This is necessary as a single list
rather than `git diff` which includes implementation-details' tangential
details. In other words, this document:
- includes, "change peg to be round"
- leaves out, "change holes 1,2,3,4,5,6,... to take round peg"

## ast.ml

In summary:
- removes: `Int`, `Void`, `Return`, `For`
- removes: `func_decl`'s `typ`, `formals`, `locals`
  - ie: `func_decl` is now our "multi-line equation"
- adds `find_decl`

```diff
-type typ = Int | Bool | Void
+type typ = Double | Bool


@@ -22,16 +22,19 @@ type expr =
 type stmt =
     Block of stmt list
   | Expr of expr
-  | Return of expr
   | If of expr * stmt * stmt
-  | For of expr * expr * expr * stmt
   | While of expr * stmt


@@ -28,10 +28,10 @@ type stmt =
 
 type func_decl = {
-    typ : typ;
     fname : string;
-    formals : bind list;
-    locals : bind list;
     body : stmt list;
   }

+type find_decl = {
 
@@ -84,17 +84,14 @@ let rec string_of_stmt = function

 let string_of_typ = function
-    Int -> "int"
+    Double -> "double"
-  | Void -> "void"
```

## scanner.mll

```diff
@@ -1,4 +1,4 @@
-(* Ocamllex scanner for MicroC *)
+(* Ocamllex scanner for EqualsEquals *)
 
@@ -27,14 +27,7 @@ rule token = parse
-| "for"    { FOR }
-| "return" { RETURN }
-| "int"    { INT }
-| "bool"   { BOOL }
-| "void"   { VOID }
-| "true"   { TRUE }
-| "false"  { FALSE }
```

## parser.mly

In summary:
- renames `fdecl` to `funcdecl`
  - removes `vdecl`
- adds `finddecl`
- updates `decls` to use it
- cleans up refs to removals made in ast.ml
- udates `expr` to remove concept of function calls (eg: `foo([opts])`)

```diff
- decls
+ decls

- fdecl
+ funcdecl

- vdecl

+ finddecl
```

# Effect of Changes

This all leaves the entire second-half of the compiler's pipeline broken, but
gives eqeq something to start with: **a working scanner & parser**. Well, at
least according to this test:
```bash
$ make clean
ocamlbuild -clean
rm -f testall.log *.diff microc scanner.ml parser.ml parser.mli parser.output
rm -f *.cmx *.cmi *.cmo *.cmx *.o
rm -f test-*.out test-*.ll

$ make scanner.ml
ocamllex scanner.mll
48 states, 1470 transitions, table size 6168 bytes

$ make parser.ml
ocamlyacc parser.mly
1 shift/reduce conflict.
```
TODO: fix this shift/reduce error ^
