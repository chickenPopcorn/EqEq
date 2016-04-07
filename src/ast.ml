(* Abstract Syntax Tree and functions for printing it   :*)

type op = Add | Sub | Mult | Div | Mod | Pow | Equal | Neq | Less | Leq | Greater | Geq |
          And | Or

type uop = Neg | Not | Abs

type expr =
    Literal of float
  | Id of string
  | Strlit of string
  | Binop of expr * op * expr
  | Unop of uop * expr
  | Assign of string * expr
  | Builtin of string * expr list

type stmt =
    Block of stmt list
  | Expr of expr
  | If of cond_exec list
  | While of expr * stmt

and cond_exec =
   CondExec of expr option * stmt list

(* func: we call this a "multi-line equation" *)
type multi_eq = {
    fname : string;
    fdbody : stmt list;
  }

type ctx_decl = {
    context : string;
    cbody : multi_eq list;
  }

type find_decl = {
    fcontext : string;
    ftarget : string;
    fbody : stmt list;
  }

type program = ctx_decl list * find_decl list
(* TODO: add this back when we get global equations multi_eq list*)

(* Pretty-printing functions *)

let string_of_op = function
    Add -> "+"
  | Sub -> "-"
  | Mult -> "*"
  | Div -> "/"
  | Mod -> "%"
  | Pow -> "^"
  | Equal -> "=="
  | Neq -> "!="
  | Less -> "<"
  | Leq -> "<="
  | Greater -> ">"
  | Geq -> ">="
  | And -> "&&"
  | Or -> "||"

let string_of_uop = function
    Neg -> "-"
  | Not -> "!"
  | Abs -> "|"

let rec string_of_expr = function
    Strlit(l) -> l
  | Literal(l) -> string_of_float l
  | Id(s) -> s
  | Binop(e1, o, e2) ->
      string_of_expr e1 ^ " " ^ string_of_op o ^ " " ^ string_of_expr e2
  | Unop(o, e) -> string_of_uop o ^ string_of_expr e
  | Assign(v, e) -> v ^ " = " ^ string_of_expr e
  | Builtin(f, el) ->
      f ^ "(" ^ String.concat ", " (List.map string_of_expr el) ^ ")"

let rec string_of_stmt = function
    Block(stmts) ->
      "{\n" ^ String.concat "" (List.map string_of_stmt stmts) ^ "}\n"
  | Expr(expr) -> string_of_expr expr ^ ";\n";
  | If(conds) -> string_of_first_cond_exec (List.hd conds) ^ "\n" ^
  (String.concat "\n" (List.map string_of_cond_exec (List.tl conds)))
  | While(e, s) -> "while (" ^ string_of_expr e ^ ") " ^ string_of_stmt s

and string_of_first_cond_exec = function
  | CondExec(None, stmts) -> "else:" ^ (String.concat "\n" (List.map string_of_stmt stmts))
  | CondExec(Some(expr), stmts) -> "if " ^ (string_of_expr expr) ^ ":\n" ^ (String.concat "\n" (List.map string_of_stmt stmts))

and string_of_cond_exec = function
  | CondExec(None, stmts) -> "else {\n" ^ (String.concat "\n" (List.map string_of_stmt stmts)) ^"}\n"
  | CondExec(Some(expr), stmts) -> "else if (" ^ (string_of_expr expr) ^ ")\n {\n" ^ (String.concat "\n" (List.map string_of_stmt stmts)) ^ "}\n"

let string_of_multieq multieq =
  multieq.fname ^
  " = {\n" ^
  String.concat "" (List.map string_of_stmt multieq.fdbody) ^
  "\n}\n"

let string_of_ctxdecl ctx =
  ctx.context ^
  " = {\n" ^
  String.concat "" (List.map string_of_multieq ctx.cbody) ^
  "\n}\n"

let string_of_finddecl finddecl =
  finddecl.fcontext ^
  ": find " ^
  finddecl.ftarget ^
  " {\n" ^
  String.concat "" (List.map string_of_stmt finddecl.fbody) ^
  "\n}\n"

let string_of_program (contexts, findexprs) =
  String.concat "" (List.map string_of_ctxdecl contexts) ^ "\n" ^
  String.concat "\n" (List.map string_of_finddecl findexprs)
