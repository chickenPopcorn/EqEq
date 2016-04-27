(* Top-level of the EqualsEquals compiler:
 *  0. accept debugging commandline flags,
 *  1. bind scanner to stdin as input,
 *  2. parse scanned tokens into AST,
 *  3. semantic analysis of AST, into SAST,
 *  4. codegen of from SAST
 *)

type cli_arg = Ast | Compile

exception Error of string

let _ =
  (* Step 0: Debug flags *)
  let cli_arg =
    if Array.length Sys.argv > 1 then
      List.assoc Sys.argv.(1) [
        ("-a", Ast);       (* Print the AST only *)
        ("-c", Compile)    (* Generate, check C *)
      ]
    else Compile
  in

  (* Step 1: Scanner (starts here) *)
  let lexbuf = Lexing.from_channel stdin in

  (* Step 2: Parser *)
  let ast =
    try
      Parser.program Scanner.token lexbuf
    with exn ->
      begin
        let curr = lexbuf.Lexing.lex_curr_p in
        let line = string_of_int curr.Lexing.pos_lnum in
        let cnum = string_of_int (curr.Lexing.pos_cnum - curr.Lexing.pos_bol) in
        let tok = Lexing.lexeme lexbuf in
      (*let tail = Scanner.ruleTail "" lexbuf in*)

        let messageForError e =
          "line " ^ line ^
          " (char " ^ cnum ^ "): " ^
          "'" ^ tok ^ "'" ^ ""
          (* TODO: call `^ "\n" ^ tail` here on limited for 40 chars or so *)
        in
        raise (Error(messageForError exn))
      end
  in

  (* Steps 3: Semantic Analysis *)
  let sast = Semant.check ast in

  (* Steps 4: Codegen *)
  match cli_arg with
  | Ast -> print_string (Ast.string_of_program ast)

  | Compile -> print_string (Codegen.translate sast)
