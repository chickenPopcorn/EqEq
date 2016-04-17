(* Semantic checking for the EqualsEquals compiler *)

module A = Ast
module S = Sast
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

  let eqrelations : S.eqResolutions =
    let rec findDepsInAssignStmt foundDeps stmt =
      let rec findIdsInExpr foundIds = function
        | A.Literal(_) -> foundIds
        | A.Id(id) -> id::foundIds
        | A.Strlit(_) -> foundIds
        | A.Binop(e1,_,e2) -> findIdsInExpr (findIdsInExpr foundIds e2) e1
        | A.Unop(_,e) -> findIdsInExpr foundIds e
        | A.Assign(_,e) -> findIdsInExpr foundIds e
        | A.Builtin(_,eList) ->
            List.fold_left (fun ls e -> findIdsInExpr ls e) foundIds eList
      in

      match stmt with
        | A.Block(sList) ->
            List.fold_left
              (fun ls s -> findDepsInAssignStmt ls s)
              foundDeps
              sList
        | A.Expr(e) -> findIdsInExpr foundDeps e
        | A.If(stmtOrTupleList) -> (
            let rec collectIdsInIf accumul = function
              | [] -> accumul
              | (None,s)::tail ->
                  collectIdsInIf (findDepsInAssignStmt accumul s) tail
              | (Some(e),s)::tail ->
                  collectIdsInIf (
                    findIdsInExpr (findDepsInAssignStmt accumul s) e
                  ) tail
            in collectIdsInIf foundDeps stmtOrTupleList
          )
        | A.While(e, s) -> findIdsInExpr (findDepsInAssignStmt foundDeps s) e
    in

    (* `Sast.eqResolutions` to which we'll add `S.equation_relations` *)
    let ctxRelations : S.eqResolutions =
      let relationCtxFolder relations ctx =
        let ctxScope =
          let (deps, indeps) =
            let ctx_body_folder (deps, indeps) mEq =
              let multi_eq_folder (deps, indeps) mEqBody =
                let foundDeps = findDepsInAssignStmt [] mEqBody in
                if List.length foundDeps > 0
                then (StringMap.add mEq.A.fname foundDeps deps, indeps)
                else (deps, StringMap.add mEq.A.fname mEq.A.fdbody indeps)
              in
              List.fold_left multi_eq_folder (deps, indeps) mEq.A.fdbody

            in
            List.fold_left ctx_body_folder (StringMap.empty, StringMap.empty) ctx.A.cbody
          in
          {
            S.ctx_deps = deps;
            S.ctx_indeps = indeps;

            (* taken care of in `relationFindFolder` later on ... *)
            S.ctx_finds = StringMap.empty;
          }
        in
        StringMap.add ctx.A.context ctxScope relations
      in
      List.fold_left relationCtxFolder StringMap.empty contexts
    in

    (* Add a complete picture of contexts' find decl relations, maintaining an
     * index along the way, then discard the last index and just return the
     * completed map. *)
    let (sastEqRels, _) =
      (* Fold `S.equation_relations` to respective Contexts' `S.ctx_scopes` *)
      let relationFindFolder (relations, findIdx) findDec =
        let findName = Printf.sprintf "find_%s_%d" findDec.A.fcontext findIdx in

        (* `Sast.ctx_scopes` for which we're creating an `findName` entry. *)
        let ctxScopes : Sast.ctx_scopes =
          try StringMap.find findDec.A.fcontext relations
          with Not_found ->
            fail ("find targeting unknown context, " ^ quot findDec.A.fcontext)
        in

        (* TODO: after building deps/indeps (findBodyMap), ensure
         * `findDec.ftarget` is known key (of either deps or indeps is fine) *)

        let extendedRels : S.eqResolutions =
          (* Map from expression index to a `Sast.equation_relations` *)
          let findRelationMap : (S.equation_relations S.IntMap.t) =
            (* Build a complete map of expresion-index to relations for this
             * find body, then discard the latest index and return that map. *)
            let (eqRels, _) =
              let rec findExprRelator (eMap, idx) (expr : A.expr) =
                let check_resolvable (index : int) (id : string) m =
                  let assert_nodeps id rels = try StringMap.find id rels with
                    | Not_found -> fail ("Unresolvable identifier, " ^ quot id)

                    (* TODO NEXT STEP: BFS on deps/indeps to give real answer *)
                  in
                  let lastMap =
                    let rec asof i =
                      (* TODO rm backwards walk by maintaining "latest" index *)
                      try S.IntMap.find i m with Not_found ->
                        if i > 0 then asof (i - 1) else fail (
                          Printf.sprintf
                            "Compiler BUG found: empty rel-map at Id('%s') at expression #%d [only found: '%s']"
                            id index (String.concat "', '" (
                              S.IntMap.fold
                                (fun k v a -> (string_of_int k)::a)
                                m []
                            ))
                        )
                    in
                    asof index
                  in
                  assert_nodeps id lastMap.S.indeps
                in

                let i = idx + 1 in match expr with
                  | A.Id(identifier) ->
                      (* TODO: here's the golden logic we care about! *)
                      ignore (check_resolvable i identifier eMap); (eMap, i)
                  | A.Literal(_) | A.Strlit(_) -> (eMap, i)
                  | A.Binop(eLeft, _, eRight) ->
                      findExprRelator (findExprRelator (eMap, i) eLeft) eRight
                  | A.Unop(_, e) -> findExprRelator (eMap, i) e
                  | A.Assign(id, e) ->
                      (* TODO: figure out how to ensure failures for
                       * `undefinedvar` in `e` for an expression:
                       *     `find{ a = b = undefinedvar + 1}`
                       *)

                      (* TODO: NEXT STEP: perform if/else and add `id` to
                       * deps/indeps accordingly *)

                      findExprRelator (eMap, i) e
                  | A.Builtin(_, exprLis) ->
                      List.fold_left findExprRelator (eMap, i) exprLis
              in

              let rec findStmtRelator (m, i) (st : A.stmt) = match st with
                | A.Block(s) -> List.fold_left findStmtRelator (m, i) s
                | A.Expr(e) -> findExprRelator (m, i) e
                | A.If(stmtTupleWithOptionalExpr) ->
                    let rec relationsInIf accum = function
                      | [] -> accum
                      | (None, s)::tail ->
                          relationsInIf (findStmtRelator accum s) tail
                      | (Some(e), s)::tail ->
                          relationsInIf (
                            findStmtRelator (
                              findExprRelator accum e
                            ) s
                          ) tail
                    in relationsInIf (m, i) stmtTupleWithOptionalExpr
                | A.While(e, s) -> findStmtRelator (findExprRelator (m, i) e) s
              in

              (* Initial map from starting with contexts' own relationships *)
              let exprMap : S.equation_relations S.IntMap.t =
                let baseRelations : S.equation_relations = {
                  S.indeps = ctxScopes.S.ctx_indeps;
                  S.deps = ctxScopes.S.ctx_deps;
                }
                in
                S.IntMap.add 0 baseRelations S.IntMap.empty
              in
              List.fold_left findStmtRelator (exprMap, 0) findDec.A.fbody
            in
            eqRels
          in

          let ctxFinds : S.find_scopes =
            StringMap.add findName findRelationMap ctxScopes.S.ctx_finds
          in

          let scopes = {
            S.ctx_deps = ctxScopes.S.ctx_deps;
            S.ctx_indeps = ctxScopes.S.ctx_indeps;
            S.ctx_finds = ctxFinds;
          }
          in
          StringMap.add findDec.A.fcontext scopes relations
        in
        (extendedRels, findIdx + 1)
      in
      List.fold_left relationFindFolder (ctxRelations, 0) finds
    in
    sastEqRels
  in

  (* Map of variables to their decls. For more, see: S.varMap *)
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
    S.ast = (contexts, finds);
    S.eqs = eqrelations;
    S.vars = varmap;
  }
