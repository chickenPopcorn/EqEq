(* Semantic Analysis API: `checked` AST *)

module StringMap = Map.Make(String)

(* Map: <ctx.context, <multieq.fname, multieq>> *)
type varMap = (Ast.multi_eq StringMap.t) StringMap.t

type checked = {
  ast: Ast.program;
  vars: varMap;
}
