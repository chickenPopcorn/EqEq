(* Top-level of the MicroC compiler:
 *  1. scan & parse input on stdin,
 *  2. check the resulting AST
 *  3. generate C
 *)

type cli_arg = Ast | Compile

let _ =
  let cli_arg =
    if Array.length Sys.argv > 1 then
      List.assoc Sys.argv.(1) [
        ("-a", Ast);        (* Print the AST only *)
         ("-c", Compile)    (* Generate, check C *)
      ]
    else Compile
  in

  let lexbuf = Lexing.from_channel stdin in
  let ast = Parser.program Scanner.token lexbuf in

  (* Step 1: Scanner & Parser *)
  Semant.check ast;

  (* Steps 2 3 *)
  match cli_arg with
    (* Ast -> print_string (Ast.string_of_program ast);
  | Compile -> print_string Codegen.translate ast; *)
    Ast ->  Ast.string_of_program ast;
  | Compile ->  Codegen.translate ast;
