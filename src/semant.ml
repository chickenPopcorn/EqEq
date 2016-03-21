(* Semantic checking for the EqualsEquals compiler *)

open Ast

module StringMap = Map.Make(String)

(* Semantic checking of a program. Returns void if successful,
   throws an exception if something is wrong.

   Check each context, then check each find declaration *)

let check (contexts, finds) =
  ();
(*
  (* Raise an exception if the given list has a duplicate *)
  let report_duplicate exceptf list =
    let rec helper = function
      n1 :: n2 :: _ when n1 = n2 -> raise (Failure (exceptf n1))
          | _ :: t -> helper t
          | [] -> ()
    in helper (List.sort compare list)
  in

  (* Raise an exception of the given rvalue type cannot be assigned to
     the given lvalue type
  let check_assign lvaluet rvaluet err =
     if lvaluet == rvaluet then lvaluet else raise err
  in

  TODO: possible ^ given how we've structured string-literals in our grammar? *)

  (**** List of known Context blocks  ****)
  let known_ctxs =
    List.fold_left
      (
        ctx, existing ->
          if StringMap.mem ctx.context existing then
            raise (Failure "duplicate context, " ^ ctx.context)
          else StringMap.add ctx.context ctx existing
      )
      StringMap.empty
      contexts
  in

  let check_have_context supposed_ctx_name =
    if StringMap.mem supposed_ctx_name known_ctxs then
      raise (Failure "unrecognized context, " ^ supposed_ctx_name)
    else StringMap.find supposed_ctx_name known_ctxs
  in

  report_duplicate (fun n -> "duplicate context " ^ n) (List.map snd contexts);

  (* Builtin declarations we provide *)
  let builtin_decls =
    StringMap.add
      "print" (Builtin("print", [])) (
        StringMap.add "range" (Builtin("range", [])) (
          StringMap.add "cos" (Builtin("cos", [])) StringMap.empty
        )
      )
   in

  let function_decl s =
    try StringMap.find s function_decls
    with Not_found -> raise (Failure ("unrecognized function " ^ s))
  in

  let _ = function_decl "main" in (* Ensure "main" is defined *)


  (* Type of each find block (global, formal, or local *)
  let symbols = List.fold_left (fun m (t, n) -> StringMap.add n t m)
    StringMap.empty (contexts @ findBlk.formals @ findBlk.locals )
  in

  let type_of_identifier s =
    try StringMap.find s symbols
    with Not_found -> raise (Failure ("undeclared identifier " ^ s))
  in

  (* TODO(copy/pasted from ast.ml): update this to match:
   *    type expr =
   *        Literal of int
   *      | BoolLit of bool
   *      | Id of string
   *      | Binop of expr * op * expr
   *      | Unop of uop * expr
   *      | Assign of string * expr
   *      | Builtin of string * expr list
   *      | Noexpr
   *)
  (* Return the type of an expression or throw an exception *)
  let rec check_expr = function
      Literal _ -> Int
    | BoolLit _ -> Bool
    | Id s -> type_of_identifier s
    | Binop(e1, op, e2) as e ->
        let t1 = check_expr e1 and t2 = check_expr e2 in (
          match op with
              Add | Sub | Mult | Div when t1 = Int && t2 = Int -> Int
            | Equal | Neq when t1 = t2 -> Bool
            | Less | Leq | Greater | Geq when t1 = Int && t2 = Int -> Bool
            | And | Or when t1 = Bool && t2 = Bool -> Bool
            | _ -> raise (Failure ("illegal binary operator " ^
                  string_of_typ t1 ^ " " ^ string_of_op op ^ " " ^
                  string_of_typ t2 ^ " in " ^ string_of_expr e))
        )
    | Unop(op, e) as ex -> let t = check_expr e in
       (match op with
         Neg when t = Int -> Int
       | Not when t = Bool -> Bool
       | _ -> raise (Failure ("illegal unary operator " ^ string_of_uop op ^
         string_of_typ t ^ " in " ^ string_of_expr ex)))
    | Noexpr -> Void
    | Assign(var, e) as ex -> let lt = type_of_identifier var
                              and rt = check_expr e in
      check_assign (type_of_identifier var) (check_expr e)
               (Failure ("illegal assignment " ^ string_of_typ lt ^ " = " ^
                         string_of_typ rt ^ " in " ^ string_of_expr ex))
    | Builtin(fname, actuals) as call -> let fd = function_decl fname in
       if List.length actuals != List.length fd.formals then
         raise (Failure ("expecting " ^ string_of_int
           (List.length fd.formals) ^ " arguments in " ^ string_of_expr call))
       else
         List.iter2 (fun (ft, _) e -> let et = check_expr e in
            ignore (check_assign ft et
              (Failure ("illegal actual argument found " ^ string_of_typ et ^
              " expected " ^ string_of_typ ft ^ " in " ^ string_of_expr e))))
           fd.formals actuals;
         fd.typ
  in

  let check_bool_expr e =
    if check_expr e != Bool then
      raise (Failure ("expected Boolean expression in " ^ string_of_expr e))
    else ()
  in

  (* Verify a statement or throw an exception *)
  let rec check_stmt = function
      Block sl ->
        (* effectively unravel statements out of their block *)
        let rec check_block = function
            Block sl :: ss -> check_block (sl @ ss)
          | s :: ss -> check_stmt s ; check_block ss
          | [] -> ()
        in check_block sl
    | Expr e -> ignore (check_expr e)
    | If(p, b1, b2) -> check_bool_expr p; check_stmt b1; check_stmt b2
    | While(p, s) -> check_bool_expr p; check_stmt s
  in

  (**** Checking Context blocks  ****)
  let check_ctxs ctxBlk =
    (* TODO: semantic analysis of variables, allow undeclared and all the stuff
     * that makes our lang special... right here!
    let knowns = [(*  *)] in
    let unknowns = [] in
    *)
    check_stmt (Block ctxBlk.body)
  in

  List.iter check_ctxs contexts in

  (**** Checking Find blocks ****)
  let check_find findBlk =
    let check_have_context =
      try StringMap.find expected_ctx_name known_ctxs
      with Not_found -> raise (
        Failure ("`find` targeting unrecognized context " ^ expected_ctx_name)
      )
    in

    report_duplicate (fun n -> "duplicate local " ^ n ^ " in " ^ findBlk.fname)
      (List.map snd findBlk.locals);

    check_have_context fidBlk.target;
    check_stmt (Block findBlk.body);

  in
  List.iter check_find finds
*)
