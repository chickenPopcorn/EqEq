(* Top-level of the MicroC compiler:
 *  1. scan & parse input on stdin,
 *  2. check the resulting AST
 *  3. generate C
 *  4. dump the module
 *)

type cli_arg = Ast | Compile | DummyGen

let c_prgm =
  let cli_arg =
    if Array.length Sys.argv > 1 then
      List.assoc Sys.argv.(1) [
        ("-a", Ast);        (* Print the AST only *)
         ("-d", DummyGen);  (* Dumbly generate C, w/o checking *)
         ("-c", Compile)    (* Generate, check C *)
      ]
    else Compile
  in

  let lexbuf = Lexing.from_channel stdin in
  let ast = Parser.program Scanner.token lexbuf in

  (* Step 1: Scanner & Parser *)
  Semant.check ast;

  (* Steps 2 (optionally 3) and 4 *)
  match cli_arg with
    Ast -> (Ast.string_of_program ast)
  | DummyGen -> (Codegen.string_of_module (Codegen.translate ast))
  | Compile ->
      let m = Codegen.translate ast in
      Codegen.assert_valid_module m;
      (Codegen.string_of_llmodule m)

in print_string c_prgm
