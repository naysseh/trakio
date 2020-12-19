type input_type = 
  | Password
  | Username

type task_output = 
  | View
  | Print_All

type action =
  | Add
  | Edit
  | Remove
  | Display 

(** [string_of_action action] returns a string representation of the action
    type. *)
let string_of_action action =
  match action with 
  | Add -> "add to"
  | Edit -> "edit"
  | Remove -> "remove"
  | Display -> "display"

(******** Create User Verification Functions ********)
(** [validate_input input i_type] validates a given [input] based on its 
    [i_type] which is either a username or password. 
    Restrictions include: username must be between 4 and 20 chars, password no 
    smaller than 8 chars. Usernames cannot contain special characters, 
    but passwords can (except backslash). *)
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

(** [validate_print validation i_type] takes in an input [validation] and then 
    checks it as a valid input. If false, it matches it with its [i_type] 
    (user or password). It returns a bool t/f and prints a message. *)
let validate_print validation i_type = 
  let result = validate_input validation i_type in 
  match result with
  | false -> if i_type = Username then begin 
      ANSITerminal.(
        print_string [red] "\nYour username is invalid. Please be sure you adhere to the following:\n");
      print_endline 
        "No spaces or special characters, and be sure the length is between 4 and 20 characters.";
      false end 
    else begin 
      ANSITerminal.(
        print_string [red] "\nYour password is invalid. Please be sure you adhere to the following:\n");
      print_endline 
        "No spaces, no backslashes, and be sure that the length is greater than 8 characters."; 
      false end
  | true -> true

(** [new_pass user] takes in password for new account with name [user].
    Verifies their password using helper. If a user enters a username that 
    already exists, direct them to enter a new one w non-existing username. 
    Create new user. *)
let rec new_pass user = 
  ANSITerminal.(print_string [cyan] "\nPlease enter a password for the new account\n");
  print_string  "\n> ";
  let input = read_line () in 
  let validation = validate_print input Password in 
  if validation = false then new_pass user else 
    match input with 
    | exception End_of_file -> failwith "uh oh"
    | pass -> (user, pass)

(** [new_user username] validates an inputted username and presents the user
    with the options on their input. *)
let rec new_user username =
  ANSITerminal.(print_string [cyan] "\nPlease enter a username for the new account: no spaces or special characters.\n");
  print_string  "\n> ";
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
        new_user "restart"
(******** Create User Verification Functions ********)


(********Action Helpers********)
(** [tasks_rec tasks type_T] prints out a formatted view of tasks. If type_t is
    View, then it includes the assignee name.  *)
let rec tasks_print_rec (tasks : Types.task list) (type_t : task_output) = 
  match tasks with 
  | [] -> ()
  | h :: t -> begin 
      if type_t = View then 
        print_string (h.assignee ^ " - " )
      else print_string "";
      print_endline (h.title ^ ": " ^ h.status ^ " --> " ^
                     h.description ^ " (id: " ^ string_of_int h.id ^")");
      tasks_print_rec t type_t
    end 

(** [team_lists_string team_l] takes in a list of teams and prints them 
    separated by commas. *)
let rec team_lists_string (team_l : Types.team list) = 
  match team_l with 
  | [] -> ""
  | h :: t -> "• " ^ String.concat ", " 
                (Types.Team.to_string_list h) ^  "\n" ^ (team_lists_string t)

(** [team_select user] is a helper for [add_tasks_input] to display the teams
    that a manager is a part of in order for the manager to determine which 
    team they will be editing tasks for. *)
let rec team_select (user : User.user) (action : action) = 
  let action_string = string_of_action action in 
  ANSITerminal.(print_string [cyan] ("\nPlease enter the name of the team from the list below that you would like to " ^ action_string ^ "."));    
  ANSITerminal.(print_string [cyan] "\nThe name is the first element of the list shown.\n");    
  ANSITerminal.(print_string [green] "\nTEAMS: \n");
  print_endline (team_lists_string user.teams);
  print_string "> ";
  try User.get_team (read_line ()) with Database.NotFound team_name -> (
      ANSITerminal.(
        print_string [red] 
          "Team name entered does not exist. Please enter a valid teamname.\n");
      team_select user action)

(** [format_task task] formats the task into a readable format with obvious
    fields. *)
let format_task (task : Types.task) = 
  print_endline 
    ("Assignee: " ^ task.assignee ^ "\nTitle: " ^ task.title ^
     "\nStatus: " ^ task.status ^ "\nDescription: " ^ task.description); ()
(********Action Helpers********)

(********Manager Add********)
(** [manager_add_user user] takes in a user with the role of manager and allows
    them to create a new member of their team, with a password to log in. *) 
let manager_add_member user = 
  let team = team_select user Add in 
  let (new_user, new_pass) = new_user "new" in 
  ANSITerminal.(print_string [green] ("\nYou are adding: "));
  print_string (new_user);
  ANSITerminal.(print_string [green] (" to team "));
  print_string (team.teamname);
  ANSITerminal.(print_string [green] (" with password: "));
  print_string (new_pass);
  ANSITerminal.(print_string [cyan] ("\nIs this correct? Enter 1 to confirm, or 0 to re-enter. \n"));
  print_string ("\n> ");
  ()

(** [print_input user] is a helper for add_tasks_input that simply asks 
    the user for input and prints out a string representation of the users 
    desired input on tasks. Returns the team, assignee, title, status, 
    and description inputted by the user. *)
let print_task_input user = 
  let team = team_select user Add in
  ANSITerminal.(print_string [cyan] ("\nPlease enter the name of the user you would like to add a task to:\n"));
  print_string  "\n> ";
  let assignee = read_line () in 
  ANSITerminal.(print_string [cyan] ("\nPlease enter the title of the task:\n"));
  print_string  "\n> ";
  let title = read_line () in 
  ANSITerminal.(print_string [cyan] ("\nPlease enter the status of the task:\n"));
  print_string  "\n> ";
  let status = read_line () in 
  ANSITerminal.(print_string [cyan] ("\nPlease enter the description of the task:\n"));
  print_string  "\n> ";
  let description = read_line () in 
  print_newline ();
  ANSITerminal.(print_string [magenta] ("Is this correct? Enter 1 to confirm, or 0 to re-enter. \n"));
  print_newline ();
  ANSITerminal.(print_string [green] ("Team name: " ^ team.teamname));
  print_newline ();
  print_endline ("Assignee: " ^ assignee ^ "\n" ^ "Title: " ^ title ^ "\n" ^
                 "Status: " ^ status ^ "\n" ^ "Description: " ^ description ^ "\n");
  print_string "> ";
  (team, assignee, title, status, description)

(** [add_tasks_input user] is the function that takes in input from the user
    on the task they would like to add.  *)
let rec add_tasks_input user = 
  let (team, assignee, title, status, description) = print_task_input user in 
  let rec entry input = 
    match read_line () with 
    | "1" -> ( 
        match 
          User.manager_task_write assignee [title; status; description] 
            team user.tasks with 
        | t_list -> (print_endline "Success. :]"; Stdlib.exit 0)
        | exception User.User_Not_In_Team assignee -> begin 
            ANSITerminal.(
              print_string [red] 
                "\nThis user was not in the team listed. Please reenter.");
            add_tasks_input user end )
    | "0" -> add_tasks_input user
    | _ -> (ANSITerminal.(
        print_string [red] 
          "Not a valid input. Please enter either 1 or 0.");
       entry user) 
  in entry user

(** [manager_add_option user] takes in a user that has the role of a manager 
    and displays their options under the action "add." *) 
let rec manager_add_option user = 
  ANSITerminal.(print_string [cyan] ("\nAs a manager, you may add tasks or new members to your team.\n"));
  ANSITerminal.(print_string [cyan] ("Please enter what you would like to add:\n"));
  ANSITerminal.(print_string [green] "Task | Member");
  print_string ("\n\n> ");
  match String.lowercase_ascii (read_line ()) with 
  | "task" -> add_tasks_input user 
  | "member" -> manager_add_member user
  | _ -> (ANSITerminal.(
      print_string [red] 
        "\nInvalid input. Please enter either \"Task\" or \"Member\"");
     manager_add_option user)
(********Manager Add********)

(********Manager Edit********)
(** [edit_field id tasks] takes in an id number and list of tasks and 
    asks the user which field they would like to input from the task 
    specified. *)
let rec edit_field id tasks = 
  ANSITerminal.(print_string [cyan] "Which field would you like to edit? Enter from:");
  ANSITerminal.(print_string [green] "Assignee | Title | Status | Description\n\n");
  let task = User.get_task_by_id tasks id in 
  format_task task;
  print_string "\n> ";
  let rec entry id = 
    match String.lowercase_ascii (read_line ()) with 
    | "assignee" -> "assignee"
    | "title" -> "title"
    | "status" -> "status"
    | "description" -> "description"
    | _ -> (
        ANSITerminal.(print_string [red] "Invalid input. Please enter either:");
        ANSITerminal.(print_string [yellow] "Assignee | Title | Status | Description\n");
        entry id)
  in entry id

(** [field_entry user] validates the id entry for the user, making sure it 
    is an int. *)
let rec id_entry user = 
  let id = read_line () in 
  if Str.string_match (Str.regexp "^[0-9]+$") id 0 
  then int_of_string id else  
    (ANSITerminal.(print_string [red] "Please enter a valid id number. (Integer input only)");
     print_string "> ";
     id_entry user)

(** [manager_edit user] takes in a user with role manager and asks for input 
    on where they would like to edit a task.  *)
let rec manager_edit user = 
  let team = team_select user Edit in
  ANSITerminal.(print_string [cyan] "\nPlease select the id number of the task you would like to edit.\n");
  let tasks_list = User.get_team_tasks team  in
  tasks_print_rec (tasks_list) View;
  print_string "> ";
  let id = id_entry user in  
  let field = edit_field id tasks_list in 
  ANSITerminal.(print_string [cyan] ("\nWhat would you like " ^ field ^ " to be updated to?\n"));
  print_string "\n> ";
  let value = read_line () in 
  match User.manager_task_edit id field value tasks_list with 
  | t_list -> (print_endline "Success."; Stdlib.exit 0)
  | exception User.Database_Fatal_Error "Database error" -> 
    (print_endline "A problem occured in the database. Please retry";
     manager_edit user)
(********Manager Edit********)

(********Manager Remove********)
(** [remove_helper user] is a helper for manager_remove that asks for and takes
    in user inputs for the task they wish to delete. *) 
let remove_helper user = 
  let team = team_select user Edit in 
  ANSITerminal.(print_string [cyan] ("\nPlease select the id number of the task you would like to remove.\n"));
  let tasks_list = User.get_team_tasks team in 
  tasks_print_rec (tasks_list) View;
  print_string "\n> ";
  let id = id_entry user in 
  ANSITerminal.(print_string [magenta] ("\nIs this the task you would like to delete?\n\n"));
  format_task (User.get_task_by_id tasks_list id);
  print_string ("\n");
  ANSITerminal.(print_string [magenta] ("Please enter 1 to confirm or 0 to restart.\n"));
  print_string("\n> ");
  (team, tasks_list, id)

(** [manager_remove user] takes in a user with manager role and asks for input
    on which task they would like to remove from the teams they are a part of.*)
let rec manager_remove user = 
  let (team, tasks_list, id) = remove_helper user in
  let rec entry user = 
    match read_line () with 
    | "1" -> (match User.manager_task_remove id tasks_list with 
        | t_list -> begin 
            print_endline "Task successfully removed. :)";
            Stdlib.exit 0 end 
        | exception User.Database_Fatal_Error s -> begin 
            ANSITerminal.(print_string [red] "An error occured in the database. Please restart.");
            manager_remove user
          end )
    | "0" -> manager_remove user
    | _ -> (
        ANSITerminal.(print_string [red] "Not a valid input. Please enter either 1 or 0.");
        entry user) 
  in entry user
(********Manager Remove********)

(********Scrummer/Engineer Actions********)
(** [show_team_tasks user] will display all the tasks for everyone in a team 
    for the given user. *)
let rec show_team_tasks user =
  let team = team_select user Display in 
  ANSITerminal.(print_string [green] "\nTEAM TASKS: \n");
  tasks_print_rec (User.get_team_tasks team) View  

(** [scrum_eng_actions user] asks the user with role Scrummer or Engineer if 
    they would like to view tasks from all users on their teams. *)
let rec scrum_eng_actions user role = 
  ANSITerminal.(print_string [cyan] ("\nAs a " ^ role ^ ", you can view the tasks on your team. What would you like to do?\n"));
  ANSITerminal.(print_string [green] "Press 1 to view your teams, or 0 to quit.\n");
  print_string ("\n> ");
  match read_line () with 
  | "1" -> show_team_tasks user
  | "0" -> Stdlib.exit 0
  | _ ->  (ANSITerminal.(print_string [red] "Not a valid input. Please enter either 1 or 0.");
           scrum_eng_actions user role)
(********Scrummer/Engineer Actions********)

(********Actions********)
(** [manager_actions user] takes in a User.user that has the role of manager 
    and displays them the possible actions they can take. *)
let rec manager_actions user = 
  ANSITerminal.(print_string [cyan] "\nAs a manager, you may add, delete, and edit tasks, as well as add members to your team.");
  ANSITerminal.(print_string [cyan] "\nWhat would you like to do? Please enter one of the following actions:\n");
  ANSITerminal.(print_string [green] "Add | Delete | Edit | Quit ");
  print_string("\n\n> ");
  match String.lowercase_ascii (read_line ()) with 
  | "add" -> manager_add_option user
  | "delete" -> manager_remove user
  | "edit" -> manager_edit user
  | "quit" -> Stdlib.exit 0
  | _ ->  (ANSITerminal.(
      print_string [red] 
        "Invalid input. Please enter either \"Add\", \"Delete\", \"Edit\", or \"Quit\"\n");
     manager_actions user)

(** [actions user] offers a user the actions that come with their role. *)
let rec actions (user : User.user) = 
  let role = user.role in
  match role with 
  | Manager -> manager_actions user
  | Engineer -> scrum_eng_actions user "engineer"
  | Scrummer -> scrum_eng_actions user "scrummer"
(********Actions********)

(********Login Verification ********)
(** [password_verify user pass] takes in a [user] and [pass] and verifies that 
    the inputted password matches the username in the login base. Prompts the 
    user to re-enter if the password does not match the username. *)
let rec password_verify user pass =
  ANSITerminal.(print_string [cyan] "\nPlease enter your password, or enter 0 to quit.");
  print_string "\n\n> ";
  match read_line () with 
  | exception End_of_file -> failwith "failed"
  | input_pass -> 
    if input_pass = pass then 
      begin 
        print_endline ("\n________________________________________________________________________________________________________");
        ANSITerminal.(print_string [magenta; Bold] ("\nWelcome, " ^ user ^ "!\n"));
        ANSITerminal.(print_string [green] "\nYOUR TASKS: \n");
        try User.create_session user with Database.NotFound user -> begin
            print_endline "User not in database/empty user.";
            {User.tasks=[]; User.teams=[]; User.role=Field.Engineer} end
      end 
    else if input_pass = "0" then Stdlib.exit 0
    else begin 
      ANSITerminal.(
        print_string [red] 
          "Your password does not match your inputted username. Please try again.\n");
      password_verify user pass
    end

(** [check_user user] akes in username, returns password if user exists. *)
let check_user user =
  match User.log_in user with 
  | password -> (true, password) 
  | exception Database.NotFound _ -> (false, user)

let rec start str = 
  ANSITerminal.(print_string [cyan] ("\nPlease enter your username, or 0 to quit.\n"));
  print_string  "\n> ";
  match read_line () with
  | exception End_of_file -> ()
  | "0" -> Stdlib.exit 0
  | username -> get_tasks username

(** [get_tasks user] takes in a string [user] and attempts to login. If 
    successful, will print a user's list of tasks, and direct them to their 
    actions. *)
and get_tasks user = 
  match check_user user with 
  | (true, password) -> begin 
      let user_type = password |> password_verify user in 
      tasks_print_rec user_type.tasks Print_All;
      actions user_type end 
  | (false, _) -> 
    (ANSITerminal.
       (print_string [red] "Your username does not exist. Please enter again or create a new user.");
     start user) 
(********Login Verification********)

let main () =
  ANSITerminal.(print_string [magenta] 

                  "──────────────────────────────┬─────────────────────────────────────────────────────────────┬───────────────────────────");
  ANSITerminal.(print_string [magenta]
                  "\n                              |");
  ANSITerminal.(print_string [yellow] "                    Welcome to ");
  ANSITerminal.(print_string [green; Bold] "TRAKIO");
  ANSITerminal.(print_string [magenta] "                        |\n");
  ANSITerminal.(print_string [magenta]
                  "                              └─────────────────────────────────────────────────────────────┘\n" );
  start "file start"

let () = main ()