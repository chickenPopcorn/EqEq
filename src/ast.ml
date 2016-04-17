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
   (* Block of stmt list *)
  | Expr of expr
  | If of (expr option * stmt list) list
  | While of expr * stmt list
  | Break 
  | Continue 

type range =
  | Range of string * expr * expr option * expr option

(* multieq: we call this a "multi-line equation" *)
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
    frange: range list;
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
   (* Block(stmts) ->
      "{\n" ^ String.concat "" (List.map string_of_stmt stmts) ^ "}\n" *)
  | Expr(expr) -> string_of_expr expr ^ ";\n";
  | If(conds) -> "\n" ^ string_of_first_cond_stmts (List.hd conds) ^ "\n" ^
  (String.concat "\n" (List.map string_of_cond_stmts (List.tl conds)))
  | While(e, s) -> "while (" ^ string_of_expr e ^ ") " ^ "{" ^ String.concat "\n" (List.map string_of_stmt s) ^ "}"
  | Break -> "break"
  | Continue -> "continue"

  and string_of_first_cond_stmts = function
    | (None, stmts) -> "else {\n" ^ (String.concat "\n" (List.map string_of_stmt stmts))
    | (Some(expr), stmts) -> "if (" ^ (string_of_expr expr) ^ ")\n {\n" ^
                                        (String.concat "\n" (List.map string_of_stmt stmts)) ^
                                    "}\n"
  and string_of_cond_stmts = function
    | (None, stmts) -> "else {\n" ^ (String.concat "\n" (List.map string_of_stmt stmts)) ^"}\n"
    | (Some(expr), stmts) -> "else if (" ^ (string_of_expr expr) ^ ")\n {\n" ^
                                    (String.concat "\n" (List.map string_of_stmt stmts)) ^ "}\n"

let string_of_range range =
   match range with
   | [] -> ""
   | hd::tl -> (match hd with Range(id, st, ed, inc) ->
                (match st, ed, inc with
                  | Literal(lst), Some(sed), Some(sinc) ->
                    (match sed, sinc with Literal(led), Literal(linc) ->
                                   " " ^ id ^ " in range(" ^ string_of_float lst ^ "," ^
                                   string_of_float led ^ ")"
                                   | _ -> "")
                  | Literal(lst), Some(sed), None ->
                    (match sed with Literal(led) ->
                                   " " ^ id ^ " in range(" ^ string_of_float lst ^ "," ^
                                   string_of_float led ^ ")"
                                   | _ -> "")
                  | Literal(lst), None, None ->
                                   " " ^ id ^ " in range(" ^ string_of_float lst ^ ")"
                  | _ -> ""))

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
  string_of_range finddecl.frange ^
  " {\n" ^
  String.concat "" (List.map string_of_stmt finddecl.fbody) ^
  "\n}\n"

let string_of_program (contexts, findexprs) =
  String.concat "" (List.map string_of_ctxdecl contexts) ^ "\n" ^
  String.concat "\n" (List.map string_of_finddecl findexprs)
