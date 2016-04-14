(* Semantic checking for the EqualsEquals compiler *)

module A = Ast
module StringMap = Map.Make(String)

(* Semantic checking of a program. Returns void if successful,
   throws an exception if something is wrong.

   Check each context, then check each find declaration *)

let check (contexts, finds) =
  let fail msg = raise (Failure msg) in

  (* string prettifiers *)
  let quot content = "\"" ^ content ^  "\"" in
  let ex_qt expr = quot (A.string_of_expr expr) in
  let bop_qt bop = quot (A.string_of_op bop) in
  let uop_qt uop = quot (A.string_of_uop uop) in

  (* Raise an exception of the given rvalue type cannot be assigned to
     the given lvalue type
  let check_assign lvaluet rvaluet err =
     if lvaluet == rvaluet then lvaluet else raise err
  in

  TODO: possible ^ given how we've structured string-literals in our grammar? *)

  (* Map of variables to their decls. For more, see: Sast.varMap *)
  let varmap =
    let create_varmap map ctx =
      if StringMap.mem ctx.A.context map
      then fail ("duplicate context, " ^ (quot ctx.A.context))
      else
        StringMap.add
          ctx.A.context
          (List.fold_left
            (fun map meqdecl -> StringMap.add meqdecl.A.fname meqdecl map)
            StringMap.empty
            ctx.A.cbody
          )
          map
    in
    List.fold_left create_varmap StringMap.empty contexts
   in
   (* list of EqualsEquals symbols that require external library support *)
   let liblist =
    let rec add_lib_expre lis  = function
          A.Binop(left,op,right)-> (
               match op with
               |A.Mod -> "%"::lis
               |A.Pow -> "^"::lis
               |_ -> (add_lib_expre lis left)@(add_lib_expre lis right)@lis )
        | A.Unop(op, expr) -> (
            match op with
            |A.Abs -> "|"::lis
            |_ -> add_lib_expre lis expr )
        | A.Assign(left, expr) -> add_lib_expre lis expr
        | A.Builtin(name, expr) -> (
            match name with
            | "cos" -> "cos"::lis
            | "sin" -> "sin"::lis
            | "tan" -> "tan"::lis
            | "log" -> "log"::lis
            | "sqrt" -> "sqrt"::lis
            | "print" -> "print"::(List.fold_left add_lib_expre lis expr)
            |_ -> List.fold_left add_lib_expre lis expr )
        |_ -> lis
    in
    let rec add_lib_stmt_ctx lis = function
             A.Expr e-> add_lib_expre lis e
            |A.Block sl -> (List.fold_left add_lib_stmt_ctx lis sl)
            |A.If(l) -> lis
            |A.While(p, s) -> add_lib_stmt_ctx lis s
    in
    let check_if_lib lis = function
        | (None, sl) -> add_lib_stmt_ctx lis sl
        | (Some(e), sl) -> List.append (add_lib_expre lis e) (add_lib_stmt_ctx lis sl)
    in
    let rec add_lib_stmt lis  = function
             A.Expr e-> add_lib_expre lis e
            |A.Block sl -> (List.fold_left add_lib_stmt lis sl)
            |A.If(l) -> let rec check_if_list_lib lis = function
                                 | [] -> lis
                                 | hd::tl -> check_if_list_lib (List.append lis (check_if_lib lis hd)) tl
                                in check_if_list_lib lis l
            |A.While(p, s) -> add_lib_stmt lis s
    in
    let create_liblist_finds lis finds =
      List.fold_left
        add_lib_stmt
        lis
        finds.A.fbody
    in
    let create_liblist_ctx lis ctx =
      List.fold_left
        add_lib_stmt_ctx
        lis
        ctx.A.fdbody
    in
    (* append list from finds black with list from contexts block *)
    List.append
     (List.fold_left create_liblist_finds [] finds)
     (List.fold_left (fun lis eq -> List.fold_left create_liblist_ctx lis eq.A.cbody) [] contexts)
  in

  let check_have_var var symbolmap =
    try StringMap.find var symbolmap
    with Not_found -> fail ("variable not defined, " ^ quot var)
  in
  let rec check_expr e =
      match e with
          | A.Literal(lit) -> ()
          | A.Strlit(str) -> ()
          | A.Id(id) -> ()
          | A.Binop(left, op, right) -> ()
          | A.Unop(op, expr) -> ()
          | A.Assign(left, expr) -> check_expr expr
          | A.Builtin(name, expr) -> (check_builtin name expr)
  and check_builtin_name name str=
    match name with
      | "sin" -> fail ("illegal argument for sin, " ^ quot str)
      | "cos" -> fail ("illegal argument for cos, " ^ quot str)
      | "tan" -> fail ("illegal argument for tan, " ^ quot str)
      | "log" -> fail ("illegal argument for log, " ^ quot str)
      | "sqrt" -> fail ("illegal argument for sqrt, " ^ quot str)
      | _ -> fail ("unknown built-in function, " ^ quot name)
  and check_builtin name expr=
    match name, List.hd expr with
        | "print", A.Builtin(name , value) -> ()
        | "print", _ -> ()
        | s, A.Strlit(str) -> check_builtin_name s str
        | s, A.Assign(left, expr) -> check_builtin_name s left
        | "cos", _ -> ()
        | "sin", _ -> ()
        | "sqrt", A.Literal(l) -> if l < 0. then fail ("illegal argument for sqrt, " ^ quot (string_of_float l))
        | "sqrt", _ -> ()
        | "tan", _ -> ()
        | "log", A.Literal(l) -> if l <= 0. then fail ("illegal argument for log, " ^ quot (string_of_float l))
        | "log", _ -> ()
        | _ -> fail ("unknown built-in function, " ^ quot name)
    in
  (* Verify a statement or throw an exception *)
  let rec check_stmt = function
      | A.Block sl ->
          (* effectively unravel statements out of their block *)
          let rec check_block = function
            | A.Block sl :: ss -> check_block (sl @ ss)
            | s :: ss -> check_stmt s; check_block ss
            | [] -> ()
          in check_block sl
      | A.Expr e -> check_expr e
      | A.If(l) ->  ()
      | A.While(p, s) -> check_stmt (A.Expr p); check_stmt s
  in

  (**** Checking Context blocks  ****)
  let check_ctx ctxBlk =
    let check_eq eq = List.iter check_stmt eq.A.fdbody in

    (* TODO: semantic analysis of variables, allow undeclared and all the stuff
     * that makes our lang special... right here!
    let knowns = [] in
    let unknowns = [] in
    *)

    (* vanilla logic;
    let equation_decl var =
      try StringMap.find s function_decls
      with Not_found -> raise (Failure ("unrecognized variable " ^ quot s))
    in
    *)
    List.iter check_eq ctxBlk.A.cbody
  in

  (**** Checking Find blocks ****)
  let check_find findBlk =
    let symbolmap =
      let ctx_name = findBlk.A.fcontext in
      try StringMap.find ctx_name varmap
      with Not_found -> fail ("unrecognized context, " ^ quot ctx_name)
    in
  (* Verify a particular `statement` in `find` or throw an exception *)
  let check_if = function
    | (None, sl) -> check_stmt sl
    | (Some(e), sl) -> check_stmt (A.Expr e); check_stmt sl
  in
  let rec check_stmt_for_find = function
      | A.Block sl ->
          (* effectively unravel statements out of their block *)
          let rec check_block = function
            | A.Block sl :: ss -> check_block (sl @ ss)
            | s :: ss -> check_stmt_for_find s; check_block ss
            | [] -> ()
          in check_block sl
      | A.Expr e -> check_expr e
      | A.If(l) -> let rec check_if_list = function
                    | [] -> ()
                    | hd::tl -> check_if hd; check_if_list tl
                    in check_if_list l
      | A.While(p, s) -> check_stmt_for_find (A.Expr p); check_stmt_for_find s
  in

    check_have_var findBlk.A.ftarget symbolmap;
    List.iter check_stmt_for_find findBlk.A.fbody
  in

  List.iter check_ctx contexts;
  List.iter check_find finds;

  {
    Sast.ast = (contexts, finds);
    Sast.vars = varmap;
    Sast.lib = liblist
  }
