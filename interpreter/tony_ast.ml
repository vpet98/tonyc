type typ = TY_int | TY_bool | TY_char | TY_array of typ | TY_list of typ
type paramPas = BY_val | BY_ref
type operator = O_plus | O_minus | O_times | O_div | O_mod
type lg_operator = LO_eq | LO_dif | LO_less | LO_greater | LO_less_eq | LO_greater_eq
type bool_val = True | False
type and_or = And | Or

type ast_formal = Formal of paramPas * typ * string list

type ast_header = Header of typ option * string * ast_formal list

type ast_func_decl = Func_decl of ast_header

type ast_var_def = Var_def of typ * string list

type ast_expr =
  | E_atom of ast_atom
  | E_int_const of int
  | E_char_const of char
  | E_un_plus of ast_expr
  | E_un_minus of ast_expr
  | E_op of ast_expr * operator * ast_expr
  | E_lg_op of ast_expr * lg_operator * ast_expr
  | E_bool of bool_val
  | E_not of ast_expr
  | E_and_or of ast_expr * and_or * ast_expr
  | E_new of typ * ast_expr
  | E_nil of unit
  | E_is_nil of ast_expr
  | E_cons of ast_expr * ast_expr
  | E_head of ast_expr
  | E_tail of ast_expr

and ast_call = C_call of string * ast_expr list

and ast_atom =
  | A_var of string
  | A_string_const of string
  | A_atom of ast_atom * ast_expr
  | A_call of ast_call

type ast_simple =
  | S_skip of unit
  | S_assign of ast_atom * ast_expr
  | S_call of ast_call

type ast_stmt =
  | S_simple of ast_simple
  | S_exit of unit
  | S_return of ast_expr
  | S_if of ast_expr * ast_stmt list * ast_elsif_stmt * ast_else_stmt
  | S_for of ast_simple list * ast_expr * ast_simple list * ast_stmt list

and ast_elsif_stmt = S_elsif of ast_expr * ast_stmt list * ast_elsif_stmt

and ast_else_stmt = S_else of ast_stmt list

type ast_func_def = Func_def of ast_header * ast_def list * ast_stmt list

and ast_def =
  | F_def of ast_func_def
  | F_decl of ast_func_decl
  | V_def of ast_var_def


module Vars = Map.Make(String)
let vars = ref Vars.empty

(* let (a name here)_formal ast =
  match ast with
  | Formal (pp, t, strs) ->

let (a name here)_header ast =
  match ast with
  | Header (mt, str, formals) ->

let (a name here)_func_decl ast =
  match ast with
  | Func_decl h ->

let (a name here)_var_def ast =
  match ast with
  | Var_def (t, strs) -> *)

let rec run_expr ast = (* compiler says things in right side of -> have to be of same type, there must be another way... *)
  match ast with
  | E_atom a              -> run_atom a
  | E_int_const n         -> n
  | E_char_const c        -> c
  | E_un_plus e           -> let v = run_expr e in +v
  | E_un_minus e          -> let v = run_expr e in -v
  | E_op (e1, op, e2)     -> let v1 = run_expr e1
                             and v2 = run_expr e2 in
            		             (match op with
            		             | O_plus  -> v1 + v2
            		             | O_minus -> v1 - v2
                             | O_times -> v1 * v2
                             | O_div   -> v1 / v2
                             | O_mod   -> v1 mod v2)
  | E_lg_op (e1, op, e2)  -> let v1 = run_expr e1
                             and v2 = run_expr e2 in
            		             (match op with
            		             | LO_eq         -> v1 = v2
            		             | LO_dif        -> v1 != v2
                             | LO_less       -> v1 < v2
                             | LO_greater    -> v1 > v2
                             | LO_less_eq    -> v1 <= v2
                             | LO_greater_eq -> v1 >= v2)
  | E_bool b              -> (match b with
                             | True  -> true
                             | False -> false)
  | E_not e               -> let v = run_expr e in
                             not v
  | E_and_or (e1, ao, e2) -> let v1 = run_expr e1
                             and v2 = run_expr e2 in
                             (match ao with
                             | And -> v1 && v2
                             | Or  -> v1 || v2)
  | E_new (t, e)          -> () (* just for test, not correct *)
  | E_nil ()              -> []
  | E_is_nil e            -> let v = run_expr e in
                             v = []
  | E_cons (e1, e2)       -> let v1 = run_expr e1
                             and v2 = run_expr e2 in
                             v1::v2
  | E_head e              -> let v = run_expr e in
                             List.hd v
  | E_tail e              -> let v = run_expr e in
                             List.tl v

and dummy_call ast = () (* just for test, not correct, name dummy has to change *)

and (*rec*) run_atom ast =
  match ast with
  | A_var v            -> vars := Vars.add v None !vars
  | A_string_const str -> str
  | A_atom (a, e)      -> () (* just for test, not correct *)
  | A_call c           -> dummy_call c

let run_simple ast =
  match ast with
  | S_skip          -> ()
  | S_assign (a, e) -> let x = run_atom a
                       and y = run_expr e in
                       vars := Vars.add x (Some y) !vars
  | S_call c        -> dummy_call c

let rec run_stmt ast =
  match ast with
  | S_simple s                         -> run_simple s
  | S_exit                             -> () (* just for test, not correct *)
  | S_return e                         -> let v = run_expr e in v (* needs more *)
  | S_if (e, stmts, elsif, els)        -> let v = run_expr e in
                                          if v then List.iter run_stmt stmts;
                                                    run_elsif_stmt elsif;
                                                    run_else_stmt els
  | S_for (simples, e, simples, stmts) -> let v = run_expr e
                                          and s = List.iter run_simple simples in
                                          while v do (*something is wrong with s*)
                                            run_stmt s;
                                            List.iter run_simple simples;
                                          done

let rec run_elsif_stmt ast =
  match ast with
  | () -> ()
  | S_elsif (e, stmts, elsif) -> let v = run_expr e in
                                 if v then List.iter run_stmt stmts;
                                           run_elsif_stmt elsif

let run_else_stmt ast =
  match ast with
  | () -> ()
  | S_else stmts -> List.iter run_stmt stmts

let run_func_def ast =
  match ast with
  | Func_def (h, defs, stmts) ->
      (* (a name here)_header h;
      List.iter run_def defs; *)
      List.iter run_stmt stmts

(*and run_def ast =
  match ast with
  | F_def fdef   -> run_func_def fdef
  | F_decl fdecl -> (a name here)_func_decl fdecl
  | V_def vdef   -> (a name here)_var_def vdef *)

let run ast = run_func_def ast
