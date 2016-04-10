(* Semantic Analysis API: `checked` AST *)

module A = Ast
module StringMap = Map.Make(String)

(* <EquationName(string), string list> *)
type equation_deps = StringMap

(* <EquationName(string), A.Expr> *)
type variables_indeps = StringMap

type equation_relations = equation_deps * variables_indeps

(* <FindName(string), equation_relations> *)
type find_scopes = StringMap

type ctx_scopes = equation_deps * variables_indeps * find_scopes

(* <CtxName(string), ctx_scopes> *)
type eqResolutions = (ctx_scopes StringMap.t)

(* Map: <ctx.context, <multieq.fname, multieq>> *)
type varMap = (Ast.multi_eq StringMap.t) StringMap.t

(* TODO: add `eqResolutions` here*)
type checked = {
  ast: Ast.program;
  vars: varMap;
}
