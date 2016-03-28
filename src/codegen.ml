(* Code generation: translates semantically checked AST & produces vanilla C. *)

module A = Ast

module StringMap = Map.Make(String)

let translate (contexts, finds) =
  let rec gen_expr = function
    | A.Strlit(l) -> "\"" ^ l ^ "\""
    | A.Literal(l) -> string_of_int l
    | A.Id(s) -> s
    | A.Binop(e1, o, e2) ->
        gen_expr e1 ^ " " ^ A.string_of_op o ^ " " ^ gen_expr e2
    | A.Unop(o, e) -> A.string_of_uop o ^ gen_expr e
    | A.Assign(v, e) -> v ^ " = " ^ gen_expr e
    | A.Builtin("print", el) -> "printf(" ^ String.concat ", " (List.map gen_expr el) ^ ")"
    | A.Builtin(f, el) -> f ^ "(" ^ String.concat ", " (List.map gen_expr el) ^ ")"
    | A.Noexpr -> ""
  in
  let rec gen_stmt = function
    | A.Block(stmts) ->
        "{\n" ^ String.concat "" (List.map gen_stmt stmts) ^ "}\n"
    | A.Expr(expr) -> gen_expr expr ^ ";\n";
    | A.If(e, s, Block([])) -> "if (" ^ gen_expr e ^ ")\n" ^ gen_stmt s
    | A.If(e, s1, s2) ->  "if (" ^ gen_expr e ^ ")\n" ^
        gen_stmt s1 ^ "else\n" ^ gen_stmt s2
    | A.While(e, s) -> "while (" ^ gen_expr e ^ ") " ^ gen_stmt s
  in
  let gen_funcdecl funcdecl =
    "double " ^
    funcdecl.A.fname ^
    " = " ^
    String.concat "" (List.map gen_stmt funcdecl.A.body) ^
    "\n"
  in
  let gen_ctxdecl ctx =
    String.concat "" (List.map gen_funcdecl ctx.A.body)
  in
  let gen_finddecl finddecl =
    String.concat "" (List.map gen_stmt finddecl.A.fbody) ^
    "\n"
  in
  "#include <stdio.h>\n" ^
  "int main() {\n" ^
  String.concat "" (List.map gen_ctxdecl contexts) ^
  String.concat "" (List.map gen_finddecl finds) ^
  "return 0;\n}\n"
