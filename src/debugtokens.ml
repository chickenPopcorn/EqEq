open Parser
open Ast

let stringify = function
  | LPAREN -> "LPAREN"
  | RPAREN -> "RPAREN"
  | LBRACE -> "LBRACE"
  | RBRACE -> "RBRACE"
  | SEMI -> "SEMI"
  | COLON -> "COLON"
  | COMMA -> "COMMA"
  | PLUS -> "PLUS"
  | MINUS -> "MINUS"
  | TIMES -> "TIMES"
  | DIVIDE -> "DIVIDE"
  | MOD -> "MOD"
  | POW -> "POW"
  | ABS -> "ABS"
  | ASSIGN -> "ASSIGN"
  | EQ -> "EQ"
  | NEQ -> "NEQ"
  | LT -> "LT"
  | LEQ -> "LEQ"
  | GT -> "GT"
  | GEQ -> "GEQ"
  | AND -> "AND"
  | OR -> "OR"
  | NOT -> "NOT"
  | IF -> "IF"
  | ELSE -> "ELSE"
  | ELIF -> "ELIF"
  | WHILE -> "WHILE"
  | STRLIT(lxm) -> "STRLIT"
  | FIND -> "FIND"
  | LITERAL(lxm) -> "LITERAL"
  | ID(lxm) -> "ID"
  | CTX(lxm) -> "CTX"
  | EOF -> "EOF"

let _ =
  let lexbuf = Lexing.from_channel stdin in
  let rec print_tokens = function
    | EOF -> " "
    | token ->
      print_endline (stringify token);
      print_tokens (Scanner.token lexbuf) in
  print_tokens (Scanner.token lexbuf)
