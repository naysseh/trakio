open MakeCluster

type input_type = 
  | Password
  | Username

(* if true, input is permitted - false, need to enter new input *)
(* input is the given data, i_type is the type of data - user,pass,etc. *)
(* username must be between 4 and 20 chars, password no smaller than 8 chars. 
   Usernames cannot contain special characters, but passwords can 
   (except backslash). *)
let validate_input input i_type = 
  let new_input = String.trim input in 
  let length = String.length new_input in 
  if i_type = Username && (length < 4 || length > 20) then false 
  else if i_type = Password && length < 8 then false 
  else if String.contains new_input ' ' then false 
  else if i_type = Username && 
          (Str.string_match (Str.regexp "^[a-zA-Z0-9]+$") 
             new_input 0) = false then false 
  else if i_type = Password && (String.contains new_input '\\') = true 
  then false 
  else true 
(* another regexp to exclude certain special chars: 
   "^[\\[\\$\\^\\.\\*\\+\\?]+$" *)

(* validate_print takes in an input ([validation]) and then checks it as a 
    valid input. if false, it matches it with its type (user or password).
    It returns a bool t/f and prints a message.  *)
let validate_print validation i_type = 
  let result = validate_input validation i_type in 
  match result with
  | false -> if i_type = Username then begin 
      print_endline "Your username is invalid. Please be sure you adhere to the following: 
  No spaces or special characters, and be sure the length is between 4 and 20 characters.";
      false end 
    else begin print_endline "Your password is invalid. Please be sure you adhere to the following: 
  No spaces, no backslashes, and be sure that the length is greater than 8 characters."; 
      false end
  | true -> true

(* if a user enters a username that already exists, direct them to enter a new 
   one w non-existing username, create new user when function is implemented. *)
let rec new_pass user = 
  print_endline "Please enter a password for your new account \n";
  print_string  "> ";
  let input = read_line () in 
  let validation = validate_print input Password in 
  if validation = false then new_pass user else 
    match input with 
    | exception End_of_file -> failwith "oops"
    | pass -> print_endline "create new user not implemented" 
(* print message to tell user to log in again using their new login *)

let rec new_user x =
  print_endline "Please enter a username for your new account, no spaces or 
  special characters. \n";
  print_string  "> ";
  let input = read_line () in 
  let validation = validate_print input Username in 
  if validation = false then new_user "restart" else 
    match input with 
    | exception End_of_file -> Stdlib.exit 0
    | user ->
      match User.log_in user with
      | exception Database.NotFound user -> new_pass user
      | string -> 
        print_endline "user already taken -- restart"; 
        new_user "not done"

(* takes in username, returns password if user exists, otherwise error msg *)
let check_user user =
  try User.log_in user with  
    Database.NotFound user -> "Your username does not exist. Please enter again
    or create a new user."

let rec password_verify user pass =
  print_endline "Please enter your password, or enter 0 to quit. \n";
  print_string  "> ";
  match read_line () with 
  | exception End_of_file -> failwith "uhh"
  | input_pass -> 
    if input_pass = pass then 
      begin 
        print_string ("\n");
        ANSITerminal.(print_string [green] "TASKS: ");
        print_string ("\n"); 
        (* if the user does not exist in the database, it will return 
           an empty user. *)
        try User.create_session user with Database.NotFound user -> begin
            print_endline "User not in database/empty user.";
            {User.tasks=[]; User.teams=[]; User.role=User.Engineer}
          end
      end 
    else if input_pass = "0" then Stdlib.exit 0
    else begin print_endline 
        "Your password does not match your inputted username. Please try again.\n";
      password_verify user pass
    end

(* let pp_string_list = Fmt.list Fmt.string 

   let string_list lst = Format.printf "%a" pp_string_list lst *)

let string_of_tasks (user : User.user) = 
  let rec tasks_rec (tasks : Types.task list) = 
    match tasks with 
    | [] -> ()
    | h :: t -> 
      begin 
        print_endline (h.title ^ ": " ^ h.status ^ " --> " ^
                       h.description ^ " (id: " ^ string_of_int h.id ^")");
        tasks_rec t 
      end in tasks_rec user.tasks

let rec team_lists_string (team_l : Types.team list) = 
  match team_l with 
  | [] -> ""
  | h :: t -> String.concat ", " (Types.Team.to_string_list h) 
              ^  "\n" ^ (team_lists_string t)


let rec team_select (user : User.user) = 
  print_endline "Please enter the name of the team from the list below that you would like to edit.\n";
  print_endline (team_lists_string user.teams);
  print_string "\n> ";
  let team_name = User.get_team (read_line ()) in
  try team_name with Database.NotFound team_name -> (
      print_endline "Team name entered does not exist. Please enter a valid teamname.";
      team_select user)

(* let rec add_tasks_input user = 
   let team = team_select user in
   print_endline "Please enter the name of the user you would like to add a task to:\n";
   print_string  "> ";
   let assignee = read_line () in 
   print_endline "Please enter the title of the task:\n";
   print_string  "> ";
   let title = read_line () in 
   print_endline "Please enter the status of the task:\n";
   print_string  "> ";
   let status = read_line () in 
   print_endline "Please enter the description of the task:\n";
   print_string  "> ";
   let description = read_line () in 
   print_endline "Please confirm that this is the task you would like to add. 
   Enter 1 to confirm, or 0 to re-enter. \n";
   print_endline ("Team name: " ^ team.teamname ^ "\n");
   print_endline ("Assignee: " ^ assignee ^ "\n" ^ "Title: " ^ title ^ "\n" ^
                 "Status: " ^ status ^ "\n" ^ "Description: " ^ description ^ "\n");
   print_string "> ";
   let rec entry input = 
    match read_line () with 
    | "1" -> ( 
        match User.manager_task_write assignee [title; status; description] team with 
        | () -> print_endline "Success"
        | exception User.User_Not_In_Team assignee -> begin 
            print_endline "This user was not in the team listed. Please reenter.";
            add_tasks_input user end
      )
    | "0" -> add_tasks_input user
    | _ -> (print_endline "Not a valid input. Please enter either 1 or 0.";
            entry user) 
   in entry user *)

let rec add_option user = 
  print_endline "Please enter what you would like to add:";
  print_endline "Task | Team \n";
  match String.lowercase_ascii (read_line ()) with 
  | "task" -> () 
  | "team" -> ()
  | _ -> (print_endline "Invalid input. Please enter either \"Task\" or \"Team\" ";
          add_option user)

let rec manager_actions user = 
  print_endline "What action would you like to do? Please enter one of the following:";
  print_endline "Add | Delete | Edit \n";
  match String.lowercase_ascii (read_line ()) with 
  | "add" -> add_option user
  | "delete" -> () 
  | "edit" -> ()
  | _ -> (print_endline "Invalid input. Please enter either \"Add\", \"Delete\", or \"Edit\""; 
          manager_actions user)


(* roles have diff actions *)
let rec actions (user : User.user) = 
  let role = user.role in
  match role with 
  | Manager -> manager_actions user
  | Engineer -> ()
  | Scrummer -> ()


let get_tasks user = 
  let user_type = check_user user |> password_verify user in 
  string_of_tasks user_type;
  print_newline () ;
  actions user_type 

(* let pp_cell fmt cell = Format.fprintf fmt "%s" cell *)

(* create array matrix with tasks, make a row with titles
   id, assignee, title, descr, status *)

let main () =
  ANSITerminal.(print_string [magenta] 
                  "─────────────────────────────┬──────────────────────────────────────���───────────┬───────────────────────────");
  ANSITerminal.(print_string [magenta]
                  "\n                              |");
  ANSITerminal.(print_string [yellow] "                    Welcome to ");
  ANSITerminal.(print_string [green] "TRAKIO");
  ANSITerminal.(print_string [magenta] "                        |\n");
  ANSITerminal.(print_string [magenta]
                  "                              └─────────────────────────────────────────────────────────────┘\n" );
  print_endline "Please enter your username, or the word \"create\" to create a new user.\n";
  print_string  "> ";
  match read_line () with
  | exception End_of_file -> ()
  | "create" -> new_user "create"
  | username -> get_tasks username

let () = main ()