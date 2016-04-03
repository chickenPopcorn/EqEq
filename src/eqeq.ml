(* Top-level of the MicroC compiler:
 *  1. scan & parse input on stdin,
 *  2. check the resulting AST
 *  3. generate C
 *)

type cli_arg = Ast | Compile

exception Error of exn * (int * int * string * string)

let _ =
  let cli_arg =
    if Array.length Sys.argv > 1 then
      List.assoc Sys.argv.(1) [
        ("-a", Ast);       (* Print the AST only *)
        ("-c", Compile)    (* Generate, check C *)
      ]
    else Compile
  in

  (* Step 1: Scanner & Parser *)
  let lexbuf = Lexing.from_channel stdin in

  let ast =
    try
      Parser.program Scanner.token lexbuf
    with exn ->
      begin
        let curr = lexbuf.Lexing.lex_curr_p in
        let line = curr.Lexing.pos_lnum in
        let cnum = curr.Lexing.pos_cnum - curr.Lexing.pos_bol in
        let tok = Lexing.lexeme lexbuf in
        let tail = "rest of chars" in (* TODO *)
        raise (Error(exn,(line,cnum,tok,tail)))
      end
  in

  let sast = Semant.check ast in

  (* Steps 2 3 *)
  match cli_arg with
    Ast -> print_string (Ast.string_of_program ast)
  | Compile -> print_string (Codegen.translate sast)
