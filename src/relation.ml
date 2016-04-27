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
let latest (asof : int) (m : S.equation_relations S.IntMap.t) =
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

let rec asrt_resolves (root : string) (m : S.equation_relations S.IntMap.t) i =
  let m = latest i m in

  let check_deps_resolvable (id : string) : unit =
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
    in terminates id StringMap.empty;
  in check_deps_resolvable root

(* List.fold_left handler for find decl's fbody. *)
let rec findStmtRelator (m, i) (st : A.stmt) =
  let rec findExprRelator (eMap, idx) (expr : A.expr) =
    let i = idx + 1 in match expr with
    | A.Id(id) -> asrt_resolves id eMap i; (eMap, i)
    | A.Literal(_) | A.Strlit(_) -> (eMap, i)
    | A.Binop(eLeft, _, eRight) ->
      findExprRelator (findExprRelator (eMap, i) eLeft) eRight
    | A.Unop(_, e) -> findExprRelator (eMap, i) e
    | A.Assign(id, e) ->
      (** traverse depth first *)
      let (m, i) = findExprRelator (eMap, i) e in

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
    | A.Builtin(_, exprLis) -> List.fold_left findExprRelator (eMap, i) exprLis
  in

  let findStmtLi acc (sLi : A.stmt list) =
    List.fold_left (fun a s -> findStmtRelator a s) acc sLi

  in match st with
  | A.Expr(e) -> findExprRelator (m, i) e
  | A.If(stmtTupleWithOptionalExpr) ->
    let rec relationsInIf accum = function
      | [] -> accum
      | (None, sLi)::tail -> relationsInIf (findStmtLi accum sLi) tail
      | (Some(e), sLi)::tail ->
        relationsInIf (findStmtLi (findExprRelator accum e) sLi) tail
    in relationsInIf (m, i) stmtTupleWithOptionalExpr
  | A.While(e, sLi) -> findStmtLi (findExprRelator (m, i) e) sLi
