(* Code generation: translates semantically checked AST & produces vanilla C. *)

module A = Ast
module S = Sast
module IntMap = S.IntMap

module StringMap = Map.Make(String)


let translate sast =
  let (contexts, finds) = sast.S.ast in
  let varmap = sast.S.vars in
  let liblist = sast.S.lib in
  let eqs = sast.S.eqs in

  let fail msg = raise (Failure msg) in

  (* to remove debug messages: `let debug msg = "" in` *)
  let debug msg = msg in
  let info msg = msg in

  (* SAST helper functions *)
  let get_deps_indeps_from_context ctxname =
    let ctx_sast = StringMap.find ctxname eqs in
    (ctx_sast.S.ctx_deps, ctx_sast.S.ctx_indeps)
  in

  let get_find_from_context ctxname findname =
    let ctx_sast = StringMap.find ctxname eqs in
    StringMap.find findname ctx_sast.S.ctx_finds
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

  let gen_varlist varname _ varlist =
    if StringMap.mem varname varlist then
      varlist
    else
      StringMap.add varname "whatever" varlist
  in

  let gen_varlist_from_find_relation _ relation varlist =
    let varlist =
      StringMap.fold gen_varlist relation.S.deps varlist
    in
    StringMap.fold gen_varlist relation.S.indeps varlist
  in

  let gen_decl_var varname funcdecl str =
    "double " ^ varname ^ ";\n" ^ str
  in

  let gen_decl_ctx_and_find (find_sast: S.equation_relations IntMap.t) ctxname =
    let varmap_for_ctx = StringMap.find ctxname varmap in
    (* varlist: is a map of with the key is the variable needed to generate declaration for variables *)
    let varlist = StringMap.fold gen_varlist varmap_for_ctx StringMap.empty in
    let varlist = IntMap.fold gen_varlist_from_find_relation find_sast varlist in

    StringMap.fold gen_decl_var varlist "\n"
  in

  let gen_function_for_one_ctx ctx =
    let (deps, indeps) = get_deps_indeps_from_context ctx.A.context in
    let rec gen_function_for_multieq count multieq_list =
      match multieq_list with
      | [] -> []
      | hd::tl ->
          let arg_str =
            if (StringMap.mem hd.A.fname deps) then
              String.concat ", " (List.map (fun args -> "double " ^ args) (StringMap.find hd.A.fname deps))
            else
              ""
          in

          (Printf.sprintf "%s_%d (%s){\n%s}\n"
            hd.A.fname count
            arg_str
            (String.concat "\n" (List.map (gen_stmt_for_multieq false) hd.A.fdbody))
          ) :: (
          gen_function_for_multieq (count+1) tl
          )
    in
    String.concat "\n" (List.map (fun x -> Printf.sprintf "double %s_%s" ctx.A.context x)
                (gen_function_for_multieq 0 ctx.A.cbody))
  in

  (* NOTE: this's still not working as expected... `visited` doesn't prevent duplicate assignments *)
  (*       but since duplicates are not a problem we don't neccessarily have to fix this if we don't have time *)
  let rec gen_multieq_call_in_find (deps, indeps) visited varmap_for_ctx varname =
    if StringMap.mem varname visited then
      ""
    else if not (StringMap.mem varname varmap_for_ctx) then
      (* happens when a variable is first defined in `finddecl` *)
      ""
    else
      let multieq_name = (StringMap.find varname varmap_for_ctx).A.fname in
      let visited = StringMap.add varname "" visited in

      if StringMap.mem varname deps then
        let deplist = StringMap.find varname deps in
        String.concat
          "\n"
          (List.map
            (gen_multieq_call_in_find (deps, indeps) (StringMap.add varname "" visited) varmap_for_ctx)
            deplist)
        ^
        Printf.sprintf "%s = %s(%s);\n" varname multieq_name (String.concat ", " deplist)
      else if StringMap.mem varname indeps then
        Printf.sprintf "%s = %s();\n" varname multieq_name
      else
        (* assume that the variable is declared elsewhere before this function is called *)
        ""
  in

  let gen_finddecl finddecl =
    String.concat "" (List.map gen_stmt finddecl.A.fbody)
  in

  let rec gen_findname_from_find count = function
    | [] -> []
    | hd::tl -> ("find_" ^ hd.A.fcontext ^ "_" ^ (string_of_int count))
                ::
                (gen_findname_from_find (count+1) tl)
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

  (* return: {variable_name: multieqname}, type String StringMap.t *)
  let gen_find_function findname finddecl =
    let (deps, indeps) = get_deps_indeps_from_context finddecl.A.fcontext in
    let find_sast = get_find_from_context finddecl.A.fcontext findname in
    let varmap_for_ctx = StringMap.find finddecl.A.fcontext varmap in
    let varlist = StringMap.fold (fun key value lst -> key::lst) varmap_for_ctx [] in

    (***** Helper functions for the current finddecl { *****)
    let rec gen_finddecl_deps (str, count, cur_expr_number) expr =
      let count = count + 1 in
      let cur_expr_number =
        if IntMap.mem count find_sast then
          count
        else
          cur_expr_number
      in
      (* let str = debug (str ^ "// cur_expr = " ^ (A.string_of_expr expr) ^ "\n") in *)
      (* let str = debug (str ^ "// cur_expr_number = " ^ (string_of_int cur_expr_number) ^ "\n") in *)
      (* let str = debug (str ^ "// count = " ^ (string_of_int count) ^ "\n") in *)

      match expr with
        | A.Id(_) | A.Literal(_) | A.Strlit(_) -> (str, count, cur_expr_number)
        | A.Binop(eLeft, _, eRight) ->
          gen_finddecl_deps (gen_finddecl_deps (str, count, cur_expr_number) eLeft) eRight
        | A.Unop(_, e) -> gen_finddecl_deps (str, count, cur_expr_number) e
        | A.Assign(id, e) ->
          let (str, count, cur_expr_number) = gen_finddecl_deps (str, count, cur_expr_number) e in
          let deps = (IntMap.find cur_expr_number find_sast).S.deps in
          let deplist =
            StringMap.fold (fun key value lst -> key::lst) deps []
          in

          ( str ^
            String.concat
              ""
              (List.map
                (gen_multieq_call_in_find (deps, StringMap.empty) StringMap.empty varmap_for_ctx)
                deplist)
            , count, cur_expr_number
          )
        | A.Builtin(_, exprlist) -> List.fold_left gen_finddecl_deps (str, count, cur_expr_number) exprlist
    in

    let gen_finddecl_stmt (str, count, cur_expr_number) stmt =
      let str = str ^ (gen_stmt stmt) in

      match stmt with
        | A.Expr(expr) ->
            let (str, count, cur_expr_number) =
              (gen_finddecl_deps (str, count, cur_expr_number) expr)
            in
            (str, count, cur_expr_number)
        | _ -> (str, count, cur_expr_number)
    in
    (***** Helper functions for the current finddecl end } *****)

    (* naming of the function: find_(context_name)_(golabl_counting_num) *)
    "void " ^ findname ^ "(" ^
    ((fun x -> match x with | "" -> " "
                            | _ -> "double " ^ x ) (get_id_range finddecl)) ^
    ")" ^ "{\n" ^
    gen_decl_ctx_and_find find_sast finddecl.A.fcontext ^
    (match (get_ctx_by_name finddecl.A.fcontext) with
      | Some(cxt) ->
          String.concat
            "\n"
            (List.map (gen_multieq_call_in_find (deps, indeps) StringMap.empty varmap_for_ctx) varlist)
      | None -> ""
    ) ^ "\n" ^
    info "//-----gen_finddecl_stmt-----\n" ^
    (fun (a, _, _) -> a) (List.fold_left gen_finddecl_stmt ("", 0, 0) finddecl.A.fbody) ^
    "}\n\n"
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
  String.concat "" (List.map2 gen_find_function (gen_findname_from_find 0 finds) finds) ^
  String.concat "" (gen_wrapped_find_func_prototype_list finds) ^
  "int main() {\n" ^
  String.concat "" (gen_find_func_call_list finds) ^
  " return 0;\n}\n"
