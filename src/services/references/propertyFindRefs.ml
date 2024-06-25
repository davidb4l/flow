(*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *)

module Ast = Flow_ast
open Loc_collections
open GetDefUtils
open Get_def_types

let ( >>= ) = Base.Result.( >>= )

let ( >>| ) = Base.Result.( >>| )

let add_ref_kind kind = Base.List.map ~f:(fun loc -> (kind, loc))

module LiteralToPropLoc : sig
  (* Returns a map from object_literal_loc to prop_loc, for all object literals which contain the
   * given property name. *)
  val make : (Loc.t, Loc.t) Ast.Program.t -> prop_name:string -> Loc.t LocMap.t
end = struct
  class locmap_builder prop_name =
    object (this)
      inherit [Loc.t LocMap.t] Object_key_visitor.visitor ~init:LocMap.empty

      method! private visit_object_key
          (literal_loc : Loc.t) (key : (Loc.t, Loc.t) Ast.Expression.Object.Property.key) =
        let open Ast.Expression.Object in
        match key with
        | Property.Identifier (prop_loc, { Ast.Identifier.name; comments = _ })
          when name = prop_name ->
          this#update_acc (fun map -> LocMap.add literal_loc prop_loc map)
        (* TODO consider supporting other property keys (e.g. literals). Also update the
         * optimization in property_access_searcher below when this happens. *)
        | _ -> ()
    end

  let make ast ~prop_name =
    let builder = new locmap_builder prop_name in
    builder#eval builder#program ast
end

let annot_of_jsx_name =
  let open Flow_ast.JSX in
  function
  | Identifier (annot, _)
  | NamespacedName (_, NamespacedName.{ name = (annot, _); _ })
  | MemberExpression (_, MemberExpression.{ property = (annot, _); _ }) ->
    annot

module Potential_ordinary_refs_search = struct
  exception Found_import of ALoc.t

  class searcher cx ~(target_name : string) ~(potential_refs : Type.t ALocMap.t ref) =
    object (_this)
      inherit
        [ALoc.t, ALoc.t * Type.t, ALoc.t, ALoc.t * Type.t] Flow_polymorphic_ast_mapper.mapper as super

      method on_loc_annot x = x

      method on_type_annot x = x

      method! import_declaration loc decl =
        let open Flow_ast.Statement.ImportDeclaration in
        try super#import_declaration loc decl with
        | Found_import name_loc ->
          let { source = ((_, module_t), _); _ } = decl in
          (* Replace previous bindings of `loc`. We should always use the result of the last call to
             the hook for a given location (this may no longer be relevant with the removal of
             generate-tests) *)
          potential_refs := ALocMap.add name_loc module_t !potential_refs;
          decl

      method! import_named_specifier ~import_kind:_ specifier =
        let open Flow_ast.Statement.ImportDeclaration in
        let { kind = _; local; remote; remote_name_def_loc = _ } = specifier in
        let ((name_loc, _), { Flow_ast.Identifier.name; _ }) =
          Base.Option.value ~default:remote local
        in
        if name = target_name then
          raise (Found_import name_loc)
        else
          specifier

      method! member loc expr =
        let open Flow_ast.Expression.Member in
        let { _object = ((_, ty), _); property; comments = _ } = expr in
        (match property with
        | PropertyIdentifier ((loc, _), { Flow_ast.Identifier.name; _ }) when name = target_name ->
          potential_refs := ALocMap.add loc ty !potential_refs
        | PropertyPrivateName _
        | PropertyIdentifier _
        | PropertyExpression _ ->
          ());
        super#member loc expr

      method! jsx_opening_element elt =
        let open Flow_ast.JSX in
        let (_, Opening.{ name = component_name; attributes; _ }) = elt in
        List.iter
          (function
            | Opening.Attribute
                ( _,
                  {
                    Attribute.name =
                      Attribute.Identifier
                        ((loc, _), { Identifier.name = attribute_name; comments = _ });
                    _;
                  }
                )
              when attribute_name = target_name ->
              let (_, component_t) = annot_of_jsx_name component_name in
              let reason = Reason.mk_reason Reason.RReactProps loc in
              let props_object =
                Tvar.mk_where cx reason (fun tvar ->
                    let use_op = Type.Op Type.UnknownUse in
                    Flow_js.flow
                      cx
                      (component_t, Type.ReactKitT (use_op, reason, Type.React.GetConfig tvar))
                )
              in
              potential_refs := ALocMap.add loc props_object !potential_refs
            | _ -> ())
          attributes;
        super#jsx_opening_element elt

      method! pattern ?kind expr =
        let ((_, ty), patt) = expr in
        let _ =
          match patt with
          | Ast.Pattern.Object { Ast.Pattern.Object.properties; _ } ->
            List.iter
              (fun prop ->
                let open Ast.Pattern.Object in
                match prop with
                | Property (_, { Property.key; _ }) ->
                  (match key with
                  | Property.Identifier ((loc, _), { Ast.Identifier.name; _ })
                  | Property.StringLiteral (loc, { Ast.StringLiteral.value = name; _ }) ->
                    if name = target_name then potential_refs := ALocMap.add loc ty !potential_refs;
                    ()
                  | Property.Computed _
                  | Property.NumberLiteral _
                  | Property.BigIntLiteral _ ->
                    ())
                | RestElement _ -> ())
              properties
          | Ast.Pattern.Identifier { Ast.Pattern.Identifier.name; _ } ->
            let ((loc, ty), { Flow_ast.Identifier.name = id_name; _ }) = name in
            (* If the location is already in the map, it was set by a parent *)
            if id_name = target_name && (not @@ ALocMap.mem loc !potential_refs) then
              potential_refs := ALocMap.add loc ty !potential_refs;
            ()
          | Ast.Pattern.Array _
          | Ast.Pattern.Expression _ ->
            ()
        in
        super#pattern ?kind expr
    end

  let search cx ~target_name ~potential_refs ast =
    let s = new searcher cx ~target_name ~potential_refs in
    let _ = s#program ast in
    ()
end

(* Returns `true` iff the given type is a reference to the symbol we are interested in *)
let type_matches_locs ~loc_of_aloc cx ty prop_def_info name =
  let rec def_loc_matches_locs = function
    | FoundClass ty_def_locs ->
      prop_def_info
      |> Nel.exists (function
             | ObjectProperty _ -> false
             | ClassProperty loc ->
               (* Only take the first extracted def loc -- that is, the one for the actual definition
                * and not overridden implementations, and compare it to the list of def locs we are
                * interested in *)
               loc = Nel.hd ty_def_locs
             )
    | FoundObject loc ->
      prop_def_info
      |> Nel.exists (function
             | ClassProperty _ -> false
             | ObjectProperty def_loc -> loc = def_loc
             )
    | FoundUnion def_locs -> def_locs |> Nel.map def_loc_matches_locs |> Nel.fold_left ( || ) false
    (* TODO we may want to surface AnyType results somehow since we can't be sure whether they
     * are references or not. For now we'll leave them out. *)
    | NoDefFound
    | UnsupportedType
    | AnyType ->
      false
  in
  extract_def_loc ~loc_of_aloc cx ty name >>| def_loc_matches_locs

let get_loc_of_def_info ~cx ~loc_of_aloc ~obj_to_obj_map prop_def_info =
  let prop_obj_locs =
    Nel.fold_left
      (fun acc def_info ->
        match def_info with
        | ClassProperty _ -> acc
        | ObjectProperty def_loc -> Loc_collections.LocSet.add def_loc acc)
      Loc_collections.LocSet.empty
      prop_def_info
  in
  (* Iterates all the map prop values. If any match prop_def_info, add the obj loc to the result *)
  Loc_collections.LocMap.fold
    (fun loc props_tmap_set result ->
      Type.Properties.Set.fold
        (fun props_id result' ->
          let props = Context.find_props cx props_id in
          NameUtils.Map.fold
            (fun _name prop result'' ->
              match Type.Property.read_loc prop with
              | Some aloc when Loc_collections.LocSet.mem (loc_of_aloc aloc) prop_obj_locs ->
                loc :: result''
              | _ -> result'')
            props
            result')
        props_tmap_set
        result)
    obj_to_obj_map
    []

let process_prop_refs ~loc_of_aloc cx potential_refs file_key prop_def_info name =
  potential_refs
  |> ALocMap.bindings
  |> Base.List.map ~f:(fun (ref_loc, ty) ->
         type_matches_locs ~loc_of_aloc cx ty prop_def_info name >>| function
         | true -> Some (loc_of_aloc ref_loc)
         | false -> None
     )
  |> Base.Result.all
  |> Base.Result.map_error ~f:(fun err ->
         Printf.sprintf
           "Encountered while finding refs in `%s`: %s"
           (File_key.to_string file_key)
           err
     )
  >>| fun refs -> refs |> Base.List.filter_opt |> add_ref_kind FindRefsTypes.PropertyAccess

let ordinary_property_find_refs_in_file ~loc_of_aloc ast_info type_info file_key (props_info, name)
    =
  let potential_refs : Type.t ALocMap.t ref = ref ALocMap.empty in
  let (Types_js_types.Typecheck_artifacts { cx; typed_ast; obj_to_obj_map }) = type_info in
  let (ast, _file_sig, _info) = ast_info in
  let local_defs =
    Nel.to_list (all_locs_of_ordinary_property_def_info props_info)
    |> List.filter (fun loc -> loc.Loc.source = Some file_key)
    |> add_ref_kind FindRefsTypes.PropertyDefinition
  in
  Potential_ordinary_refs_search.search cx ~target_name:name ~potential_refs typed_ast;
  let literal_prop_refs_result =
    (* Lazy to avoid this computation if there are no potentially-relevant object literals to
     * examine *)
    let prop_loc_map = lazy (LiteralToPropLoc.make ast ~prop_name:name) in

    get_loc_of_def_info ~cx ~loc_of_aloc ~obj_to_obj_map props_info
    |> List.filter_map (fun obj_loc -> LocMap.find_opt obj_loc (Lazy.force prop_loc_map))
    |> add_ref_kind FindRefsTypes.PropertyDefinition
  in

  process_prop_refs ~loc_of_aloc cx !potential_refs file_key props_info name
  >>| ( @ ) local_defs
  >>| ( @ ) literal_prop_refs_result

let property_find_refs_in_file ~loc_of_aloc ast_info type_info file_key = function
  | OrdinaryProperty { props_info; name } ->
    ordinary_property_find_refs_in_file ~loc_of_aloc ast_info type_info file_key (props_info, name)
  | PrivateNameProperty { def_loc; references; name = _ } ->
    Ok
      ((FindRefsTypes.PropertyDefinition, def_loc)
      :: Base.List.map references ~f:(fun l -> (FindRefsTypes.PropertyAccess, l))
      )

let find_local_refs ~loc_of_aloc file_key ast_info type_info loc =
  match get_property_def_info ~loc_of_aloc type_info loc with
  | Error _ as err -> err
  | Ok None -> Ok None
  | Ok (Some props_info) ->
    property_find_refs_in_file ~loc_of_aloc ast_info type_info file_key props_info >>= fun refs ->
    Ok (Some refs)
