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

  (* return: {key: funcdecl.fname, val: funcdecl} *)
  let create_symbolmap map funcdecl =
    let map =
      if StringMap.mem funcdecl.A.fname map
      then StringMap.remove funcdecl.A.fname map
      else map
    in
    StringMap.add funcdecl.A.fname funcdecl map
  in

  (* return: {key: ctx.context, val: <ReturnValueOf`create_symbolmap`>} *)
  let create_varmap map ctx =
    if StringMap.mem ctx.A.context map
    then fail ("duplicate context, " ^ (quot ctx.A.context))
    else
      StringMap.add
        ctx.A.context
        (List.fold_left create_symbolmap StringMap.empty ctx.A.cbody)
        map
  in

  let varmap = List.fold_left create_varmap StringMap.empty contexts in

  (**** Map of known Context blocks keyed by their names ****)
  let known_ctxs =
    List.fold_left
      (fun existing ctx ->
         if StringMap.mem ctx.A.context existing then
           fail ("duplicate context, " ^ (quot ctx.A.context))
         else
           StringMap.add ctx.A.context ctx existing
      )
      StringMap.empty
      contexts
  in

  let check_have_var ctx_name var =
    let symbolmap =
      try StringMap.find ctx_name varmap
      with Not_found -> fail ("unrecognized context, " ^ quot ctx_name)
    in
    try StringMap.find var symbolmap
    with Not_found -> fail ("variable not defined, " ^ quot var)
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
      | A.Expr e -> (
          (* Verify an expression or throw an exception *)
          match e with
              | A.Literal(lit) -> ()
              | A.Strlit(str) -> ()
              | A.Id(id) -> ()
              | A.Binop(left, op, right) -> ()
              | A.Unop(op, expr) -> ()
              | A.Assign(left, expr) -> ()
              | A.Builtin(name, expr) -> ()
        )
      | A.If(p, b1, b2) ->
          check_stmt (A.Expr p); check_stmt b1; check_stmt b2
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
    check_have_var findBlk.A.fcontext findBlk.A.ftarget;
    List.iter check_stmt findBlk.A.fbody
  in

  List.iter check_ctx contexts;
  List.iter check_find finds;

  (contexts, finds, varmap)
