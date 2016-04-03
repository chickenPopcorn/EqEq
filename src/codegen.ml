(* Code generation: translates semantically checked AST & produces vanilla C. *)

module A = Ast

module StringMap = Map.Make(String)

let translate (contexts, finds, varmap) =
  let rec gen_expr = function
    | A.Strlit(l) -> "\"" ^ l ^ "\""
    | A.Literal(l) -> string_of_float l
    | A.Id(s) -> s
    | A.Binop(e1, o, e2) -> let check_op o =
                                match A.string_of_op o with
                                | "%" -> "fmod(" ^ gen_expr e1 ^ ", " ^ gen_expr e2 ^ ")"
                                | "^" -> "pow(" ^ gen_expr e1 ^ ", " ^ gen_expr e2 ^ ")"
                                | _ -> gen_expr e1 ^ " " ^ A.string_of_op o ^ " " ^ gen_expr e2 in check_op o
    | A.Unop(o, e) -> let check_unop o =
                          match A.string_of_uop o with
                          | "|" -> "fabs(" ^ gen_expr e ^ ")"
                          | _ -> A.string_of_uop o ^ "(" ^ gen_expr e ^ ")" in check_unop o
    | A.Assign(v, e) -> v ^ " = " ^ gen_expr e
    | A.Builtin("print", el) -> "printf(" ^ String.concat ", " (List.map gen_expr el) ^ ")"
    | A.Builtin(f, el) -> f ^ "(" ^ String.concat ", " (List.map gen_expr el) ^ ")"
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
  let gen_decl_var varname funcdecl str =
    "double " ^ varname ^ ";\n" ^ str
  in
  let gen_decl_ctx ctx =
    StringMap.fold gen_decl_var (StringMap.find ctx.A.context varmap) "\n"
  in
  let gen_multieq multieq =
    multieq.A.fname ^
    " = " ^
    String.concat "" (List.map gen_stmt multieq.A.fdbody) ^
    "\n"
  in
  let gen_ctxdecl ctx =
    String.concat "" (List.map gen_multieq ctx.A.cbody)
  in
  let gen_finddecl finddecl = 
    String.concat "" (List.map gen_stmt finddecl.A.fbody)
  in
  let gen_find_funcname_list finddecl_list = 
    let rec gen_find_funcname count find_list = 
      match find_list with
      | [] -> []
      | hd::tl -> ("find_" ^ hd.A.fcontext ^ "_" ^ (string_of_int count))::(gen_find_funcname (count+1) tl)
    in List.rev (gen_find_funcname 0 finddecl_list)
  in 
  let gen_find_function find_funcname finddecl = 
    (* naming of the function: find_(context_name)_(golabl_counting_num) *)
    "void " ^ find_funcname ^ " () {\n  " ^ 
    String.concat ""(List.map gen_decl_ctx contexts) ^ 
    String.concat ""(List.map gen_ctxdecl contexts) ^
    (gen_finddecl finddecl) ^ "}\n" ^
    "\n"
  in
  let gen_findfunc_call find_funcname finddecl = 
    find_funcname ^ " ();\n"
  in

  "#include <stdio.h>\n#include <math.h>\n" ^
  (*String.concat "" (List.map gen_ctxdecl contexts) ^*)
  String.concat "" (List.map2 gen_find_function (gen_find_funcname_list finds) finds) ^
  "int main() {\n" ^
  String.concat "" (List.rev (List.map2 gen_findfunc_call (gen_find_funcname_list finds) finds)) ^
  " return 0;\n}\n"
