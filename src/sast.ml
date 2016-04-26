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
let str_of_checked chk =
  let indent depth =
    let rec indentStr = function
      | 0 -> []
      | i -> "    "::(indentStr (i - 1))
    in List.fold_left (fun s ind -> s ^ ind) "" (indentStr depth)
  in

  (* Thin wrapper for `StringMap.fold` that passes extra `depth` field in
   * accumulator, and discards it in the final result. *)
  let strMapFold func str_map accumulator startDepth =
    let (result, _) =
      StringMap.fold func str_map (accumulator, startDepth)
    in result
  in

  (* Thin wrapper for `IntMap.fold`, identical to strMapFold. *)
  let intMapFold func int_map accumulator startDepth =
    let (result, _) =
      IntMap.fold func int_map (accumulator, startDepth)
    in result
  in

  let str_of_deps eq_name (depList : string list) (str, (depth : int)) =
    let rendered =
      str ^
      indent depth ^ eq_name ^
      ": [" ^ (String.concat ", " depList) ^ "]\n"
    in (rendered, depth)
  in
  let str_of_indeps eq_name (stmtList : A.stmt list) (str, depth) =
    let rendered =
      let indented_stmts = List.map (
        fun stmt -> indent (depth + 1) ^ A.string_of_stmt stmt
      ) stmtList in

      str ^

      String.concat "\n" [
        indent depth ^ eq_name ^ " : ```";

        String.concat "" indented_stmts;

        indent depth ^ "```";
      ] ^ "\n"
    in (rendered, depth)
  in
  let str_of_finds fdname (finds : (equation_relations IntMap.t)) (str, depth) =
    let str_of_eqrelmap exprIndex (relmap : equation_relations) (str, depth) =
      let rendered =
        str ^
        String.concat "\n" [
          (indent depth) ^ "[" ^ string_of_int exprIndex ^ "]: {";

          String.concat "\n" [
            indent (depth + 1) ^ "deps:" ;
            strMapFold str_of_deps relmap.deps "" (depth + 2);

            indent (depth + 1) ^ "indeps:" ;
            strMapFold str_of_indeps relmap.indeps "" (depth + 2);
          ];

          (indent depth) ^ "}";
        ] ^ "\n"
      in (rendered, depth)
    in

    let rendered =
      str ^
      String.concat "\n" [
        indent depth ^ "\"" ^ fdname ^ "\": {";
        String.concat "\n" [
          intMapFold str_of_eqrelmap finds "" (depth + 1)
        ];
        indent depth ^ "}\n";
      ] ^ "\n"
    in (rendered, depth)
  in

  let str_of_ctxscope ctxname scope (str, depth) =
    let rendered =
      indent depth ^

      String.concat "\n" [
        str;
        ctxname ^ " : {";

        String.concat "\n" [
          indent (depth + 1) ^ "deps:";
          strMapFold str_of_deps scope.ctx_deps "" (depth + 2);

          indent (depth + 1) ^ "indeps:";
          strMapFold str_of_indeps scope.ctx_indeps "" (depth + 2);

          indent (depth + 1) ^ "finds:";
          strMapFold str_of_finds scope.ctx_finds "" (depth + 2);
        ];
        "}";
      ] ^ "\n"
    in (rendered, depth)

  in (strMapFold str_of_ctxscope chk.eqs "" 0)
