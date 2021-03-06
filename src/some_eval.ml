open Some_types
open Printf

(* Eval step count *)
let count = ref 0
let break = ref false
let cont = ref false

(* Result to string *)
let rec string_of_eval = function
  | Bool b -> string_of_bool b
  | Integer i -> string_of_int i
  | Address a -> "Address: " ^ string_of_int a
  | _ -> "()"

(* Functions *)
let funs = Hashtbl.create 100

(* Store *)
let store = ref (Hashtbl.create 100)

(* Store fetch *)
let rec store_fetch key =
  try Hashtbl.find !store key
         with Not_found -> failwith ("Unable to match - Address out of bounds")

(* Address generation *)
let addr = ref 0
let newref () = addr:=!addr+1; !addr

(* Environment lookup *)
let rec lookup env s =
  match env with
  | (s',v)::env -> if s = s' then v else lookup env s
  | _ -> failwith ("Unable to match - Value "^s^" not found")

(* Operation evaluation *)
let eval_op op e e' =
  count := !count + 1;
  match (op, e, e') with
    | (Add, Integer e, Integer e') -> Integer (e+e')
    | (Sub, Integer e, Integer e') -> Integer (e-e')
    | (Mul, Integer e, Integer e') -> Integer (e*e')
    | (Div, Integer e, Integer e') -> Integer (e/e')
    | (Eq, Integer e, Integer e') -> Bool (e==e')
    | (Le, Integer e, Integer e') -> Bool (e<e')
    | (Ge, Integer e, Integer e') -> Bool (e>e')
    | (Leq, Integer e, Integer e') -> Bool (e<=e')
    | (Geq, Integer e, Integer e') -> Bool (e>=e')
    | (And, Bool e, Bool e') -> Bool (e&&e')
    | (Or, Bool e, Bool e') -> Bool (e||e')
    | _ -> failwith "Unable to match - Operator applied to invalid operands"

(* Type of value *)
let bool_of_value = function
  | Bool b -> b
  | Integer 0 -> false
  | Integer 1 -> true
  | _ -> failwith "Unable to match - boolean condition does not evaluate to type bool"

(* Expression evaluation *)
let rec eval_exp env exp =
  count := !count + 1;
  match exp with
  | Const i -> Integer i
  | Readint -> Integer (read_int ())
  | Printint e -> (eval_exp env e) |> string_of_eval |> printf "%s\n"; Unit ()
  | Let (s, e, e') -> let v = eval_exp env e in
              eval_exp ((s, v)::env) e'
  | New (s, e, e') -> let v = eval_exp env e in
            let addr = Address(newref ()) in
            Hashtbl.replace !store addr v;
            let v' = eval_exp ((s, addr)::env) e' in
            Hashtbl.remove !store addr;
            v'
  | Application (s, args) -> let res = eval_fundef (s, List.map (eval_exp env) args) env in
                             if !cont || !break
                             then failwith "Unable to match - Constrol statement outside loop"
                             else res
  | Identifier s -> lookup env s
  | Seq (e, e') -> let res = eval_exp env e in
           if not !break && not !cont then eval_exp env e' else res
  | Lambda (args, e') -> Function (args, e')
  | Asg (e, e') -> let left = eval_exp env e in
           let right = eval_exp env e' in
           store_fetch left |> ignore;
           Hashtbl.replace !store left right;
           Unit ()
  | Operation (op, e, e') -> eval_op op (eval_exp env e) (eval_exp env e')
  | Negation e -> let exp = eval_exp env e in (match exp with
                      | Bool a -> Bool (not a)
                      | _ -> failwith "Unable to match - Negation condition does not evaluate to type bool")
  | If (e, e', e'') -> let branch = bool_of_value (eval_exp env e) in
              if branch then eval_exp env e' else eval_exp env e''
  | While (e, e') -> let branch = bool_of_value (eval_exp env e) in
              if branch then (let res = eval_exp env e' in
                         let rebranch = bool_of_value (eval_exp env e) in
                           if rebranch && not !break
                          then (cont := false; eval_exp env (While (e, e')))
                          else (break := false; cont := false; res))
              else Unit ()
  | Deref e -> store_fetch (eval_exp env e)
  | Return e -> eval_exp env e
  | Break -> break := true; Unit ()
  | Continue -> cont := true; Unit ()

(* Function evaluation *)
and eval_fundef (name, argvs) env =
  let (args, exp) = try Hashtbl.find funs name
             with Not_found -> lambda_fetch name env in
  let tempStore = Hashtbl.copy !store in
  Hashtbl.clear !store;
  let env = List.map2 (fun arg argv -> (arg, argv)) args argvs in
  let res = eval_exp env exp in
  store := tempStore;
  res

(* Lambda evaluation *)
and lambda_fetch name env =
  let v = try Hashtbl.find !store (lookup env name)
         with Not_found -> lookup env name in
  match v with
  | Function (args, e) -> (args, e)
  | _ -> failwith ("Unable to match - Function definition "^ name ^" not found")

(* Program evaluation *)
let rec eval_prog = function
  | (name, args, exp)::prog -> Hashtbl.replace funs name (args, exp); eval_prog prog
  | _ -> let res = eval_fundef ("main", []) [] in
         if !cont || !break
         then failwith "Unable to match - Control statement outside loop"
         else res
