/* Ocamlyacc parser for EqualsEquals */

%{
open Ast
%}

%token SEMI LPAREN RPAREN LBRACE RBRACE COMMA COLON
%token PLUS MINUS TIMES DIVIDE MOD POW ABS ASSIGN NOT
%token EQ NEQ LT LEQ GT GEQ AND OR
%token IF ELSE WHILE FIND WITH IN RANGE BREAK CONTINUE
%token <float> LITERAL
%token <string> ID
%token <string> STRLIT
%token <string> CTX
%token EOF

%right ASSIGN
%left OR
%left AND
%left EQ NEQ
%left LT GT LEQ GEQ
%left PLUS MINUS
%left TIMES DIVIDE MOD POW
%right NOT NEG

%start program
%type <Ast.program> program

%%

program:
  decls EOF { $1 }

decls:
   /* nothing */     { [], [] }
 | decls ctxtdecl    { ($2 :: fst $1), snd $1 }
 | decls finddecl    { fst $1, ($2 :: snd $1) }
/**
 * TODO: add ability for global-context function declarations to exist:
 * What does statement-action look like? Does it matter? Probably needs to be
 * prioritized higher than both contexts and find blocks :|
 *
 *  | decls funcdecl { fst $1, ($2 :: snd $1) }
 *
 */

/* TODO: improve funcdeclt_list to make it better */
ctxtdecl:
  | CTX ASSIGN LBRACE funcdecl_list RBRACE
    { { context = $1; cbody = List.rev $4 } }
  | global_assign global_assign_list SEMI
    { { context = "Global"; cbody = $1 :: (List.rev $2) } }


global_assign:
  | ID ASSIGN LITERAL
    { { fname = $1; fdbody = [Expr(Literal($3))] } }

global_assign_list:
   /* nothing */ { [] }
  | global_assign_list COMMA global_assign { $3 :: $1 }

funcdecl:
    ID ASSIGN LBRACE stmt_list RBRACE
      { { fname = $1; fdbody = List.rev $4 } }  
  | ID ASSIGN stmt
      { { fname = $1; fdbody = [$3] } }

finddecl:
   FIND ID LBRACE stmt_list RBRACE
     { { fcontext = "Global"; (* global context *)
         ftarget = $2;
         frange = [];
         fbody = List.rev $4 } }
 | CTX COLON FIND ID LBRACE stmt_list RBRACE
     { { fcontext = $1;
         ftarget = $4;
         frange = [];
         fbody = List.rev $6 } }
 | FIND ID WITH stmt_list LBRACE stmt_list RBRACE
     { { fcontext = "Global"; (* global context *)
         ftarget = $2;
         frange = [];
         fbody = (List.rev $4) @ (List.rev $6) } }
 | CTX COLON FIND ID WITH stmt_list LBRACE stmt_list RBRACE
     { { fcontext = $1;
         ftarget = $4;
         frange = [];
         fbody = (List.rev $6) @ (List.rev $8) } }
 | FIND ID WITH stmt_list range LBRACE stmt_list RBRACE
     { { fcontext = "Global"; (* global context *)
         ftarget = $2;
         frange = [$5];
         fbody = (List.rev $4) @ (List.rev $7) } }
 | CTX COLON FIND ID WITH stmt_list range LBRACE stmt_list RBRACE
     { { fcontext = $1;
         ftarget = $4;
         frange = [$7];
         fbody = (List.rev $6) @ (List.rev $9) } }


funcdecl_list:
    /* nothing */  { [] }
  | funcdecl_list funcdecl { $2 :: $1 }

stmt_list:
    /* nothing */  { [] }
  | stmt_list stmt { $2 :: $1 }

/*
findpost_list:
                               { [], [] }
 | findpost_list stmt_list     { ($2 :: fst $1), snd $1 }
 | findpost_list range_list    { fst $1, ($2 :: snd $1) }

range_list:
      { [] }
  | range_list range { $2 :: $1 }
*/

range:
  | ID IN RANGE LPAREN literal RPAREN SEMI {Range($1, $5, None, None)}
  | ID IN RANGE LPAREN literal COMMA literal RPAREN SEMI {Range($1, $5, Some($7), None)}
  | ID IN RANGE LPAREN literal COMMA literal COMMA literal RPAREN SEMI {Range($1, $5, Some($7), Some($9))}

stmt:
    expr SEMI { Expr $1 }
  | IF LPAREN expr RPAREN LBRACE stmt_list RBRACE elif_stmt_list else_stmt{ If(List.rev ($9 @ List.rev $8 @ [(Some($3), List.rev $6) ])) }
  | WHILE LPAREN expr RPAREN LBRACE stmt_list RBRACE { While($3, $6) }
  | BREAK SEMI { Break }
  | CONTINUE SEMI { Continue }

elif_stmt_list:
    /* nothing */ { [] }
    | elif_stmt_list elif_stmt { $1 @ $2 }

elif_stmt:
    | ELSE IF LPAREN expr RPAREN LBRACE stmt_list RBRACE { [(Some($4), List.rev $7)] }

else_stmt:
    /* nothing */ { [] }
    | ELSE LBRACE stmt_list RBRACE { [(None, List.rev $3)] }

expr:
    literal          { $1 }
  | ID               { Id($1) }
  | expr PLUS   expr { Binop($1, Add,   $3) }
  | expr MINUS  expr { Binop($1, Sub,   $3) }
  | expr TIMES  expr { Binop($1, Mult,  $3) }
  | expr DIVIDE expr { Binop($1, Div,   $3) }
  | expr MOD    expr { Binop($1, Mod,   $3) }
  | expr POW    expr { Binop($1, Pow,   $3) }
  | ABS expr ABS     { Unop(Abs, $2) }
  | expr EQ     expr { Binop($1, Equal, $3) }
  | expr NEQ    expr { Binop($1, Neq,   $3) }
  | expr LT     expr { Binop($1, Less,  $3) }
  | expr LEQ    expr { Binop($1, Leq,   $3) }
  | expr GT     expr { Binop($1, Greater, $3) }
  | expr GEQ    expr { Binop($1, Geq,   $3) }
  | expr AND    expr { Binop($1, And,   $3) }
  | expr OR     expr { Binop($1, Or,    $3) }
  | MINUS expr %prec NEG { Unop(Neg, $2) }
  | NOT expr         { Unop(Not, $2) }
  | ID ASSIGN expr   { Assign($1, $3) } 
  | ID LPAREN actuals_opt RPAREN { Builtin($1, $3) }
  | LPAREN expr RPAREN { $2 }

literal:
    LITERAL { Literal($1) }
  | STRLIT  { Strlit($1) }

actuals_opt:
    /* nothing */ { [] }
  | actuals_list  { List.rev $1 }

actuals_list:
    expr                    { [$1] }
  | actuals_list COMMA expr { $3 :: $1 }
