(* Semantic checking for the EqualsEquals compiler *)

open Ast

module StringMap = Map.Make(String)

(* Semantic checking of a program. Returns void if successful,
   throws an exception if something is wrong.

   Check each context, then check each find declaration *)

let check (contexts, finds) =
  let fail msg = raise (Failure msg) in

  (* string prettifiers *)
  let quot content = "\"" ^ content ^  "\"" in
  let ex_qt expr = quot (string_of_expr expr) in
  let bop_qt bop = quot (string_of_op bop) in
  let uop_qt uop = quot (string_of_uop uop) in

  (* Raise an exception if the given list has a duplicate *)
  let report_duplicate exceptf list =
    let rec helper = function
      n1 :: n2 :: _ when n1 = n2 -> fail (exceptf n1)
          | _ :: t -> helper t
          | [] -> ()
    in helper (List.sort compare list)
  in

  report_duplicate
    (fun n -> "duplicate context " ^ quot n)
    (List.map (fun c -> c.context) contexts);

  (* Raise an exception of the given rvalue type cannot be assigned to
     the given lvalue type
  let check_assign lvaluet rvaluet err =
     if lvaluet == rvaluet then lvaluet else raise err
  in

  TODO: possible ^ given how we've structured string-literals in our grammar? *)

  (**** List of known Context blocks  ****)
  let known_ctxs =
    List.fold_left
      (fun existing ctx ->
         if StringMap.mem ctx.context existing then
           fail ("duplicate context, " ^ (quot ctx.context))
         else
           StringMap.add ctx.context ctx existing
      )
      StringMap.empty
      contexts
  in

  let check_have_context ctx_name =
    try StringMap.find ctx_name known_ctxs
    with Not_found -> fail ("unrecognized context, " ^ quot ctx_name)
  in

  (* Verify a statement or throw an exception *)
  let rec check_stmt = function
      | Block sl ->
          (* effectively unravel statements out of their block *)
          let rec check_block = function
            | Block sl :: ss -> check_block (sl @ ss)
            | s :: ss -> check_stmt s; check_block ss
            | [] -> ()
          in check_block sl
      | Expr e -> (
          match e with (* Verify an expression or throw an exception *)
              | Literal(lit) -> ()
              | Strlit(str) -> ()
              | Id(id) -> ()
              | Binop(left, op, right) -> ()
              | Unop(op, expr) -> ()
              | Assign(left, expr) -> ()
              | Builtin(name, expr) -> ()
        )
      | If(p, b1, b2) ->
          check_stmt (Expr p); check_stmt b1; check_stmt b2
      | While(p, s) -> check_stmt (Expr p); check_stmt s
  in

  (**** Checking Context blocks  ****)
  let check_ctx ctxBlk =
    let check_equation eq =
      List.iter check_stmt eq.body
    in

    (* TODO: semantic analysis of variables, allow undeclared and all the stuff
     * that makes our lang special... right here!
    let knowns = [(*  *)] in
    let unknowns = [] in
    *)

    (* vanilla logic;
    let equation_decl var =
      try StringMap.find s function_decls
      with Not_found -> raise (Failure ("unrecognized variable " ^ quot s))
    in
    *)
    List.iter check_equation ctxBlk.body
  in

  (**** Checking Find blocks ****)
  let check_find findBlk =
    ignore report_duplicate
      (fun n -> "duplicate local " ^ n ^ " in " ^ findBlk.fname)
      (List.map snd findBlk.locals)

    ignore check_have_context fidBlk.target
    check_stmt findBlk.body
  in

  ignore List.iter check_ctx contexts;
  List.iter check_find finds
