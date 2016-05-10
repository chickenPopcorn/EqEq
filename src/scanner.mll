(* Ocamllex scanner for EqualsEquals *)

{ open Parser }

let intgr = ['0'-'9']
let lowercase = ['a'-'z']
let uppercase = ['A'-'Z']
let alpha_num = lowercase | uppercase | intgr
let sign = '+' | '-'
let expo = 'e' | 'E'
let sci_note = expo sign? intgr+
let decimal = '.' intgr+
let frac = decimal sci_note? | decimal? sci_note

let num = '-'? (intgr+ frac? | intgr* frac)

let identifier = lowercase (alpha_num | '_')*
let context_id = uppercase identifier

let whitespace = [' ' '\t' '\r']
let newline = '\n' | "\r\n"
let reserved = ("int" | "double" | "char" | "float" | "const" | "void" | "short" | "struct"
				| "long" | "return" | "static" | "switch" | "case" | "default" | "for" | "do" | "goto"
				| "auto" | "signed" | "extern" | "register" | "enum" | "sizeof" | "typedef" | "union"
				| "volatile" | "Global")

rule token = parse
| whitespace                 { token lexbuf }
| "/*"                       { comment lexbuf }
| newline                    { Lexing.new_line lexbuf; token lexbuf }
| reserved as illegalid      { raise (Failure("illegal namespace " ^ String.escaped illegalid)) }
| '('                        { LPAREN }
| ')'                        { RPAREN }
| '{'                        { LBRACE }
| '}'                        { RBRACE }
| ';'                        { SEMI }
| ':'                        { COLON }
| ','                        { COMMA }
| '+'                        { PLUS }
| '-'                        { MINUS }
| '*'                        { TIMES }
| '/'                        { DIVIDE }
| '%'                        { MOD }
| '^'                        { POW }
| '|'                        { ABS }
| '='                        { ASSIGN }
| "=="                       { EQ }
| "!="                       { NEQ }
| '<'                        { LT }
| "<="                       { LEQ }
| ">"                        { GT }
| ">="                       { GEQ }
| "&&"                       { AND }
| "||"                       { OR }
| "!"                        { NOT }
| "if"                       { IF }
| "else"                     { ELSE }
| "while"                    { WHILE }
| "find"                     { FIND }
| "break"                    { BREAK }
| "continue"                 { CONTINUE }
| "with"                     { WITH }
| "in"                       { IN }
| "range"                    { RANGE }
| '"' (([^'"']*) as lxm) '"' { STRLIT(lxm) }
| num as lxm                 { LITERAL(float_of_string lxm) }
| identifier as lxm          { ID(lxm) }
| context_id as lxm          { CTX(lxm) }
| eof { EOF }
| _ as char                  { raise (Failure("illegal character " ^ Char.escaped char)) }

and comment = parse
  "*/" { token lexbuf }
| _    { comment lexbuf }

and ruleTail acc = parse
| eof { acc }
| _* as str { ruleTail (acc ^ str) lexbuf }
