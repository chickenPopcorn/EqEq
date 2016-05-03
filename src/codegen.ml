(* Code generation: translates semantically checked AST & produces vanilla C. *)

module A = Ast
module S = Sast

module StringMap = Map.Make(String)


let translate sast =
  let (contexts, finds) = sast.S.ast in
  let varmap = sast.S.vars in
  let liblist = sast.S.lib in
  let eqs = sast.S.eqs in

  let fail msg = raise (Failure msg) in

  (* SAST helper functions *)
  let get_deps_indeps_from_context ctxname =
    let ctx_sast = StringMap.find ctxname eqs in
    (ctx_sast.S.ctx_deps, ctx_sast.S.ctx_indeps)
  in

  (* SAST helper functions end *)

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
    | A.Expr(expr) -> gen_expr expr ^ ";\n";
    | A.While(e, stmts) -> "while (" ^ gen_expr e ^ "){\n" ^ String.concat "\n" (List.rev (List.map gen_stmt stmts)) ^ "}\n"
    | A.Continue -> "continue;\n"
    | A.Break -> "break;\n"
    | A.If (l) ->  string_of_first_cond_exec (List.hd l) ^ "\n" ^
    (String.concat "\n" (List.map string_of_cond_exec (List.tl l)))

  and string_of_first_cond_exec = function
    | (Some(expr), stmts) -> "if (" ^ (gen_expr expr) ^ ")\n {\n" ^
                                          (String.concat "\n" (List.map gen_stmt stmts)) ^
                                      "}\n"
    | _ -> ""

  and string_of_cond_exec = function
    | (None, stmts) -> "else {\n" ^
                                    (String.concat "\n" (List.map gen_stmt stmts)) ^
                                "}\n"
    | (Some(expr), stmts) -> "else if (" ^ (gen_expr expr) ^ ")\n {\n" ^
                                           (String.concat "\n" (List.map gen_stmt stmts)) ^
                                      "}\n"
  in
    (* param is_indeps: whether the stmt is generated for a variable in indeps *)
  let rec gen_stmt_for_multieq is_indeps = function
    | A.Expr(expr) -> (
        match expr with
        | A.Builtin("print", el) -> gen_expr expr ^ ";\n"
        | A.Assign(left, expr) ->  (
                match expr with
                | A.Literal(l) -> "double " ^left ^ "=" ^ string_of_float l ^ ";\n"
                | _ -> left ^ "=" ^ gen_expr expr ^ ";\n"
          )
        | _ ->
          if is_indeps
          then "(double) (" ^ gen_expr expr ^ ");\n"
          else "return (double) (" ^ gen_expr expr ^ ");\n" )
    | A.While(e, stmts) -> "while (" ^ gen_expr e ^ "){\n" ^ String.concat "\n" (List.rev (List.map (gen_stmt_for_multieq is_indeps) stmts)) ^ "}\n"
    | A.Continue -> "continue;\n"
    | A.Break -> "break;\n"
    | A.If (l) ->  (string_of_first_cond_exec is_indeps) (List.hd l) ^ "\n" ^
    (String.concat "\n" (List.map (string_of_cond_exec is_indeps) (List.tl l)))

  and string_of_first_cond_exec is_indeps = function
    | (Some(expr), stmts) -> "if (" ^ (gen_expr expr) ^ ")\n {\n" ^
                                          (String.concat "\n" (List.map (gen_stmt_for_multieq is_indeps) stmts)) ^
                                      "}\n"
    | _ -> ""

  and string_of_cond_exec is_indeps = function
    | (None, stmts) -> "else {\n" ^
                                    (String.concat "\n" (List.map (gen_stmt_for_multieq is_indeps) stmts)) ^
                                "}\n"
    | (Some(expr), stmts) -> "else if (" ^ (gen_expr expr) ^ ")\n {\n" ^
                                           (String.concat "\n" (List.map (gen_stmt_for_multieq is_indeps) stmts)) ^
                                      "}\n"
  in

  let get_id_range finddecl =
    match finddecl.A.frange with
    | [] -> ""
    | hd :: tl -> (match hd with A.Range(id, st, ed, inc) -> id)
  in

  let gen_decl_var varname funcdecl str =
    "double " ^ varname ^ ";\n" ^ str
  in
  let gen_decl_ctx ctx =
    StringMap.fold gen_decl_var (StringMap.find ctx.A.context varmap) "\n"
  in

  let gen_function_for_one_ctx ctx =
    let (deps, indeps) = get_deps_indeps_from_context ctx.A.context in
    let rec gen_function_for_multieq count multieq_list =
      match multieq_list with
      | [] -> []
      | hd::tl ->
          if (StringMap.mem hd.A.fname deps) then
            (Printf.sprintf "%s_%d (%s){\n %s }\n"
              hd.A.fname count
              (String.concat ", " (List.map (fun args -> "double " ^ args) (StringMap.find hd.A.fname deps)))
              (String.concat "\n" (List.map (gen_stmt_for_multieq false) hd.A.fdbody))
            ) :: (
            gen_function_for_multieq (count+1) tl
            )
          else if (StringMap.mem hd.A.fname indeps) then
            (Printf.sprintf "%s_%d =  %s"
              hd.A.fname count
              (String.concat "\n" (List.map (gen_stmt_for_multieq true) hd.A.fdbody))
            ) :: (
            gen_function_for_multieq (count+1) tl
            )
          else
            fail "Something is deeply wrong"

    in
    String.concat "\n" (List.map (fun x -> Printf.sprintf "double %s_%s" ctx.A.context x)
                (gen_function_for_multieq 0 ctx.A.cbody))
  in

  let gen_function_call_in_find ctx =
    let rec gen_function_call_for_multieq count multieq_list =
      match multieq_list with
      | [] -> []
      | hd::tl -> (Printf.sprintf "%s = %s_%s_%d ();\n" hd.A.fname ctx.A.context hd.A.fname count
                  ) :: (gen_function_call_for_multieq (count+1) tl)
    in String.concat "\n" (gen_function_call_for_multieq 0 ctx.A.cbody)
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
  let gen_wrapped_find_func_prototype_list finddecl_list =
    let get_for_loop_range finddecl =
      match finddecl.A.frange with
      | [] -> ""
      | hd :: tl -> (match hd with A.Range(id, st, ed, inc) ->
                     (match st, ed, inc with
                      | A.Literal(lst), Some(sed), Some(sinc)  ->
                        (match sed, sinc with
                        | A.Literal(led), A.Literal(linc) ->
                            if linc >= 0.
                            then
                            Printf.sprintf "for(%s=%f; %s<=%f; %s=%s+%f)" id lst id led id id linc
                            else
                            Printf.sprintf "for(%s=%f; %s>=%f; %s=%s+%f)" id lst id led id id linc
                        | _ -> "")
                      | A.Literal(lst), Some(sed), None ->
                        (match sed with
                         | A.Literal(led) ->
                           if lst < led then
                           Printf.sprintf "for(%s=%f; %s<=%f; %s++)" id lst id led id
                           else
                           Printf.sprintf "for(%s=%f; %s>=%f; %s--)" id lst id led id
                         | _ -> "")
                      | A.Literal(lst), None, None ->
                           if lst > 0. then
                           Printf.sprintf "for(%s=0; %s<=%f; %s++)" id id lst id
                           else
                           Printf.sprintf "for(%s=0; %s>=%f; %s--)" id id lst id
                      | _ -> ""
                      ))
    in
    let rec gen_wrapped_find_func_prototype count find_list =
      match find_list with
      | [] -> []
      | hd::tl -> (match get_id_range hd with
                   | "" ->  ((Printf.sprintf "void find_%s_%d_range(){\n" hd.A.fcontext count)^
                            (Printf.sprintf "find_%s_%d(%s);\n}\n" hd.A.fcontext count (get_id_range hd)))::(gen_wrapped_find_func_prototype (count+1) tl)
                   | _ -> ((Printf.sprintf "void find_%s_%d_range(){\n" hd.A.fcontext count) ^
                          (Printf.sprintf "double %s;\n" (get_id_range hd)) ^
                          get_for_loop_range hd ^ "{\n" ^
                          (Printf.sprintf "find_%s_%d(%s);\n}\n}\n" hd.A.fcontext count (get_id_range hd)))::(gen_wrapped_find_func_prototype (count+1) tl)
                  )
    in List.rev (gen_wrapped_find_func_prototype 0 finddecl_list)
  in
  let get_ctx_by_name ctx_name =
    let rec cmp_ctx_with_name ctxlist =
      match ctxlist with
      | [] -> []
      | hd::tl -> if hd.A.context = ctx_name then [hd]
                  else cmp_ctx_with_name tl
    in (match cmp_ctx_with_name contexts with
          | hd::tl -> Some(hd)
          | [] -> None
       )
  in
  let gen_find_function find_funcname finddecl =
    (* naming of the function: find_(context_name)_(golabl_counting_num) *)
    find_funcname ^ " {\n  " ^
    String.concat ""(List.map gen_decl_ctx contexts) ^
    (match (get_ctx_by_name finddecl.A.fcontext) with | Some(cxt) -> gen_function_call_in_find cxt
                                                      | None -> "") ^
    (gen_finddecl finddecl) ^ "}\n" ^
    "\n"
  in
  let gen_find_func_call_list finddecl_list =
    let rec gen_find_func_call count find_list =
      match find_list with
      | [] -> []
      | hd::tl -> ("find_" ^ hd.A.fcontext ^ "_" ^ (string_of_int count) ^ "_range ();\n"
                  )::(gen_find_func_call (count+1) tl)
    in List.rev (gen_find_func_call 0 finddecl_list)
  in
  let lib =
    let add_lib header head_lib =
      if (List.mem header head_lib) then head_lib else header::head_lib
    in
    let add_lib_for_dep head elem =
      match elem with
      | "%" | "^" | "|" | "cos" | "sin" | "tan" | "sqrt" | "log" -> add_lib "#include <math.h>\n" head
      | "print" -> add_lib "#include <stdio.h>\n" head
      | _ -> head
    in List.fold_left add_lib_for_dep [] liblist

  in
  String.concat "" lib ^
  String.concat "\n" (List.map gen_function_for_one_ctx contexts) ^
  String.concat "" (List.map2 gen_find_function (gen_find_func_prototype_list finds) (List.rev finds)) ^
  String.concat "" (gen_wrapped_find_func_prototype_list finds) ^
  "int main() {\n" ^
  String.concat "" (gen_find_func_call_list finds) ^
  " return 0;\n}\n"
