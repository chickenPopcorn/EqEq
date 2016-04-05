(* Semantic Analysis API: `sast`
 *   For more, see: ../notes/whiteboard-eq-analysis.md
 *)

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
type sast = StringMap
