module A = Ast
module S = Sast
module StringMap = Map.Make(String)

let fail msg = raise (Failure msg)
let quot content = "\"" ^ content ^  "\""

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


let rec asrt_resolves (root : A.expr) (m : S.equation_relations S.IntMap.t) i =
  let was_previously_resolvable : (string -> string -> bool) = (
    fun prnt chld -> (prnt = chld) && (asrt_resolves root m (i - 1); true)
  ) in

  let m = latest i m in

  let assert_notseen parent id (visited : bool StringMap.t) : unit =
    if StringMap.mem id visited then fail (
      "Cyclical dependency under, " ^
      quot parent ^
      "; stopped at ID=" ^ quot id
    )
  in

  let check_deps_resolvable (id : string) : unit =
    (* Asserts identifier terminates in `m`, and hasn't already been seen. *)
    let rec terminates (target : string) (seen : bool StringMap.t) : unit =
      assert_notseen id target seen;

      if not (StringMap.mem target m.S.indeps) then (
        if StringMap.mem target m.S.deps
        then
          List.iter (
            fun dp -> terminates dp (StringMap.add target true seen);
          ) (StringMap.find target m.S.deps)
        else
          (* TODO: NEXT STEP: make `test-lazyresolved-vars-increment-self`
           *   pass this is done by passing in *two* maps to
           *   `asrt_resolves`, the previous map and the current map.
           *
           *   IF all of the following:
           *     1) `id` fails in *this* else branch
           *     2) `target` == `id`
           *     3) `id` is in the *old* map's `indeps` field
           *   THEN allow it to pass
           *)
          if not (was_previously_resolvable id target) then fail (
            "Unresolvable identifier, " ^ (quot target) ^
            " found while following " ^ (quot id) ^
            "'s dependency chain."
          );
      )

    in terminates id StringMap.empty;
  in

  (* TODO: figure out how to ensure failures for `undefinedvar` in `e` for
   * an expression:  `find{ a = b = undefinedvar + 1}`
   *)
  let rec chk_resolvable e : unit = match e with
  | A.Id(id) -> (
      if not (StringMap.mem id m.S.indeps)
      then check_deps_resolvable id;
    );
  | A.Literal(_) | A.Strlit(_) -> ();
  | A.Binop(el, _, er) -> List.iter chk_resolvable [el; er];
  | A.Unop(_, e) -> chk_resolvable e;
  | A.Assign(_, e) -> chk_resolvable e;
  | A.Builtin(_, eLi) -> List.iter chk_resolvable eLi;
  in chk_resolvable root

(* List.fold_left handler for find decl's fbody. *)
let rec findStmtRelator (m, i) (st : A.stmt) =
  let rec findExprRelator (eMap, idx) (expr : A.expr) =
    asrt_resolves expr eMap idx;

    let i = idx + 1 in match expr with
    | A.Id(id) -> asrt_resolves (A.Id(id)) eMap i; (eMap, i)
    | A.Literal(_) | A.Strlit(_) -> (eMap, i)
    | A.Binop(eLeft, _, eRight) ->
      findExprRelator (findExprRelator (eMap, i) eLeft) eRight
    | A.Unop(_, e) -> findExprRelator (eMap, i) e
    | A.Assign(id, e) ->
      asrt_resolves e eMap i;

      (* If `id` already exists, then it's being redefined, in which case we'll
       * start a new `S.equation_relations` at the current expression index.
       * Else we'll keep using the current S.equation_relations, `eMap` as-is.
       *)
      let maybeExtendedExprMap =
        let current = latest i eMap in

        let isKnownEquation =
          StringMap.mem id current.S.indeps ||
          StringMap.mem id current.S.deps
        in

        if not isKnownEquation then eMap (* use as-is *) else
          let forked : S.equation_relations =
            let deps : string list = getStmtDeps (A.Expr(e)) in
            if List.length deps > 0 then
              {
                S.deps = StringMap.add id deps current.S.deps;
                S.indeps = StringMap.remove id current.S.indeps;
              }
            else
              {
                S.deps = StringMap.remove id current.S.deps;
                S.indeps = StringMap.add id [A.Expr(e)] current.S.indeps;
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
