(*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *)

open Flow_js_utils
open Instantiation_utils
open Reason
open Type
open TypeUtil
module ALocFuzzyMap = Loc_collections.ALocFuzzyMap

module type INPUT = sig
  include Flow_common.BASE
end

module type OUTPUT = sig
  val try_union :
    Context.t ->
    Type.DepthTrace.t ->
    Type.use_op ->
    Type.t ->
    Reason.reason ->
    Type.UnionRep.t ->
    unit

  val try_intersection :
    Context.t -> Type.DepthTrace.t -> Type.use_t -> Reason.reason -> Type.InterRep.t -> unit

  (**
   * [try_singleton_throw_on_failure cx trace reason t u] runs the constraint
   * between (t, u) in a speculative environment. If an error is raised then a
   * SpeculationSingletonError exception is raised. This needs to be caught by
   * the caller of this function.
   *)
  val try_singleton_throw_on_failure :
    Context.t -> Type.DepthTrace.t -> Reason.reason -> Type.t -> Type.use_t -> unit
end

module Make (Flow : INPUT) : OUTPUT = struct
  open Flow

  let mk_intersection_reason r _ls = replace_desc_reason RIntersection r

  let log_synthesis_result cx _trace case speculation_id =
    let open Speculation_state in
    let { lhs_t; use_t; _ } = case in
    match use_t with
    | CallT
        {
          call_action = Funcalltype { call_speculation_hint_state = Some call_callee_hint_ref; _ };
          _;
        } ->
      let old_callee_hint = !call_callee_hint_ref in
      let new_callee_hint =
        match old_callee_hint with
        | Speculation_hint_unset ->
          let spec_id_path =
            speculation_id
            :: List.map (fun branch -> branch.speculation_id) !(Context.speculation_state cx)
          in
          Speculation_hint_set (spec_id_path, lhs_t)
        | Speculation_hint_invalid -> Speculation_hint_invalid
        | Speculation_hint_set (old_spec_id_path, old_t) ->
          if List.mem speculation_id old_spec_id_path then
            (* We are moving back a successful speculation path. *)
            old_callee_hint
          else if lhs_t == old_t then
            (* We are in a different branch, but the outcome is the same, so keep it. *)
            old_callee_hint
          else
            Speculation_hint_invalid
      in
      call_callee_hint_ref := new_callee_hint
    | _ -> ()

  let rec log_specialized_use cx use case speculation_id =
    match use with
    | CallT { call_action = Funcalltype { call_specialized_callee = Some c; _ }; _ }
    | MethodT
        ( _,
          _,
          _,
          _,
          (CallM { specialized_callee = Some c; _ } | ChainM { specialized_callee = Some c; _ })
        )
    | ReactKitT (_, _, React.CreateElement { specialized_component = Some c; _ }) ->
      let (Specialized_callee data) = c in
      let spec_id = (speculation_id, case.Speculation_state.case_id) in
      Base.List.find data.speculative_candidates ~f:(fun (_, spec_id') -> spec_id = spec_id')
      |> Base.Option.iter ~f:(fun (l, _) -> data.finalized <- l :: data.finalized)
    | OptionalChainT { t_out; _ } -> log_specialized_use cx t_out case speculation_id
    | _ -> ()

  let log_specialized_callee cx spec case speculation_id =
    match spec with
    | IntersectionCases (_, use) -> log_specialized_use cx use case speculation_id
    | _ -> ()

  (** Entry points into the process of trying different branches of union and
      intersection types.

     The problem we're trying to solve here is common to checking unions and
     intersections: how do we make a choice between alternatives, when we want
     to avoid regret (i.e., by not committing to an alternative that might not
     work out, when alternatives that were not considered could have worked out)?

     To appreciate the problem, consider what happens without choice. Partial
     information is not a problem: we emit constraints that must be satisfied for
     something to work, and either those constraints fail (indicating a problem)
     or they don't fail (indicating no problem). With choice we cannot naively
     emit constraints as we try alternatives *without also having a mechanism to
     roll back those constraints*. This is because those constraints don't *have*
     to be satisfied; some other alternative may end up not needing those
     constraints to be satisfied for things to work out!

     It is not too hard to imagine scary scenarios we can get into without a
     roll-back mechanism. (These scenarios are not theoretical, by the way: with a
     previous implementation of union and intersection types that didn't
     anticipate these scenarios, they consistently caused a lot of problems in
     real-world use cases.)

     * One bad state we can get into is where, when trying an alternative, we emit
     constraints hoping they would be satisfied, and they appear to work. So we
     commit to that particular alternative. Then much later find out that those
     constraints are unsatified, at which point we have lost the ability to try
     other alternatives that could have worked. This leads to a class of bugs
     where a union or intersection type contains cases that should have worked,
     but they don't.

     * An even worse state we can get into is where we do discover that an
     alternative won't work out while we're still in a position of choosing
     another alternative, but in the process of making that discovery we emit
     constraints that linger on in a ghost-like state. Meanwhile, we pick another
     alternative, it works out, and we move on. Except that much later the ghost
     constraints become unsatisfied, leading to much confusion on the source of
     the resulting errors. This leads to a class of bugs where we get spurious
     errors even when a union or intersection type seems to have worked.

     So, we just implement roll-back, right? Basically...yes. But rolling back
     constraints is really hard in the current implementation. Instead, we try to
     avoid processing constraints that have side effects as much as possible while
     trying alternatives: by ensuring that the constraints that have side effects
     get deferred, instead of being processed immediately, until a choice can be
     made, thereby not participating in the choice-making process.

     But not all types can be fully resolved. In particular, while union and
     intersection types themselves can be fully resolved, the lower and upper
     bounds we check them against could have still-to-be-inferred types in
     them. How do we ensure that for the potentially side-effectful constraints we
     do emit on these types, we avoid undue side effects? By explicitly marking
     these types as unresolved, and deferring the execution of constraints that
     involved such marked types until a choice can be made. The details of this
     process is described in Speculation.
  *)

  (* Every choice-making process on a union or intersection type is assigned a
     unique identifier, called the speculation_id. This identifier keeps track of
     unresolved tvars encountered when trying to fully resolve types. *)
  let rec try_union cx trace use_op l reason rep =
    let ts = UnionRep.members rep in
    speculative_matches cx trace reason (UnionCases (use_op, l, rep, ts))

  and try_intersection cx trace u reason rep =
    let ts = InterRep.members rep in
    speculative_matches cx trace reason (IntersectionCases (ts, u))

  and try_singleton_throw_on_failure cx trace reason t u =
    speculative_matches cx trace reason (SingletonCase (t, u))

  (************************)
  (* Speculative matching *)
  (************************)

  (* Speculatively match a pair of types, returning whether some error was
     encountered or not. Speculative matching happens in the context of a
     particular "branch": this context controls how some constraints emitted
     during the matching might be processed. See comments in Speculation for
     details on branches. See also speculative_matches, which calls this function
     iteratively and processes its results. *)
  and speculative_match cx trace branch l u =
    let typeapp_stack = TypeAppExpansion.get cx in
    let constraint_cache_ref = Context.constraint_cache cx in
    let constraint_cache = !constraint_cache_ref in
    Speculation.set_speculative cx branch;
    let restore () =
      Speculation.restore_speculative cx;
      constraint_cache_ref := constraint_cache;
      TypeAppExpansion.set cx typeapp_stack
    in
    try
      rec_flow cx trace (l, u);
      restore ();
      None
    with
    | SpeculativeError err ->
      restore ();
      Some err
    | exn ->
      let exn = Exception.wrap exn in
      restore ();
      Exception.reraise exn

  (* Speculatively match several alternatives in turn, as presented when checking
     a union or intersection type. This process maintains a so-called "match
     state" that describes the best possible choice found so far, and can
     terminate in various ways:

     (1) One of the alternatives definitely succeeds. This is straightforward: we
     can safely discard any later alternatives.

     (2) All alternatives fail. This is also straightforward: we emit an
     appropriate error message.

     (3) One of the alternatives looks promising (i.e., it doesn't immediately
     fail, but it doesn't immediately succeed either: some potentially
     side-effectful constraints, called actions, were emitted while trying the
     alternative, whose execution has been deferred), and all the later
     alternatives fail. In this scenario, we pick the promising alternative, and
     then fire the deferred actions. This is fine, because the choice cannot cause
     regret: the chosen alternative was the only one that had any chance of
     succeeding.

     (4) Multiple alternatives look promising, but the set of deferred actions
     emitted while trying the first of those alternatives form a subset of those
     emitted by later trials. Here we pick the first promising alternative (and
     fire the deferred actions). The reason this is fine is similar to (3): once
     again, the choice cannot cause any regret, because if it failed, then the
     later alternatives would have failed too. So the chosen alternative had the
     best chance of succeeding.

     See Speculation for more details on terminology and low-level mechanisms used
     here, including what bits of information are carried by match_state and case.

     Because this process is common to checking union and intersection types, we
     abstract the latter into a so-called "spec." The spec is used to customize
     error messages.
  *)
  and speculative_matches cx trace r spec =
    (* explore optimization opportunities *)
    if optimize_spec_try_shortcut cx trace r spec then
      ()
    else
      long_path_speculative_matches cx trace r spec

  and long_path_speculative_matches cx trace r spec =
    let open Speculation_state in
    let speculation_id = mk_id () in
    (* extract stuff to ignore while considering actions *)
    (* split spec into a list of pairs of types to try speculative matching on *)
    let trials = trials_of_spec spec in
    (* Here match_state can take on various values:
     * (a) (NoMatch errs) indicates that everything has failed up to this point,
     *   with errors recorded in errs. Note that the initial value of acc is
     *   Some (NoMatch []).
     * (b) (ConditionalMatch case) indicates the a promising alternative has
     *    been found, but not chosen yet.
     *)
    let rec loop match_state = function
      | [] -> return match_state
      | (case_id, _, l, u) :: trials ->
        let case =
          {
            case_id;
            errors = [];
            implicit_instantiation_post_inference_checks = [];
            implicit_instantiation_results = ALocFuzzyMap.empty;
            lhs_t = l;
            use_t = u;
          }
        in
        (* speculatively match the pair of types in this trial *)
        let error = speculative_match cx trace { speculation_id; case } l u in
        (match error with
        | None -> begin
          (* no error, looking great so far... *)
          match match_state with
          | NoMatch _ -> fire_actions cx trace spec case speculation_id
          | ConditionalMatch _ -> loop match_state trials
        end
        | Some err -> begin
          (* if an error is found, then throw away this alternative... *)
          match match_state with
          | NoMatch errs ->
            (* ...adding to the error list if no promising alternative has been
             * found yet *)
            loop (NoMatch (err :: errs)) trials
          | _ -> loop match_state trials
        end)
    and return = function
      | ConditionalMatch case ->
        (* best choice that survived, congrats! fire deferred actions  *)
        fire_actions cx trace spec case speculation_id
      | NoMatch msgs ->
        (* everything failed; make a really detailed error message listing out the
         * error found for each alternative *)
        let ts = choices_of_spec spec in
        assert (List.length ts = List.length msgs);
        let branches =
          Base.List.mapi
            ~f:(fun i msg ->
              let reason = reason_of_t (List.nth ts i) in
              (reason, msg))
            msgs
        in
        (* Add the error. *)
        begin
          match spec with
          | UnionCases (use_op, l, _rep, us) ->
            let reason = reason_of_t l in
            add_output
              cx
              (Error_message.EUnionSpeculationFailed
                 { use_op; reason; op_reasons = (r, List.map reason_of_t us); branches }
              )
          | SingletonCase _ -> raise SpeculationSingletonError
          | IntersectionCases (ls, upper) ->
            let err =
              let reason_lower = mk_intersection_reason r ls in
              Default_resolve.default_resolve_touts
                ~flow:(flow_t cx)
                ~resolve_callee:(r, ls)
                cx
                (loc_of_reason reason_lower)
                upper;
              match upper with
              | UseT (use_op, t) ->
                Error_message.EIncompatibleDefs
                  { use_op; reason_lower; reason_upper = reason_of_t t; branches }
              | _ ->
                Error_message.EIncompatible
                  {
                    use_op = use_op_of_use_t upper;
                    lower = (reason_lower, Some Error_message.Incompatible_intersection);
                    upper = (reason_of_use_t upper, error_message_kind_of_upper upper);
                    branches;
                  }
            in
            add_output cx err
        end
    in
    loop (NoMatch []) trials

  and trials_of_spec = function
    | UnionCases (use_op, l, _rep, us) ->
      (* NB: Even though we know the use_op for the original constraint, don't
         embed it in the nested constraints to avoid unnecessary verbosity. We
         will unwrap the original use_op once in EUnionSpeculationFailed. *)
      Base.List.mapi ~f:(fun i u -> (i, reason_of_t l, l, UseT (Op (Speculation use_op), u))) us
    | IntersectionCases (ls, u) ->
      Base.List.mapi
        ~f:(fun i l ->
          (i, reason_of_use_t u, l, mod_use_op_of_use_t (fun use_op -> Op (Speculation use_op)) u))
        ls
    | SingletonCase (l, u) ->
      [(0, reason_of_use_t u, l, mod_use_op_of_use_t (fun use_op -> Op (Speculation use_op)) u)]

  and choices_of_spec = function
    | UnionCases (_, _, _, ts)
    | IntersectionCases (ts, _) ->
      ts
    | SingletonCase (t, _) -> [t]

  (* spec optimization *)
  (* Currently, the only optimizations we do are for enums and for disjoint unions.

     When a literal type is checked against a union of literal types, we hope the union is an enum and
     try to optimize the representation of the union as such. We also try to use our optimization to
     do a quick membership check, potentially avoiding the speculative matching process altogether.

     When an object type is checked against an union of object types, we hope the union is a disjoint
     union and try to guess and record sentinel properties across object types in the union. Later,
     during speculative matching, by checking sentinel properties first we force immediate match
     failures in the vast majority of cases without having to do any useless additional work.
  *)
  and optimize_spec_try_shortcut cx trace reason_op = function
    | UnionCases (_use_op, InternalT (EnforceUnionOptimized reason), rep, _ts) ->
      let specialization =
        UnionRep.optimize_
          rep
          ~reason_of_t:TypeUtil.reason_of_t
          ~reasonless_eq:(Concrete_type_eq.eq cx)
          ~flatten:(Type_mapper.union_flatten cx)
          ~find_resolved:(Context.find_resolved cx)
          ~find_props:(Context.find_props cx)
      in
      begin
        match specialization with
        | Error kind ->
          add_output cx (Error_message.EUnionOptimization { loc = loc_of_reason reason; kind })
        | Ok
            ( UnionRep.AlmostDisjointUnionWithPossiblyNonUniqueKeys map
            | UnionRep.PartiallyOptimizedAlmostDisjointUnionWithPossiblyNonUniqueKeys map ) ->
          let non_unique_keys =
            map
            |> NameUtils.Map.map (fun map ->
                   map
                   |> UnionRep.UnionEnumMap.filter (fun _ (_, ts) -> ts <> [])
                   |> UnionRep.UnionEnumMap.map (Nel.map TypeUtil.reason_of_t)
               )
            |> NameUtils.Map.filter (fun _ map -> not (UnionRep.UnionEnumMap.is_empty map))
          in
          if not (NameUtils.Map.is_empty non_unique_keys) then
            add_output
              cx
              (Error_message.EUnionPartialOptimizationNonUniqueKey
                 { loc = loc_of_reason reason; non_unique_keys }
              )
        | Ok _ -> ()
      end;
      true
    | UnionCases (use_op, l, rep, _ts) ->
      if not (UnionRep.is_optimized_finally rep) then
        UnionRep.optimize
          rep
          ~reason_of_t:TypeUtil.reason_of_t
          ~reasonless_eq:(Concrete_type_eq.eq cx)
          ~flatten:(Type_mapper.union_flatten cx)
          ~find_resolved:(Context.find_resolved cx)
          ~find_props:(Context.find_props cx);
      begin
        match l with
        | DefT
            ( _,
              ( StrT (Literal _)
              | NumT (Literal _)
              | BoolT (Some _)
              | SingletonStrT _ | SingletonNumT _ | SingletonBoolT _ | SingletonBigIntT _
              | BigIntT (Literal _)
              | VoidT | NullT )
            ) ->
          shortcut_enum cx trace reason_op use_op l rep
        (* Types that are definitely incompatible with enums, after the above case. *)
        | DefT
            ( _,
              ( NumT _ | BigIntT _ | StrT _ | MixedT _ | SymbolT | FunT _ | ObjT _ | ArrT _
              | ClassT _ | InstanceT _ | TypeT _ | PolyT _ | ReactAbstractComponentT _
              | EnumValueT _ | EnumObjectT _ )
            )
          when Base.Option.is_some (UnionRep.check_enum rep) ->
          add_output
            cx
            (Error_message.EIncompatibleWithUseOp
               { reason_lower = TypeUtil.reason_of_t l; reason_upper = reason_op; use_op }
            );
          true
        | DefT (_, ObjT _)
        | ExactT (_, DefT (_, ObjT _)) ->
          shortcut_disjoint_union cx trace reason_op use_op l rep
        | _ -> false
      end
    | IntersectionCases _ -> false
    | SingletonCase _ -> false

  and shortcut_enum cx trace reason_op use_op l rep =
    let quick_subtype = TypeUtil.quick_subtype in
    quick_mem_result cx trace reason_op use_op l @@ UnionRep.quick_mem_enum ~quick_subtype l rep

  and shortcut_disjoint_union cx trace reason_op use_op l rep =
    let quick_subtype = TypeUtil.quick_subtype in
    quick_mem_result cx trace reason_op use_op l
    @@ UnionRep.quick_mem_disjoint_union
         ~quick_subtype
         l
         rep
         ~find_resolved:(Context.find_resolved cx)
         ~find_props:(Context.find_props cx)

  and quick_mem_result cx trace reason_op use_op l = function
    | UnionRep.Yes ->
      (* membership check succeeded *)
      true
    (* Our work here is done, so no need to continue. *)
    | UnionRep.No ->
      (* membership check failed *)
      rec_flow cx trace (l, UseT (use_op, DefT (reason_op, EmptyT)));
      true
    (* Our work here is done, so no need to continue. *)
    | UnionRep.Conditional t ->
      (* conditional match *)
      rec_flow cx trace (l, UseT (use_op, t));
      true (* Our work here is done, so no need to continue. *)
    | UnionRep.Unknown ->
      (* membership check was inconclusive *)
      false

  and fire_actions cx trace spec case speculation_id =
    log_synthesis_result cx trace case speculation_id;
    log_specialized_callee cx spec case speculation_id;
    List.iter (add_output cx) case.Speculation_state.errors
end
