(* Semantic checking for the EqualsEquals compiler *)

open Ast

module StringMap = Map.Make(String)

(* Semantic checking of a program. Returns void if successful,
   throws an exception if something is wrong.

   Check each context, then check each find declaration *)

let check (contexts, finds) =

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

  (**** Checking Context blocks  ****)

  report_duplicate (fun n -> "duplicate context " ^ n) (List.map snd contexts);

  (**** Checking Find blocks ****)
  (* TODO: figure out how author might screw `find` expressions, and add here *)

  (* Function declaration for a named function *)
  let built_in_decls =  StringMap.add "print"
     { typ = Void; fname = "print"; formals = [(Int, "x")];
       locals = []; body = [] } (StringMap.singleton "printb"
     { typ = Void; fname = "printb"; formals = [(Bool, "x")];
       locals = []; body = [] })
   in

  let function_decls =
    List.fold_left
      (fun m fd -> StringMap.add fd.fname fd m)
      built_in_decls
      finds
  in

  let function_decl s =
    try StringMap.find s function_decls
    with Not_found -> raise (Failure ("unrecognized function " ^ s))
  in

  let _ = function_decl "main" in (* Ensure "main" is defined *)

  let check_find findBlk =

    List.iter (check_not_void (fun n -> "illegal void formal " ^ n ^
      " in " ^ findBlk.fname)) findBlk.formals;

    report_duplicate (fun n -> "duplicate formal " ^ n ^ " in " ^ findBlk.fname)
      (List.map snd findBlk.formals);

    List.iter (check_not_void (fun n -> "illegal void local " ^ n ^
      " in " ^ findBlk.fname)) findBlk.locals;

    report_duplicate (fun n -> "duplicate local " ^ n ^ " in " ^ findBlk.fname)
      (List.map snd findBlk.locals);

    (* Type of each find block (global, formal, or local *)
    let symbols = List.fold_left (fun m (t, n) -> StringMap.add n t m)
      StringMap.empty (contexts @ findBlk.formals @ findBlk.locals )
    in

    let type_of_identifier s =
      try StringMap.find s symbols
      with Not_found -> raise (Failure ("undeclared identifier " ^ s))
    in

    (* Return the type of an expression or throw an exception *)
    let rec expr = function
        Literal _ -> Int
      | BoolLit _ -> Bool
      | Id s -> type_of_identifier s
      | Binop(e1, op, e2) as e ->
          let t1 = expr e1 and t2 = expr e2 in (
            match op with
                Add | Sub | Mult | Div when t1 = Int && t2 = Int -> Int
              | Equal | Neq when t1 = t2 -> Bool
              | Less | Leq | Greater | Geq when t1 = Int && t2 = Int -> Bool
              | And | Or when t1 = Bool && t2 = Bool -> Bool
              | _ -> raise (Failure ("illegal binary operator " ^
                    string_of_typ t1 ^ " " ^ string_of_op op ^ " " ^
                    string_of_typ t2 ^ " in " ^ string_of_expr e))
          )
      | Unop(op, e) as ex -> let t = expr e in
         (match op with
           Neg when t = Int -> Int
         | Not when t = Bool -> Bool
         | _ -> raise (Failure ("illegal unary operator " ^ string_of_uop op ^
           string_of_typ t ^ " in " ^ string_of_expr ex)))
      | Noexpr -> Void
      | Assign(var, e) as ex -> let lt = type_of_identifier var
                                and rt = expr e in
        check_assign (type_of_identifier var) (expr e)
                 (Failure ("illegal assignment " ^ string_of_typ lt ^ " = " ^
                           string_of_typ rt ^ " in " ^ string_of_expr ex))
      | Builtin(fname, actuals) as call -> let fd = function_decl fname in
         if List.length actuals != List.length fd.formals then
           raise (Failure ("expecting " ^ string_of_int
             (List.length fd.formals) ^ " arguments in " ^ string_of_expr call))
         else
           List.iter2 (fun (ft, _) e -> let et = expr e in
              ignore (check_assign ft et
                (Failure ("illegal actual argument found " ^ string_of_typ et ^
                " expected " ^ string_of_typ ft ^ " in " ^ string_of_expr e))))
             fd.formals actuals;
           fd.typ
    in

    let check_bool_expr e =
      if expr e != Bool then
        raise (Failure ("expected Boolean expression in " ^ string_of_expr e))
      else ()
    in

    (* Verify a statement or throw an exception *)
    let rec stmt = function
        Block sl ->
          let rec check_block = function
              [Return _ as s] -> stmt s
            | Return _ :: _ -> raise (Failure "nothing may follow a return")
            | Block sl :: ss -> check_block (sl @ ss)
            | s :: ss -> stmt s ; check_block ss
            | [] -> ()
          in check_block sl
      | Expr e -> ignore (expr e)
      | Return e ->
          let t = expr e in
          if t = findBlk.typ then () else
          raise (Failure ("return gives " ^ string_of_typ t ^ " expected " ^
                             string_of_typ findBlk.typ ^ " in " ^ string_of_expr e))
      | If(p, b1, b2) -> check_bool_expr p; stmt b1; stmt b2
      | For(e1, e2, e3, st) -> ignore (expr e1); check_bool_expr e2;
                               ignore (expr e3); stmt st
      | While(p, s) -> check_bool_expr p; stmt s
    in

    stmt (Block findBlk.body)

  in
  List.iter check_find finds
