(* Ocamllex scanner for EqualsEquals *)

{ open Parser }

let integer = ['0'-'9']
let lowercase = ['a'-'z']
let uppercase = ['A'-'Z']
let identifier = lowercase (lowercase | uppercase | integer | '_')*
let context_id = uppercase identifier

let num = integer+'.'integer*(['e''E']['+''-']?integer+)?
  | integer*'.'integer+(['e''E']['+''-']?integer+)?
  | integer+'.'?integer*['e''E']['+''-']?integer+
  | integer+'.'?integer+['e''E']['+''-']?integer+
  | integer+

rule token = parse
  [' ' '\t' '\r' '\n'] { token lexbuf } (* Whitespace *)
| "/*"     { comment lexbuf }           (* Comments *)
| '('      { LPAREN }
| ')'      { RPAREN }
| '{'      { LBRACE }
| '}'      { RBRACE }
| ';'      { SEMI }
| ':'      { COLON }
| ','      { COMMA }
| '+'      { PLUS }
| '-'      { MINUS }
| '*'      { TIMES }
| '/'      { DIVIDE }
| '%'      { MOD }
| '^'      { POW }
| '|'      { ABS }
| '='      { ASSIGN }
| "=="     { EQ }
| "!="     { NEQ }
| '<'      { LT }
| "<="     { LEQ }
| ">"      { GT }
| ">="     { GEQ }
| "&&"     { AND }
| "||"     { OR }
| "!"      { NOT }
| "if"     { IF }
| "else"   { ELSE }
| "while"  { WHILE }
| "find"   { FIND }
| '"' (([^'"']*) as lxm) '"' { STRLIT(lxm) }
| num as lxm { LITERAL(float_of_string lxm) }
| identifier as lxm { ID(lxm) }
| context_id as lxm { CTX(lxm) }
| eof { EOF }
| _ as char { raise (Failure("illegal character " ^ Char.escaped char)) }

and comment = parse
  "*/" { token lexbuf }
| _    { comment lexbuf }
