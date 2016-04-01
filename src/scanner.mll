(* Ocamllex scanner for EqualsEquals *)

{ open Parser }

let identifier = ['a'-'z'] ['a'-'z' 'A'-'Z' '0'-'9' '_']*
let context = ['A'-'Z'] identifier

let digit = ['0'-'9']
let e = ['e''E']
let sign = ['+''-']
let component = e sign? digit+


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
| digit+'.'digit*component? as lxm { LITERAL(float_of_string lxm) }
| digit*'.'digit+component? as lxm { LITERAL(float_of_string lxm) }
| digit+'.'?digit*component as lxm { LITERAL(float_of_string lxm) }
| digit+'.'?digit+component as lxm { LITERAL(float_of_string lxm) }
| digit+ as lxm { LITERAL(float_of_string lxm) }
| identifier as lxm { ID(lxm) }
| context as lxm { CTX(lxm) }
| eof { EOF }
| _ as char { raise (Failure("illegal character " ^ Char.escaped char)) }

and comment = parse
  "*/" { token lexbuf }
| _    { comment lexbuf }
