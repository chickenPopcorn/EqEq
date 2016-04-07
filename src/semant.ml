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

  (* Map: {key: ctx.context, val: <AnotherMap>} *)
  (* AnotherMap: {key: funcdecl.fname, val: funcdecl} *)
  let varmap =
    let create_varmap map ctx =
      if StringMap.mem ctx.A.context map
      then fail ("duplicate context, " ^ (quot ctx.A.context))
      else
        StringMap.add
          ctx.A.context
          (List.fold_left
            (fun map funcdecl -> StringMap.add funcdecl.A.fname funcdecl map)
            StringMap.empty
            ctx.A.cbody
          )
          map
    in
    List.fold_left create_varmap StringMap.empty contexts in

  let check_have_var var symbolmap =
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
  let rec check_stmt_for_find = function
      | A.Block sl ->
          (* effectively unravel statements out of their block *)
          let rec check_block = function
            | A.Block sl :: ss -> check_block (sl @ ss)
            | s :: ss -> check_stmt_for_find s; check_block ss
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
      | A.If(l) -> ()
      | A.While(p, s) -> check_stmt_for_find (A.Expr p); check_stmt_for_find s
  in

    check_have_var findBlk.A.ftarget symbolmap;
    List.iter check_stmt_for_find findBlk.A.fbody
  in

  List.iter check_ctx contexts;
  List.iter check_find finds;

  (contexts, finds, varmap)
