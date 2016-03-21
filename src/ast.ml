(* Abstract Syntax Tree and functions for printing it *)

type op = Add | Sub | Mult | Div | Equal | Neq | Less | Leq | Greater | Geq |
          And | Or

type uop = Neg | Not

type typ = Double | Bool

type bind = typ * string

type expr =
    Literal of int
  | Id of string
  | Binop of expr * op * expr
  | Unop of uop * expr
  | Assign of string * expr
  | Builtin of string * expr list
  | Noexpr

type stmt =
    Block of stmt list
  | Expr of expr
  | If of expr * stmt * stmt
  | While of expr * stmt

type ctx_decl = {
    context : string;
    body : stmt list;
  }

(* func: we call this a "multi-line equation" *)
type func_decl = {
    fname : string;
    body : stmt list;
  }

type find_decl = {
    context : string;
    target : string;
    body : stmt list;
  }

type program = ctx_decl list * find_decl list
(* TODO: add this back when we get global equations func_decl list*)

(* Pretty-printing functions *)

let string_of_op = function
    Add -> "+"
  | Sub -> "-"
  | Mult -> "*"
  | Div -> "/"
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

let rec string_of_expr = function
    Literal(l) -> string_of_int l
  | Id(s) -> s
  | Binop(e1, o, e2) ->
      string_of_expr e1 ^ " " ^ string_of_op o ^ " " ^ string_of_expr e2
  | Unop(o, e) -> string_of_uop o ^ string_of_expr e
  | Assign(v, e) -> v ^ " = " ^ string_of_expr e
  | Builtin(f, el) ->
      f ^ "(" ^ String.concat ", " (List.map string_of_expr el) ^ ")"
  | Noexpr -> ""

let rec string_of_stmt = function
    Block(stmts) ->
      "{\n" ^ String.concat "" (List.map string_of_stmt stmts) ^ "}\n"
  | Expr(expr) -> string_of_expr expr ^ ";\n";
  | If(e, s, Block([])) -> "if (" ^ string_of_expr e ^ ")\n" ^ string_of_stmt s
  | If(e, s1, s2) ->  "if (" ^ string_of_expr e ^ ")\n" ^
      string_of_stmt s1 ^ "else\n" ^ string_of_stmt s2
  | While(e, s) -> "while (" ^ string_of_expr e ^ ") " ^ string_of_stmt s

let string_of_typ = function
    Double -> "double"
  | Bool -> "bool"

let string_of_ctxdecl ctx =
  ctx.context ^
  " = {\n" ^
  String.concat "" (List.map string_of_stmt ctx.body) ^
  "\n}\n"

let string_of_finddecl finddecl =
  finddecl.context ^
  ": find " ^
  finddecl.target ^
  " {\n" ^
  String.concat "" (List.map string_of_stmt finddecl.body) ^
  "\n}\n"

let string_of_funcdecl funcdecl =
  funcdecl.fname ^
  " = {\n" ^
  String.concat "" (List.map string_of_stmt funcdecl.body) ^
  "\n}\n"

let string_of_program (contexts, findexprs) =
  String.concat "" (List.map string_of_ctxdecl contexts) ^ "\n" ^
  String.concat "\n" (List.map string_of_finddecl findexprs)
