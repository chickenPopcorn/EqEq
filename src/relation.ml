module A = Ast
module S = Sast
module StringMap = Map.Make(String)

let fail msg = raise (Failure msg)
let quot content = "\"" ^ content ^  "\""

(* eg, for expression, "a = 3 + b;", return ["b"]. *)
let get_ids (e : A.expr) : string list =
  let rec ids expr (accum : string list) : string list = match expr with
  | A.Id(id) -> id::accum
  | A.Literal(_) | A.Strlit(_) -> accum
  | A.Binop(el, _, er) -> ids er (ids el accum)
  | A.Unop(_, e) -> ids e accum
  | A.Assign(_, e) -> ids e accum
  | A.Builtin(_, eLi) ->
      List.fold_left (fun a e -> ids e a) accum eLi
  in ids e []

(* Newest value in `map`; ie: where largest key <= `i` *)
let latest (asof : int) (m : S.equation_relations S.IntMap.t) : S.equation_relations =
  let rec walkBack i =
    try S.IntMap.find i m with Not_found ->
      if i > 0 then walkBack (i - 1) else fail (
          Printf.sprintf
            "Compiler BUG: empty rel-map at expression #%d [only found: '%s']"
            asof (String.concat "', '" (
                S.IntMap.fold
                  (fun k v a -> (string_of_int k)::a)
                  m []
              ))
        )
  in walkBack asof

(* Lists all `A.Id`s in the given `stmt` *)
let rec getStmtDeps (stmt : A.stmt) : string list =
  let rec getAssignDeps (foundDeps : string list) (st : A.stmt) : string list =
    let getExprIDs (accum : string list) e : string list = (get_ids e)@accum in

    let accumStmtLi accum (sLi : A.stmt list) =
      List.fold_left (fun a s -> a@(getStmtDeps s)) accum sLi
    in

    match st with
    | A.Break | A.Continue -> foundDeps
    | A.Expr(e) -> getExprIDs foundDeps e
    | A.If(stmtOrTupleList) -> (
        let rec idsInIf accumul = function
          | [] -> accumul
          | (None,sLi)::t -> idsInIf (accumStmtLi accumul sLi) t
          | (Some(e),sLi)::t ->
              idsInIf (getExprIDs (accumStmtLi accumul sLi) e) t
        in idsInIf foundDeps stmtOrTupleList
      )
    | A.While(e, s) -> getExprIDs (accumStmtLi foundDeps s) e
  in getAssignDeps [] stmt

let check_deps_resolvable (id : string) (m : S.equation_relations) : unit =
  (* Asserts identifier terminates in `m`, and hasn't already been seen. *)
  let rec terminates (target : string) (seen : bool StringMap.t) : unit =
    if StringMap.mem target seen
    then fail (
      "Cyclical dependency under, " ^
      quot target ^ "; stopped at ID=" ^ quot id
    )
    else if not (StringMap.mem target m.S.indeps) then (
      if StringMap.mem target m.S.deps
      then
        List.iter (
          fun dp -> terminates dp (StringMap.add target true seen);
        ) (StringMap.find target m.S.deps)
      else
        fail (
          "Unresolvable identifier, " ^ (quot target) ^
          " found while following " ^ (quot id) ^
          "'s dependency chain."
        );
    )
  in terminates id StringMap.empty

(* List.fold_left handler for a context.A.cbody; Returns its accumulator. *)
let ctxBodyRelator ((m : S.equation_relations), (urs : string list)) (meq : A.multi_eq) =
  let is_resolvable id m : bool =
    try
      check_deps_resolvable id m;
      true
    with _ -> false
  in

  let rec exprRelator (eRels, unresolveds) = function
    | A.Id(id) ->
        if is_resolvable id eRels
        then (eRels, unresolveds)
        else (eRels, id::unresolveds)
    | A.Literal(_) | A.Strlit(_) -> (eRels, unresolveds)
    | A.Binop(eLeft, _, eRight) ->
      exprRelator (exprRelator (eRels, unresolveds) eLeft) eRight
    | A.Unop(_, e) -> exprRelator (eRels, unresolveds) e
    | A.Assign(id, e) ->
      (** traverse depth first *)
      let (current, u) = exprRelator (eRels, unresolveds) e in

      let forked : S.equation_relations =
        if List.length u > 0
        then
          {
            S.deps = StringMap.add id u current.S.deps;
            S.indeps = StringMap.remove id current.S.indeps;
          }
        else
          {
            S.deps = StringMap.remove id current.S.deps;
            S.indeps = StringMap.add id [A.Expr(e)] current.S.indeps;
          }
      in (forked, u)
    | A.Builtin(_, exprLis) ->
        List.fold_left exprRelator (eRels, unresolveds) exprLis
  in

  let rec stLiRelator acc (sLi : A.stmt list) : (S.equation_relations * string list) =
    let statementRelator (m, u) = function
      | A.Break | A.Continue -> (m, u)
      | A.Expr(e) -> exprRelator (m, u) e
      | A.If(stmtTupleWithOptionalExpr) ->
        let rec relationsInIf accum = function
          | [] -> accum
          | (None, sLi)::tail -> relationsInIf (stLiRelator accum sLi) tail
          | (Some(e), sLi)::tail ->
            relationsInIf (stLiRelator (exprRelator accum e) sLi) tail
        in relationsInIf (m, u) stmtTupleWithOptionalExpr
      | A.While(e, sLi) -> stLiRelator (exprRelator (m, u) e) sLi
    in
      List.fold_left (fun a s -> statementRelator a s) acc sLi
  in stLiRelator (m, urs) meq.A.fdbody

(* List.fold_left handler an initial map of contexts' equations, before, and
 * start an empty map for their find blocks. *)
let relationCtxFolder (relations : S.eqResolutions) ctx =
  let diToRelations d i : S.equation_relations =
    { S.deps = d; S.indeps = i; }
  in

  let ctxScope =
    let equationRels : S.equation_relations =
      let ctx_body_folder rels mEq =
        let (r, unresolveds) = ctxBodyRelator (rels, []) mEq in

        let eqName = mEq.A.fname in
        if List.length unresolveds > 0
        then (
          diToRelations
            (StringMap.add eqName unresolveds r.S.deps)
            (StringMap.remove eqName r.S.indeps)
        )
        else (
          diToRelations
            (StringMap.remove eqName r.S.deps)
            (StringMap.add eqName mEq.A.fdbody r.S.indeps)
        )

      in List.fold_left
        ctx_body_folder
        (diToRelations StringMap.empty StringMap.empty)
        ctx.A.cbody

    in {
      S.ctx_deps = equationRels.S.deps;
      S.ctx_indeps = equationRels.S.indeps;
      S.ctx_finds = StringMap.empty; (* is handled using `findStmtRelator` *)
    }
  in StringMap.add ctx.A.context ctxScope relations


(* List.fold_left handler for find decl's fbody. *)
let rec findStmtRelator ((m : S.equation_relations S.IntMap.t), (i : int)) (st : A.stmt) =
  let asrt_resolves (root : string) (m : S.equation_relations S.IntMap.t) i =
    check_deps_resolvable root (latest i m)
  in

  let rec exprRelator (eMap, idx) (expr : A.expr) =
    let i = idx + 1 in match expr with
    | A.Id(id) -> asrt_resolves id eMap i; (eMap, i)
    | A.Literal(_) | A.Strlit(_) -> (eMap, i)
    | A.Binop(eLeft, _, eRight) ->
      exprRelator (exprRelator (eMap, i) eLeft) eRight
    | A.Unop(_, e) -> exprRelator (eMap, i) e
    | A.Assign(id, e) ->
      (** traverse depth first *)
      let (m, i) = exprRelator (eMap, i) e in

      let current = latest i m in
      let deps = List.filter (fun dep -> dep <> id) (get_ids e) in

      let forked : S.equation_relations =
        if List.length deps > 0
        then
          {
            S.deps = StringMap.add id deps current.S.deps;
            S.indeps = StringMap.remove id current.S.indeps;
          }
        else
          {
            S.deps = StringMap.remove id current.S.deps;
            S.indeps = StringMap.add id [A.Expr(e)] current.S.indeps;
          }
      in ((S.IntMap.add i forked m), i)
    | A.Builtin(_, exprLis) -> List.fold_left exprRelator (eMap, i) exprLis
  in

  let stLiRelator acc (sLi : A.stmt list) =
    List.fold_left (fun a s -> findStmtRelator a s) acc sLi

  in match st with
  | A.Break | A.Continue -> (m, i)
  | A.Expr(e) -> exprRelator (m, i) e
  | A.If(stmtTupleWithOptionalExpr) ->
    let rec relationsInIf accum = function
      | [] -> accum
      | (None, sLi)::tail -> relationsInIf (stLiRelator accum sLi) tail
      | (Some(e), sLi)::tail ->
        relationsInIf (stLiRelator (exprRelator accum e) sLi) tail
    in relationsInIf (m, i) stmtTupleWithOptionalExpr
  | A.While(e, sLi) -> stLiRelator (exprRelator (m, i) e) sLi


let findInitRelator (c : S.ctx_scopes) : (S.equation_relations S.IntMap.t * int) =
  (* Initial map from starting with contexts' own relationships *)
  let inheritedCtxMap : S.equation_relations S.IntMap.t =
    let baseRelations : S.equation_relations = {
      S.indeps = c.S.ctx_indeps;
      S.deps = c.S.ctx_deps;
    } in S.IntMap.add 0 baseRelations S.IntMap.empty
  in
  let analyzeRangeRelations (m, i) =
    (* TODO: dig into `range` decl to expand upon `m` *)
    (m, i)
  in analyzeRangeRelations (inheritedCtxMap, 0)
