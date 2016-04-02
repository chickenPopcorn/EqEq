(* Ocamllex scanner for EqualsEquals *)

{ open Parser }

let identifier = ['a'-'z'] ['a'-'z' 'A'-'Z' '0'-'9' '_']*
let context = ['A'-'Z'] identifier

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
| "with"   { WITH }
| '"' (([^'"']*) as lxm) '"' { STRLIT(lxm) }
| ['0'-'9']+|(['0'-'9']+['.']['0'-'9']*) as lxm { LITERAL(float_of_string lxm) }
| identifier as lxm { ID(lxm) }
| context as lxm { CTX(lxm) }
| eof { EOF }
| _ as char { raise (Failure("illegal character " ^ Char.escaped char)) }

and comment = parse
  "*/" { token lexbuf }
| _    { comment lexbuf }
