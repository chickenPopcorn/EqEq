module A = Ast
module S = Sast
module StringMap = Map.Make(String)

let fail msg = raise (Failure msg)

(* Newest value in `map`; ie: where largest key <= `i` *)
let latest (asof : int) (m : S.equation_relations S.IntMap.t) =
  let rec walkBack i =
    try S.IntMap.find i m with Not_found ->
      if i > 0 then walkBack (i - 1) else fail (
          Printf.sprintf
            "Compiler BUG found: empty rel-map at expression #%d [only found: '%s']"
            asof (String.concat "', '" (
                S.IntMap.fold
                  (fun k v a -> (string_of_int k)::a)
                  m []
              ))
        )
  in walkBack asof

(* Lists all `A.Id`s in the given `stmt` *)
let getStmtDeps (stmt : A.stmt) : string list =
  let rec getAssignDeps (foundDeps : string list) (st : A.stmt) =
    let rec getExprIDs found = function
      | A.Literal(_) -> found
      | A.Id(id) -> id::found
      | A.Strlit(_) -> found
      | A.Binop(e1,_,e2) -> getExprIDs (getExprIDs found e2) e1
      | A.Unop(_,e) -> getExprIDs found e
      | A.Assign(_,e) -> getExprIDs found e
      | A.Builtin(_,el) -> List.fold_left (fun l e -> getExprIDs l e) found el
    in

    match st with
    | A.Block(sL) -> List.fold_left (fun l s -> getAssignDeps l s) foundDeps sL
    | A.Expr(e) -> getExprIDs foundDeps e
    | A.If(stmtOrTupleList) -> (
        let rec idsInIf accumul = function
          | [] -> accumul
          | (None,s)::t -> idsInIf (getAssignDeps accumul s) t
          | (Some(e),s)::t -> idsInIf (getExprIDs (getAssignDeps accumul s) e) t
        in idsInIf foundDeps stmtOrTupleList
      )
    | A.While(e, s) -> getExprIDs (getAssignDeps foundDeps s) e
  in getAssignDeps [] stmt

(* List.fold_left handler an initial map of contexts' equations, before, and
 * start an empty map for their find blocks. *)
let relationCtxFolder (relations : S.eqResolutions) ctx =
  let ctxScope =
    let (deps, indeps) =
      let ctx_body_folder (deps, indeps) mEq =
        let multi_eq_folder (deps, indeps) mEqBody =
          let foundDeps = getStmtDeps mEqBody in
          if List.length foundDeps > 0
          then (StringMap.add mEq.A.fname foundDeps deps, indeps)
          else (deps, StringMap.add mEq.A.fname mEq.A.fdbody indeps)

        in List.fold_left multi_eq_folder (deps, indeps) mEq.A.fdbody

      in List.fold_left
        ctx_body_folder
        (StringMap.empty, StringMap.empty)
        ctx.A.cbody

    in {
      S.ctx_deps = deps;
      S.ctx_indeps = indeps;
      S.ctx_finds = StringMap.empty; (* is handled using `findStmtRelator` *)
    }
  in StringMap.add ctx.A.context ctxScope relations

(* List.fold_left handler for find decl's fbody. *)
let rec findStmtRelator (m, i) (st : A.stmt) =
  let quot content = "\"" ^ content ^  "\"" in

  let rec findExprRelator (eMap, idx) (expr : A.expr) =
    let i = idx + 1 in match expr with
    | A.Id(_) | A.Literal(_) | A.Strlit(_) -> (eMap, i)
    | A.Binop(eLeft, _, eRight) ->
      findExprRelator (findExprRelator (eMap, i) eLeft) eRight
    | A.Unop(_, e) -> findExprRelator (eMap, i) e
    | A.Assign(id, e) ->
      let check_resolvable (index : int) (id : string) m =
        let assert_nodeps id rels = try StringMap.find id rels with
          | Not_found -> fail ("Unresolvable identifier, " ^ quot id)
        (* TODO NEXT STEP: BFS on deps/indeps to give real answer *)
        in assert_nodeps id (latest index m).S.indeps
      in

      (* TODO: figure out how to ensure failures for `undefinedvar` in `e` for
       * an expression: `find{ a = b = undefinedvar + 1}`
       *)
      let rec chk_right_indep = function
        | A.Id(id) -> ignore (check_resolvable i id eMap);
        | A.Literal(_) | A.Strlit(_) -> ignore ();
        | A.Binop(el, _, er) -> ignore (List.iter chk_right_indep [el; er]);
        | A.Unop(_, e) -> ignore (chk_right_indep e);
        | A.Assign(_, e) -> ignore (chk_right_indep e);
        | A.Builtin(_, eLi) -> ignore (List.iter chk_right_indep eLi);
      in ignore (chk_right_indep e);

      (* If `id` already exists, then it's being redefined, in which case we'll
       * start a new `S.equation_relations` at the current expression index.
       * Else we'll keep using the current S.equation_relations, `eMap` as-is.
       *)
      let maybeExtendedExprMap =
        let latest = latest i eMap in

        let isKnownEquation =
          StringMap.mem id latest.S.indeps ||
          StringMap.mem id latest.S.deps
        in

        if not isKnownEquation then eMap else
          let forked : S.equation_relations =
            let deps : string list = getStmtDeps (A.Expr(e)) in
            if List.length deps > 0 then
              {
                S.deps = StringMap.add id deps latest.S.deps;
                S.indeps = StringMap.remove id latest.S.indeps;
              }
            else
              {
                S.deps = StringMap.remove id latest.S.deps;
                S.indeps = StringMap.add id [A.Expr(e)] latest.S.indeps;
              }
          in S.IntMap.add i forked eMap
      in findExprRelator (maybeExtendedExprMap, i) e
    | A.Builtin(_, exprLis) -> List.fold_left findExprRelator (eMap, i) exprLis

  in match st with
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
