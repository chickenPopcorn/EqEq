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
            | "cos" | "sin" | "tan" | "sqrt" | "log"  -> name::lis
            | "print" -> "print"::(List.fold_left add_lib_expre lis expr)
            |_ -> List.fold_left add_lib_expre lis expr )
        |_ -> lis
    in
    let rec add_lib_stmt_ctx lis = function
             A.Expr e-> add_lib_expre lis e
            |A.If(l) -> let rec check_if_list_lib lis = function
                                 | [] -> lis
                                 | hd::tl -> check_if_list_lib (List.append lis (check_if_lib lis hd)) tl
                        in check_if_list_lib lis l
            |A.While(p, stmts) -> List.fold_left add_lib_stmt_ctx lis stmts
            |_ -> lis
    and check_if_lib lis = function
        | (None, sl) -> List.fold_left add_lib_stmt_ctx lis sl
        | (Some(e), sl) -> List.append (add_lib_expre lis e) (List.fold_left add_lib_stmt_ctx lis sl)
    in
    let rec add_lib_stmt lis  = function
             A.Expr e-> add_lib_expre lis e
            |A.If(l) -> let rec check_if_list_lib lis = function
                                 | [] -> lis
                                 | hd::tl -> check_if_list_lib (List.append lis (check_if_lib lis hd)) tl
                        in check_if_list_lib lis l
            |A.While(p, stmts) -> List.fold_left add_lib_stmt lis stmts
            |_ -> lis
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
          | A.Binop(left, op, right) -> check_expr left; check_expr right;
              not_print left (A.string_of_op op); not_print right (A.string_of_op op)
          | A.Unop(op, expr) -> check_expr expr; (not_print expr (A.string_of_uop op))
          | A.Assign(left, expr) -> check_expr expr
          | A.Builtin(name, expr) -> (fail_illegal_builtin name expr); List.iter check_expr expr

  and not_print expr op =
    match expr with
    |A.Builtin(name, expr) -> (
      match name with
      | "print" -> fail("Illegal use of operator on print, " ^ quot op)
      | _ -> ())
    | _ -> ()

  and fail_illegal_builtin_arg_str_asgn name str =
    match name with
      | "cos" | "sin" | "tan" | "sqrt" | "log"  -> fail ("illegal argument for "^name ^", " ^ quot str)
      | _ -> fail ("unknown built-in function, " ^ quot name)

  and fail_illegal_builtin_arg s hd =
      match s, hd with
          | s, A.Assign(left, expr) -> fail_illegal_builtin_arg_str_asgn s (left ^"=" ^A.string_of_expr expr)
          | s, A.Strlit(str) -> fail_illegal_builtin_arg_str_asgn s str
          | "sqrt", A.Literal(l) -> if l < 0. then fail ("illegal argument for sqrt, " ^ quot (string_of_float l))
          | "log", A.Literal(l) -> if l <= 0. then fail ("illegal argument for log, " ^ quot (string_of_float l))
          | "log", _ | "cos", _ | "sin", _ | "sqrt", _ | "tan", _ -> ()
          | s,_ -> fail ("unknown built-in function, " ^ quot s)

  and fail_illegal_builtin name expr_list=
    match name, expr_list with
        | "print", expr -> List.iter check_expr expr
        | s, hd::tl -> fail_illegal_builtin_arg s hd; fail_illegal_num_of_builtin_arg tl
        | _ ->()

  and fail_illegal_num_of_builtin_arg tl =
    match tl with
        | [] -> ()
        | _ ->fail("illegal argument, " ^ quot (String.concat " " (List.map A.string_of_expr tl)))
    in
  (* Verify a statement or throw an exception *)
  let rec check_stmt = function
      | A.Expr e -> check_expr e
      | A.If(l) ->  ()
      | A.While(p, s) -> check_expr p; List.iter check_stmt s
      | A.Continue -> ()
      | A.Break -> ()
  (**** Checking Context blocks  ****)
  in
  let check_ctx ctxBlk =
    let check_eq eq = List.iter check_stmt eq.A.fdbody
    in
    let sum_list l =
      match l with
      | hd::tl -> List.fold_left (fun x y -> x + y) hd tl
      | [] -> 0
    in
    let min_list l =
      match l with
      | hd::tl -> List.fold_left min hd tl
      | [] -> -1
    in
    let rec check_return_in_stmt stmt =
      match stmt with
      | A.Expr e -> (
        match e with
        | A.Builtin(name, expr) -> (
          match name with
          | "print" -> 0
          | _ -> 1
          )
        | A.Assign(left, expr) -> 0
        | _ ->  1
      )
      | A.Continue | A.Break -> 0
      | A.If(l) -> min_list ((List.map check_if_for_return l) @ last_one_in_if_else l)
      | A.While(p, s) -> check_return_stmt_list s
    and check_if_for_return = function
      | (None, sl) -> check_return_stmt_list sl
      | (Some(e), sl) -> check_return_stmt_list sl
    and check_return_stmt_list sl = sum_list (List.map check_return_in_stmt sl)
    and last_one_in_if_else l =
      match List.hd (List.rev l) with
      | (Some(e), sl) -> [0]
      | _ -> []
    in
    let check_return_count num_return eqName ctxName=
      match num_return with
      | 0 -> fail ("missing return in equation " ^ quot eqName ^" under context "^quot ctxName)
      | _ -> ()
    in
     let check_return_eq eq = check_return_count (check_return_stmt_list eq.A.fdbody) eq.A.fname ctxBlk.A.context
    in
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
    List.iter check_eq ctxBlk.A.cbody; List.iter check_return_eq ctxBlk.A.cbody
  in
  (**** Checking Find blocks ****)
  let check_find findBlk =
    let symbolmap =
      let ctx_name = findBlk.A.fcontext in
      try StringMap.find ctx_name varmap
      with Not_found -> fail ("unrecognized context, " ^ quot ctx_name)
    in
    let check_range =
        match findBlk.A.frange with
        | [] -> ()
        | hd::tl -> (match hd with
          A.Range(id, st, ed, inc) -> (match st with A.Strlit(str) -> fail ( "Find block in " ^ findBlk.A.fcontext ^ ": " ^ id ^ " has range with illegal argument, " ^ quot str)
                                                     | _ -> ());
                                      (match ed with Some(str) ->
                                        (match str with A.Strlit(str) -> fail ("Find block in " ^ findBlk.A.fcontext ^ ": " ^ id ^ " has range with illegal argument, " ^ quot str)
                                                        | _ -> ())
                                                     | _ -> ());
                                      (match inc with Some(str) ->
                                        (match str with A.Strlit(str) -> fail ("Find block in " ^ findBlk.A.fcontext ^ ": " ^ id ^ " has range with illegal argument, " ^ quot str)
                                                        | _ -> ())
                                                     | _ -> ()))
  in
  (* Verify a particular `statement` in `find` or throw an exception *)
  let check_if = function
    | (None, sl) -> List.iter check_stmt sl
    | (Some(e), sl) -> check_stmt (A.Expr e); List.iter check_stmt sl
  in
  let rec check_stmt_for_find = function
      | A.Expr e -> check_expr e;(
        match e with
        | A.Builtin(name, expr) -> ()
        | A.Assign(left, expr) -> ()
        | a -> fail ("invalid return in find " ^ quot (A.string_of_expr a))
      )
      (*check_expr e*)
      | A.If(l) -> let rec check_if_list = function
                    | [] -> ()
                    | hd::tl -> check_if hd; check_if_list tl
                    in check_if_list l
      | A.While(p, stmts) -> check_expr p; List.iter check_stmt_for_find stmts
      | A.Continue -> ()
      | A.Break -> ()

  in

    check_have_var findBlk.A.ftarget symbolmap;
    List.iter check_stmt_for_find findBlk.A.fbody

  in
  (*add function to cheack the usage of Break and Continue
    Break & Continue are allowed only in While loop *)
    let rec check_stmt_break_continue blk err_stmt = function
      | A.Expr e -> ()
      | A.If(l) -> let rec check_if_list = function
                    | [] -> ()
                    | hd::tl -> let check_stmt_break_continue_in_if stmt =
                                    check_stmt_break_continue blk  "if statement of " stmt
                                in List.iter check_stmt_break_continue_in_if (snd hd); check_if_list tl
                    in check_if_list l
      | A.While(p, s) -> () (* stop now. any 'break' below here is valid *)
      | A.Continue -> fail("Inadquate usage of Continue in "^err_stmt^blk^", 'Continue' should only exist in while loop" )
      | A.Break -> fail("Inadquate usage of Break in "^err_stmt^blk^", 'Break' should only exist in while loop" )
  in
  (* check Break and Continue for the contexts *)
  let check_ctx_break_continue ctxBlk =
    let check_eq_break_continue eq = List.iter (check_stmt_break_continue "Contexts_Declaration" "") eq.A.fdbody in
    List.iter check_eq_break_continue ctxBlk.A.cbody
  in
  (* check Break and Continue for the finds *)
  let check_find_break_continue findBlk = List.iter (check_stmt_break_continue "Finds_Declaration" "") findBlk.A.fbody
  in

  List.iter check_ctx_break_continue contexts;
  List.iter check_find_break_continue finds;
  List.iter check_ctx contexts;
  List.iter check_find finds;

  {
    Sast.ast = (contexts, finds);
    Sast.vars = varmap;
    Sast.lib = liblist
  }
