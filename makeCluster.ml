open Cluster

module Make : MakeCluster = 
  functor (E : EntryType) -> 
  functor (S : Schema) -> struct

    module Entry = E
    module Sch = S
    type entry = Entry.t

    let filename = ref E.assoc_file

    let bind teamname = filename := (teamname ^ "_" ^ E.assoc_file)
    let unbind () = filename := E.assoc_file

    let verify line =
      Sch.deserialize line
      |> Entry.create_entry
      |> Entry.to_string_list
      |> Sch.serialize

    let rep_ok () = Sch.rep_ok ~aux:verify !filename

    let form_list (l : string list) : entry list =
      List.map Sch.deserialize l
      |> List.map Entry.create_entry

    let search criterion =
      let checker line =
        let entry = Entry.create_entry (Sch.deserialize line) in
        List.fold_left
          (fun b f -> criterion f && b) true (Entry.to_field_list entry)
      in match Sch.search !filename checker with
      | Some x -> form_list x
      | None -> raise Not_found

    (* TODO: Check data is valid *)
    let add data = Sch.add !filename (Sch.serialize data)

    let delete id =
      Sch.delete !filename id

    let update criterion field =
      let new_line_task upd line =
        let entry = Sch.deserialize line |> Entry.create_entry in
        let to_change = List.fold_left
            (fun b f -> criterion f && b) true (Entry.to_field_list entry) in
        (if to_change then Entry.update_field upd entry else entry)
        |> Entry.to_string_list
        |> Sch.serialize
      in Sch.update !filename (new_line_task field)
  end