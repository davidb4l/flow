(*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *)

module Prot = LspProt

module Client_config = struct
  type rank_autoimports_by_usage =
    [ `Default
    | `True
    | `False
    ]

  type t = {
    rank_autoimports_by_usage: rank_autoimports_by_usage;
    suggest_autoimports: bool;
    show_suggest_ranking_info: bool;
  }

  let rank_autoimports_by_usage { rank_autoimports_by_usage; _ } = rank_autoimports_by_usage

  let suggest_autoimports { suggest_autoimports; _ } = suggest_autoimports

  let show_suggest_ranking_info { show_suggest_ranking_info; _ } = show_suggest_ranking_info
end

type autocomplete_token = {
  ac_type: string;
  loc: int * int * File_key.t option;
}

type single_client = {
  client_id: Prot.client_id;
  lsp_initialize_params: Lsp.Initialize.params;
  mutable subscribed: bool;
  (* map from filename to content *)
  mutable opened_files: string SMap.t;
  type_parse_artifacts_cache:
    (Types_js_types.file_artifacts, Flow_error.ErrorSet.t) result FilenameCache.t;
  mutable client_config: Client_config.t;
  mutable outstanding_handlers: unit Lsp.lsp_handler Lsp.IdMap.t;
  mutable autocomplete_token: autocomplete_token option;
  mutable autocomplete_session_length: int;
  autocomplete_artifacts_cache:
    (Types_js_types.autocomplete_artifacts, Flow_error.ErrorSet.t) result FilenameCache.t;
}

type t = Prot.client_id list

let cache_max_size = 10

let remove_cache_entry ~autocomplete client filename =
  (* get_def, coverage, etc. all construct a File_key.SourceFile, which is then used as a key
     * here. *)
  let file_key = File_key.SourceFile filename in
  FilenameCache.remove_entry file_key client.type_parse_artifacts_cache;
  if autocomplete then FilenameCache.remove_entry file_key client.autocomplete_artifacts_cache

let active_clients : single_client IMap.t ref = ref IMap.empty

let get_client client_id = IMap.find_opt client_id !active_clients

let empty = []

let send_message_to_client (response : Prot.message_from_server) client =
  MonitorRPC.respond_to_persistent_connection ~client_id:client.client_id ~response

let send_response (response : Prot.response_with_metadata) client =
  send_message_to_client (Prot.RequestResponse response) client

let send_notification (response : Prot.notification_from_server) client =
  send_message_to_client (Prot.NotificationFromServer response) client

let send_errors =
  (* We don't know what kind of file the filename represents,
   * so we have to try (almost) all of them. *)
  let get_warnings_for_file =
    let rec get_first_contained warn_map = function
      | [] -> Flow_errors_utils.ConcreteLocPrintableErrorSet.empty
      | filename :: filenames ->
        (match Utils_js.FilenameMap.find_opt filename warn_map with
        | Some errs -> errs
        | None -> get_first_contained warn_map filenames)
    in
    fun filename warn_map ->
      get_first_contained
        warn_map
        [
          File_key.SourceFile filename;
          File_key.LibFile filename;
          File_key.JsonFile filename;
          File_key.ResourceFile filename;
        ]
  in
  fun ~vscode_detailed_diagnostics ~errors_reason ~errors ~warnings client ->
    let warnings =
      SMap.fold
        (fun filename _ warn_acc ->
          let file_warns = get_warnings_for_file filename warnings in
          Flow_errors_utils.ConcreteLocPrintableErrorSet.union file_warns warn_acc)
        client.opened_files
        Flow_errors_utils.ConcreteLocPrintableErrorSet.empty
    in
    let diagnostics =
      Flow_lsp_conversions.diagnostics_of_flow_errors ~vscode_detailed_diagnostics ~errors ~warnings
    in
    send_notification (Prot.Errors { diagnostics; errors_reason }) client

let send_errors_if_subscribed ~client ~vscode_detailed_diagnostics ~errors_reason ~errors ~warnings
    =
  if client.subscribed then
    send_errors ~vscode_detailed_diagnostics ~errors_reason ~errors ~warnings client

let send_single_lsp (message, metadata) client =
  send_response (Prot.LspFromServer message, metadata) client

let send_single_start_recheck client = send_notification Prot.StartRecheck client

let send_single_end_recheck ~lazy_stats client =
  send_notification (Prot.EndRecheck lazy_stats) client

let add_client client_id lsp_initialize_params =
  let new_client =
    {
      subscribed = false;
      opened_files = SMap.empty;
      client_id;
      lsp_initialize_params;
      type_parse_artifacts_cache = FilenameCache.make ~max_size:cache_max_size;
      client_config =
        {
          Client_config.suggest_autoimports = true;
          rank_autoimports_by_usage = `Default;
          show_suggest_ranking_info = false;
        };
      outstanding_handlers = Lsp.IdMap.empty;
      autocomplete_token = None;
      autocomplete_session_length = 0;
      autocomplete_artifacts_cache = FilenameCache.make ~max_size:cache_max_size;
    }
  in
  active_clients := IMap.add client_id new_client !active_clients;
  Hh_logger.info "Adding new persistent connection #%d" new_client.client_id

let remove_client client_id =
  Hh_logger.info "Removing persistent connection client #%d" client_id;
  active_clients := IMap.remove client_id !active_clients

let add_client_to_clients clients client_id = client_id :: clients

let remove_client_from_clients clients client_id = List.filter (fun id -> id != client_id) clients

let get_subscribed_clients =
  Base.List.fold
    ~f:(fun acc client_id ->
      match get_client client_id with
      | Some client when client.subscribed -> client :: acc
      | _ -> acc)
    ~init:[]

let update_clients ~clients ~vscode_detailed_diagnostics ~errors_reason ~calc_errors_and_warnings =
  let subscribed_clients = get_subscribed_clients clients in
  let subscribed_client_count = List.length subscribed_clients in
  let all_client_count = List.length clients in
  if subscribed_clients <> [] then (
    let (errors, warnings) = calc_errors_and_warnings () in
    let error_count = Flow_errors_utils.ConcreteLocPrintableErrorSet.cardinal errors in
    let warning_file_count = Utils_js.FilenameMap.cardinal warnings in
    Hh_logger.info
      "sending (%d errors) and (warnings from %d files) to %d subscribed clients (of %d total)"
      error_count
      warning_file_count
      subscribed_client_count
      all_client_count;
    List.iter
      (send_errors ~vscode_detailed_diagnostics ~errors_reason ~errors ~warnings)
      subscribed_clients
  )

let send_lsp clients json = clients |> get_subscribed_clients |> List.iter (send_single_lsp json)

let send_start_recheck clients =
  clients |> get_subscribed_clients |> List.iter send_single_start_recheck

let send_end_recheck ~lazy_stats clients =
  clients |> get_subscribed_clients |> List.iter (send_single_end_recheck ~lazy_stats)

let subscribe_client ~client ~vscode_detailed_diagnostics ~current_errors ~current_warnings =
  Hh_logger.info "Subscribing client #%d to push diagnostics" client.client_id;
  if client.subscribed then
    (* noop *)
    ()
  else
    let errors_reason = Prot.New_subscription in
    send_errors
      ~vscode_detailed_diagnostics
      ~errors_reason
      ~errors:current_errors
      ~warnings:current_warnings
      client;
    client.subscribed <- true

let client_did_open (client : single_client) ~(files : (string * string) Nel.t) : bool =
  (match Nel.length files with
  | 1 -> Hh_logger.info "Client #%d opened %s" client.client_id (files |> Nel.hd |> fst)
  | len -> Hh_logger.info "Client #%d opened %d files" client.client_id len);
  Nel.iter (fun (filename, _content) -> remove_cache_entry ~autocomplete:true client filename) files;
  let add_file acc (filename, content) = SMap.add filename content acc in
  let new_opened_files = Nel.fold_left add_file client.opened_files files in
  (* SMap.add ensures physical equality if the map is unchanged, since 4.0.3,
   * so == is appropriate. *)
  if new_opened_files == client.opened_files then
    (* noop *)
    false
  else (
    client.opened_files <- new_opened_files;
    true
  )

let client_did_change
    (client : single_client)
    (fn : string)
    (changes : Lsp.DidChange.textDocumentContentChangeEvent list) :
    (unit, string * Utils.callstack) result =
  remove_cache_entry ~autocomplete:false client fn;
  try
    let content = SMap.find fn client.opened_files in
    match Lsp_helpers.apply_changes content changes with
    | Error (reason, stack) -> Error (reason, stack)
    | Ok new_content ->
      let new_opened_files = SMap.add fn new_content client.opened_files in
      client.opened_files <- new_opened_files;
      Ok ()
  with
  | Not_found as e ->
    let e = Exception.wrap e in
    let stack = Exception.get_backtrace_string e in
    Error (Printf.sprintf "File %s wasn't open to change" fn, Utils.Callstack stack)

let client_did_close (client : single_client) ~(filenames : string Nel.t) : bool =
  (match Nel.length filenames with
  | 1 -> Hh_logger.info "Client #%d closed %s" client.client_id (filenames |> Nel.hd)
  | len -> Hh_logger.info "Client #%d closed %d files" client.client_id len);
  Nel.iter (remove_cache_entry ~autocomplete:true client) filenames;
  let remove_file acc filename = SMap.remove filename acc in
  let new_opened_files = Nel.fold_left remove_file client.opened_files filenames in
  (* SMap.remove ensures physical equality if the set is unchanged,
   * so == is appropriate. *)
  if new_opened_files == client.opened_files then
    (* noop *)
    false
  else (
    client.opened_files <- new_opened_files;
    true
  )

let client_did_change_configuration (client : single_client) (new_config : Client_config.t) : unit =
  Hh_logger.info "Client #%d changed configuration" client.client_id;
  let old_config = client.client_config in

  let old_suggest_autoimports = Client_config.suggest_autoimports old_config in
  let new_suggest_autoimports = Client_config.suggest_autoimports new_config in
  if new_suggest_autoimports <> old_suggest_autoimports then
    Hh_logger.info "  suggest_autoimports: %b -> %b" old_suggest_autoimports new_suggest_autoimports;

  let old_rank_autoimports_by_usage = Client_config.rank_autoimports_by_usage old_config in
  let new_rank_autoimports_by_usage = Client_config.rank_autoimports_by_usage new_config in
  ( if new_rank_autoimports_by_usage <> old_rank_autoimports_by_usage then
    let to_string = function
      | `Default -> "default"
      | `True -> "true"
      | `False -> "false"
    in
    Hh_logger.info
      "  rank_autoimports_by_usage: %s -> %s"
      (to_string old_rank_autoimports_by_usage)
      (to_string new_rank_autoimports_by_usage)
  );

  let old_show_suggest_ranking_info = Client_config.show_suggest_ranking_info old_config in
  let new_show_suggest_ranking_info = Client_config.show_suggest_ranking_info new_config in
  if new_show_suggest_ranking_info <> old_show_suggest_ranking_info then
    Hh_logger.info
      "  show_suggest_ranking_info: %b -> %b"
      old_show_suggest_ranking_info
      new_show_suggest_ranking_info;

  client.client_config <- new_config

let get_file (client : single_client) (fn : string) : File_input.t =
  let content_opt = SMap.find_opt fn client.opened_files in
  match content_opt with
  | None -> File_input.FileName fn
  | Some content -> File_input.FileContent (Some fn, content)

let get_id client = client.client_id

let lsp_initialize_params (client : single_client) = client.lsp_initialize_params

let client_config client = client.client_config

let type_parse_artifacts_cache client = client.type_parse_artifacts_cache

let autocomplete_artifacts_cache client = client.autocomplete_artifacts_cache

let clear_type_parse_artifacts_caches () =
  IMap.iter
    (fun _key client ->
      FilenameCache.clear client.type_parse_artifacts_cache;
      FilenameCache.clear client.autocomplete_artifacts_cache)
    !active_clients

let push_outstanding_handler client id handler =
  client.outstanding_handlers <- Lsp.IdMap.add id handler client.outstanding_handlers

let pop_outstanding_handler client id =
  match Lsp.IdMap.find_opt id client.outstanding_handlers with
  | Some handler ->
    client.outstanding_handlers <- Lsp.IdMap.remove id client.outstanding_handlers;
    Some handler
  | None -> None

(** Update the autocomplete session. Given the type of autocomplete (e.g.
    "Acid" when completing an identifier) and the start loc of the token,
    increments the session length for each consecutive completion request.
    Resets the session if the type or the token's start loc changes. *)
let autocomplete_session client ~ac_type loc =
  (match client.autocomplete_token with
  | Some { ac_type = prev_ac_type; loc = prev_loc } when ac_type = prev_ac_type && prev_loc = loc ->
    client.autocomplete_session_length <- client.autocomplete_session_length + 1
  | _ ->
    client.autocomplete_token <- Some { ac_type; loc };
    client.autocomplete_session_length <- 1);
  client.autocomplete_session_length
