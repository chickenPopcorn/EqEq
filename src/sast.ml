(* Semantic Analysis API: `checked` AST *)

module A = Ast
module StringMap = Map.Make(String)
module IntMap = Map.Make(
  struct
    type t = int
    let compare = compare
  end
)

type equation_deps = (string list) StringMap.t
type variables_indeps = (A.stmt list) StringMap.t

type equation_relations = {
  deps: equation_deps;
  indeps: variables_indeps;
}

type find_scopes = (equation_relations IntMap.t) StringMap.t

type ctx_scopes = {
  ctx_deps: equation_deps;
  ctx_indeps: variables_indeps;
  ctx_finds: find_scopes;
}

(* <CtxName(string), ctx_scopes> *)
type eqResolutions = (ctx_scopes StringMap.t)

(* Map: <ctx.context, <multieq.fname, multieq>> *)
type varMap = (Ast.multi_eq StringMap.t) StringMap.t

type checked = {
  ast: Ast.program;
  eqs: eqResolutions;
  vars: varMap;
}

(* pretty print *)
let string_of_checked chk = 
  let string_of_deps deps = ""
  in
  let string_of_indeps indeps = ""
  in
  let string_of_finds finds = ""
  in
  let string_of_ctxscope ctxname scope str =
    String.concat "\n" [
      str;
      ctxname ^ " = {";
      string_of_deps scope.ctx_deps;
      string_of_indeps scope.ctx_indeps;
      string_of_finds scope.ctx_finds;
      "}";
    ]
  in
  StringMap.fold string_of_ctxscope chk.eqs "\n" ^
  "\n\n"
