type t =
  [
    | `ID of int
    | `User of string
    | `Title of string
    | `Status of string
    | `Description of string
    | `TeamName of string
    | `Managers of string list
    | `Engineers of string list
    | `Scrummers of string list
    | `Entry of t list
    | `Password of string
  ]

(** [equal a b] is the monomorphic equality of two field types. *)
val equal : t -> t -> bool