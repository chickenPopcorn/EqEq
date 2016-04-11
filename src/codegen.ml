(* Code generation: translates semantically checked AST & produces vanilla C. *)

module A = Ast
module S = Sast

module StringMap = Map.Make(String)

let translate sast =
  let (contexts, finds) = sast.S.ast in
  let varmap = sast.S.vars in

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
    | A.Builtin("print", el) -> let generate_expr el = List.map gen_expr el in
                                let check_type expr_str =
                                    match expr_str with
                                    | [] -> "printf()"
                                    | hd::tl -> if tl != [] then "printf(" ^ hd ^ ", " ^ 
                                                                 String.concat ", " (List.map (fun x -> "(double) (" ^ x ^ ")") tl) ^ 
                                                                 ")"
                                                else "printf(" ^ hd ^ ")"
                                in check_type (generate_expr el)
    | A.Builtin(f, el) -> f ^ "(" ^ String.concat ", " (List.map gen_expr el) ^ ")"
  in

  let rec gen_stmt = function
    | A.Block(stmts) ->
        "{\n" ^ String.concat "" (List.map gen_stmt stmts) ^ "}\n"
    | A.Expr(expr) -> gen_expr expr ^ ";\n";
    | A.While(e, s) -> "while (" ^ gen_expr e ^ ") " ^ gen_stmt s
    | A.If (l) ->  string_of_first_cond_exec (List.hd l) ^ "\n" ^
    (String.concat "\n" (List.map string_of_cond_exec (List.tl l)))

  and string_of_first_cond_exec = function
    | (Some(expr), A.Block(stmts)) -> "if (" ^ (gen_expr expr) ^ ")\n {\n" ^
                                          (String.concat "\n" (List.map gen_stmt stmts)) ^
                                      "}\n"
    | _ -> ""

  and string_of_cond_exec = function
    | (None, A.Block(stmts)) -> "else {\n" ^
                                    (String.concat "\n" (List.map gen_stmt stmts)) ^
                                "}\n"
    | (Some(expr), A.Block(stmts)) -> "else if (" ^ (gen_expr expr) ^ ")\n {\n" ^
                                           (String.concat "\n" (List.map gen_stmt stmts)) ^
                                      "}\n"
    | _ -> ""
  in
  let get_id_range finddecl =
    match finddecl.A.frange with
    | [] -> ""
    | hd :: tl -> (match hd with A.Range(id, st, ed) -> id)
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
  let gen_find_func_prototype_list finddecl_list = 
    let rec gen_find_func_prototype count find_list = 
      match find_list with
      | [] -> []
      | hd::tl -> ("void " ^ "find_" ^ hd.A.fcontext ^ "_" ^ (string_of_int count) ^ 
                   " (" ^ ((fun x -> match x with "" -> " "
                                                 | _ -> "double " ^ x ) (get_id_range hd)) ^ ")" 
                  )::(gen_find_func_prototype (count+1) tl)
    in List.rev (gen_find_func_prototype 0 finddecl_list)
  in 
  let gen_find_funcname_list finddecl_list = 
    let get_st_range finddecl =
      match finddecl.A.frange with
      | [] -> ""
      | hd :: tl -> (match hd with A.Range(id, st, ed) -> 
                     (match st, ed with A.Literal(lst), A.Literal(led) -> 
                                        if lst < led then string_of_float lst else string_of_float led
                                        | _ -> ""))
    in 
    let get_ed_range finddecl =
      match finddecl.A.frange with
      | [] -> ""
      | hd :: tl -> (match hd with A.Range(id, st, ed) -> 
                     (match st, ed with A.Literal(lst), A.Literal(led) -> 
                                        if lst < led then string_of_float led else string_of_float lst
                                        | _ -> ""))
    in
    let rec gen_find_funcname count find_list = 
      match find_list with
      | [] -> []
      | hd::tl -> (match get_id_range hd with
                   | "" ->  ("find_" ^ hd.A.fcontext ^ "_" ^ (string_of_int count) ^ 
                   " (" ^ get_id_range hd ^ ");\n" )::(gen_find_funcname (count+1) tl)
                   | _ -> ("double " ^ get_id_range hd ^ ";\n" ^ 
                   "for ( " ^ get_id_range hd ^ "=" ^ get_st_range hd ^ "; " ^
                   get_id_range hd ^ "<" ^ get_ed_range hd ^ "; " ^
                   get_id_range hd ^ "++) {\n" ^
                   "find_" ^ hd.A.fcontext ^ "_" ^ (string_of_int count) ^ 
                   " (" ^ get_id_range hd ^ ");\n" ^
                   "}\n") ::(gen_find_funcname (count+1) tl) 
                 )
    in List.rev (gen_find_funcname 0 finddecl_list)
  in
  let gen_find_function find_funcname finddecl =
    (* naming of the function: find_(context_name)_(golabl_counting_num) *)
    find_funcname ^ " {\n  " ^ 
    String.concat ""(List.map gen_decl_ctx contexts) ^ 
    String.concat ""(List.map gen_ctxdecl contexts) ^
    (gen_finddecl finddecl) ^ "}\n" ^
    "\n"
  in
  "#include <stdio.h>\n#include <math.h>\n" ^
  String.concat "" (List.map2 gen_find_function (gen_find_func_prototype_list finds) (List.rev finds)) ^
  "int main() {\n" ^
  String.concat "" (gen_find_funcname_list finds) ^
  " return 0;\n}\n"
