(* OASIS_START *)
(* DO NOT EDIT (digest: 0c8d8e3d3d3f32d2cf322309bc1cc8f0) *)
module OASISGettext = struct
(* # 22 "src/oasis/OASISGettext.ml" *)


  let ns_ str =
    str


  let s_ str =
    str


  let f_ (str: ('a, 'b, 'c, 'd) format4) =
    str


  let fn_ fmt1 fmt2 n =
    if n = 1 then
      fmt1^^""
    else
      fmt2^^""


  let init =
    []


end

module OASISString = struct
(* # 22 "src/oasis/OASISString.ml" *)


  (** Various string utilities.

      Mostly inspired by extlib and batteries ExtString and BatString libraries.

      @author Sylvain Le Gall
    *)


  let nsplitf str f =
    if str = "" then
      []
    else
      let buf = Buffer.create 13 in
      let lst = ref [] in
      let push () =
        lst := Buffer.contents buf :: !lst;
        Buffer.clear buf
      in
      let str_len = String.length str in
        for i = 0 to str_len - 1 do
          if f str.[i] then
            push ()
          else
            Buffer.add_char buf str.[i]
        done;
        push ();
        List.rev !lst


  (** [nsplit c s] Split the string [s] at char [c]. It doesn't include the
      separator.
    *)
  let nsplit str c =
    nsplitf str ((=) c)


  let find ~what ?(offset=0) str =
    let what_idx = ref 0 in
    let str_idx = ref offset in
      while !str_idx < String.length str &&
            !what_idx < String.length what do
        if str.[!str_idx] = what.[!what_idx] then
          incr what_idx
        else
          what_idx := 0;
        incr str_idx
      done;
      if !what_idx <> String.length what then
        raise Not_found
      else
        !str_idx - !what_idx


  let sub_start str len =
    let str_len = String.length str in
    if len >= str_len then
      ""
    else
      String.sub str len (str_len - len)


  let sub_end ?(offset=0) str len =
    let str_len = String.length str in
    if len >= str_len then
      ""
    else
      String.sub str 0 (str_len - len)


  let starts_with ~what ?(offset=0) str =
    let what_idx = ref 0 in
    let str_idx = ref offset in
    let ok = ref true in
      while !ok &&
            !str_idx < String.length str &&
            !what_idx < String.length what do
        if str.[!str_idx] = what.[!what_idx] then
          incr what_idx
        else
          ok := false;
        incr str_idx
      done;
      if !what_idx = String.length what then
        true
      else
        false


  let strip_starts_with ~what str =
    if starts_with ~what str then
      sub_start str (String.length what)
    else
      raise Not_found


  let ends_with ~what ?(offset=0) str =
    let what_idx = ref ((String.length what) - 1) in
    let str_idx = ref ((String.length str) - 1) in
    let ok = ref true in
      while !ok &&
            offset <= !str_idx &&
            0 <= !what_idx do
        if str.[!str_idx] = what.[!what_idx] then
          decr what_idx
        else
          ok := false;
        decr str_idx
      done;
      if !what_idx = -1 then
        true
      else
        false


  let strip_ends_with ~what str =
    if ends_with ~what str then
      sub_end str (String.length what)
    else
      raise Not_found


  let replace_chars f s =
    let buf = Buffer.create (String.length s) in
    String.iter (fun c -> Buffer.add_char buf (f c)) s;
    Buffer.contents buf

  let lowercase_ascii =
    replace_chars
      (fun c ->
         if (c >= 'A' && c <= 'Z') then
           Char.chr (Char.code c + 32)
         else
           c)

  let uncapitalize_ascii s =
    if s <> "" then
      (lowercase_ascii (String.sub s 0 1)) ^ (String.sub s 1 ((String.length s) - 1))
    else
      s

  let uppercase_ascii =
    replace_chars
      (fun c ->
         if (c >= 'a' && c <= 'z') then
           Char.chr (Char.code c - 32)
         else
           c)

  let capitalize_ascii s =
    if s <> "" then
      (uppercase_ascii (String.sub s 0 1)) ^ (String.sub s 1 ((String.length s) - 1))
    else
      s

end

module OASISExpr = struct
(* # 22 "src/oasis/OASISExpr.ml" *)





  open OASISGettext


  type test = string


  type flag = string


  type t =
    | EBool of bool
    | ENot of t
    | EAnd of t * t
    | EOr of t * t
    | EFlag of flag
    | ETest of test * string



  type 'a choices = (t * 'a) list


  let eval var_get t =
    let rec eval' =
      function
        | EBool b ->
            b

        | ENot e ->
            not (eval' e)

        | EAnd (e1, e2) ->
            (eval' e1) && (eval' e2)

        | EOr (e1, e2) ->
            (eval' e1) || (eval' e2)

        | EFlag nm ->
            let v =
              var_get nm
            in
              assert(v = "true" || v = "false");
              (v = "true")

        | ETest (nm, vl) ->
            let v =
              var_get nm
            in
              (v = vl)
    in
      eval' t


  let choose ?printer ?name var_get lst =
    let rec choose_aux =
      function
        | (cond, vl) :: tl ->
            if eval var_get cond then
              vl
            else
              choose_aux tl
        | [] ->
            let str_lst =
              if lst = [] then
                s_ "<empty>"
              else
                String.concat
                  (s_ ", ")
                  (List.map
                     (fun (cond, vl) ->
                        match printer with
                          | Some p -> p vl
                          | None -> s_ "<no printer>")
                     lst)
            in
              match name with
                | Some nm ->
                    failwith
                      (Printf.sprintf
                         (f_ "No result for the choice list '%s': %s")
                         nm str_lst)
                | None ->
                    failwith
                      (Printf.sprintf
                         (f_ "No result for a choice list: %s")
                         str_lst)
    in
      choose_aux (List.rev lst)


end


# 292 "myocamlbuild.ml"
module BaseEnvLight = struct
(* # 22 "src/base/BaseEnvLight.ml" *)


  module MapString = Map.Make(String)


  type t = string MapString.t


  let default_filename =
    Filename.concat
      (Sys.getcwd ())
      "setup.data"


  let load ?(allow_empty=false) ?(filename=default_filename) () =
    if Sys.file_exists filename then
      begin
        let chn =
          open_in_bin filename
        in
        let st =
          Stream.of_channel chn
        in
        let line =
          ref 1
        in
        let st_line =
          Stream.from
            (fun _ ->
               try
                 match Stream.next st with
                   | '\n' -> incr line; Some '\n'
                   | c -> Some c
               with Stream.Failure -> None)
        in
        let lexer =
          Genlex.make_lexer ["="] st_line
        in
        let rec read_file mp =
          match Stream.npeek 3 lexer with
            | [Genlex.Ident nm; Genlex.Kwd "="; Genlex.String value] ->
                Stream.junk lexer;
                Stream.junk lexer;
                Stream.junk lexer;
                read_file (MapString.add nm value mp)
            | [] ->
                mp
            | _ ->
                failwith
                  (Printf.sprintf
                     "Malformed data file '%s' line %d"
                     filename !line)
        in
        let mp =
          read_file MapString.empty
        in
          close_in chn;
          mp
      end
    else if allow_empty then
      begin
        MapString.empty
      end
    else
      begin
        failwith
          (Printf.sprintf
             "Unable to load environment, the file '%s' doesn't exist."
             filename)
      end


  let rec var_expand str env =
    let buff =
      Buffer.create ((String.length str) * 2)
    in
      Buffer.add_substitute
        buff
        (fun var ->
           try
             var_expand (MapString.find var env) env
           with Not_found ->
             failwith
               (Printf.sprintf
                  "No variable %s defined when trying to expand %S."
                  var
                  str))
        str;
      Buffer.contents buff


  let var_get name env =
    var_expand (MapString.find name env) env


  let var_choose lst env =
    OASISExpr.choose
      (fun nm -> var_get nm env)
      lst
end


# 397 "myocamlbuild.ml"
module MyOCamlbuildFindlib = struct
(* # 22 "src/plugins/ocamlbuild/MyOCamlbuildFindlib.ml" *)


  (** OCamlbuild extension, copied from
    * http://brion.inria.fr/gallium/index.php/Using_ocamlfind_with_ocamlbuild
    * by N. Pouillard and others
    *
    * Updated on 2009/02/28
    *
    * Modified by Sylvain Le Gall
    *)
  open Ocamlbuild_plugin

  type conf =
    { no_automatic_syntax: bool;
    }

  (* these functions are not really officially exported *)
  let run_and_read =
    Ocamlbuild_pack.My_unix.run_and_read


  let blank_sep_strings =
    Ocamlbuild_pack.Lexers.blank_sep_strings


  let exec_from_conf exec =
    let exec =
      let env_filename = Pathname.basename BaseEnvLight.default_filename in
      let env = BaseEnvLight.load ~filename:env_filename ~allow_empty:true () in
      try
        BaseEnvLight.var_get exec env
      with Not_found ->
        Printf.eprintf "W: Cannot get variable %s\n" exec;
        exec
    in
    let fix_win32 str =
      if Sys.os_type = "Win32" then begin
        let buff = Buffer.create (String.length str) in
        (* Adapt for windowsi, ocamlbuild + win32 has a hard time to handle '\\'.
         *)
        String.iter
          (fun c -> Buffer.add_char buff (if c = '\\' then '/' else c))
          str;
        Buffer.contents buff
      end else begin
        str
      end
    in
      fix_win32 exec

  let split s ch =
    let buf = Buffer.create 13 in
    let x = ref [] in
    let flush () =
      x := (Buffer.contents buf) :: !x;
      Buffer.clear buf
    in
      String.iter
        (fun c ->
           if c = ch then
             flush ()
           else
             Buffer.add_char buf c)
        s;
      flush ();
      List.rev !x


  let split_nl s = split s '\n'


  let before_space s =
    try
      String.before s (String.index s ' ')
    with Not_found -> s

  (* ocamlfind command *)
  let ocamlfind x = S[Sh (exec_from_conf "ocamlfind"); x]

  (* This lists all supported packages. *)
  let find_packages () =
    List.map before_space (split_nl & run_and_read (exec_from_conf "ocamlfind" ^ " list"))


  (* Mock to list available syntaxes. *)
  let find_syntaxes () = ["camlp4o"; "camlp4r"]


  let well_known_syntax = [
    "camlp4.quotations.o";
    "camlp4.quotations.r";
    "camlp4.exceptiontracer";
    "camlp4.extend";
    "camlp4.foldgenerator";
    "camlp4.listcomprehension";
    "camlp4.locationstripper";
    "camlp4.macro";
    "camlp4.mapgenerator";
    "camlp4.metagenerator";
    "camlp4.profiler";
    "camlp4.tracer"
  ]


  let dispatch conf =
    function
      | After_options ->
          (* By using Before_options one let command line options have an higher
           * priority on the contrary using After_options will guarantee to have
           * the higher priority override default commands by ocamlfind ones *)
          Options.ocamlc     := ocamlfind & A"ocamlc";
          Options.ocamlopt   := ocamlfind & A"ocamlopt";
          Options.ocamldep   := ocamlfind & A"ocamldep";
          Options.ocamldoc   := ocamlfind & A"ocamldoc";
          Options.ocamlmktop := ocamlfind & A"ocamlmktop";
          Options.ocamlmklib := ocamlfind & A"ocamlmklib"

      | After_rules ->

          (* When one link an OCaml library/binary/package, one should use
           * -linkpkg *)
          flag ["ocaml"; "link"; "program"] & A"-linkpkg";

          if not (conf.no_automatic_syntax) then begin
            (* For each ocamlfind package one inject the -package option when
             * compiling, computing dependencies, generating documentation and
             * linking. *)
            List.iter
              begin fun pkg ->
                let base_args = [A"-package"; A pkg] in
                (* TODO: consider how to really choose camlp4o or camlp4r. *)
                let syn_args = [A"-syntax"; A "camlp4o"] in
                let (args, pargs) =
                  (* Heuristic to identify syntax extensions: whether they end in
                     ".syntax"; some might not.
                  *)
                  if Filename.check_suffix pkg "syntax" ||
                     List.mem pkg well_known_syntax then
                    (syn_args @ base_args, syn_args)
                  else
                    (base_args, [])
                in
                flag ["ocaml"; "compile";  "pkg_"^pkg] & S args;
                flag ["ocaml"; "ocamldep"; "pkg_"^pkg] & S args;
                flag ["ocaml"; "doc";      "pkg_"^pkg] & S args;
                flag ["ocaml"; "link";     "pkg_"^pkg] & S base_args;
                flag ["ocaml"; "infer_interface"; "pkg_"^pkg] & S args;

                (* TODO: Check if this is allowed for OCaml < 3.12.1 *)
                flag ["ocaml"; "compile";  "package("^pkg^")"] & S pargs;
                flag ["ocaml"; "ocamldep"; "package("^pkg^")"] & S pargs;
                flag ["ocaml"; "doc";      "package("^pkg^")"] & S pargs;
                flag ["ocaml"; "infer_interface"; "package("^pkg^")"] & S pargs;
              end
              (find_packages ());
          end;

          (* Like -package but for extensions syntax. Morover -syntax is useless
           * when linking. *)
          List.iter begin fun syntax ->
          flag ["ocaml"; "compile";  "syntax_"^syntax] & S[A"-syntax"; A syntax];
          flag ["ocaml"; "ocamldep"; "syntax_"^syntax] & S[A"-syntax"; A syntax];
          flag ["ocaml"; "doc";      "syntax_"^syntax] & S[A"-syntax"; A syntax];
          flag ["ocaml"; "infer_interface"; "syntax_"^syntax] &
                S[A"-syntax"; A syntax];
          end (find_syntaxes ());

          (* The default "thread" tag is not compatible with ocamlfind.
           * Indeed, the default rules add the "threads.cma" or "threads.cmxa"
           * options when using this tag. When using the "-linkpkg" option with
           * ocamlfind, this module will then be added twice on the command line.
           *
           * To solve this, one approach is to add the "-thread" option when using
           * the "threads" package using the previous plugin.
           *)
          flag ["ocaml"; "pkg_threads"; "compile"] (S[A "-thread"]);
          flag ["ocaml"; "pkg_threads"; "doc"] (S[A "-I"; A "+threads"]);
          flag ["ocaml"; "pkg_threads"; "link"] (S[A "-thread"]);
          flag ["ocaml"; "pkg_threads"; "infer_interface"] (S[A "-thread"]);
          flag ["ocaml"; "package(threads)"; "compile"] (S[A "-thread"]);
          flag ["ocaml"; "package(threads)"; "doc"] (S[A "-I"; A "+threads"]);
          flag ["ocaml"; "package(threads)"; "link"] (S[A "-thread"]);
          flag ["ocaml"; "package(threads)"; "infer_interface"] (S[A "-thread"]);

      | _ ->
          ()
end

module MyOCamlbuildBase = struct
(* # 22 "src/plugins/ocamlbuild/MyOCamlbuildBase.ml" *)


  (** Base functions for writing myocamlbuild.ml
      @author Sylvain Le Gall
    *)





  open Ocamlbuild_plugin
  module OC = Ocamlbuild_pack.Ocaml_compiler


  type dir = string
  type file = string
  type name = string
  type tag = string


(* # 62 "src/plugins/ocamlbuild/MyOCamlbuildBase.ml" *)


  type t =
      {
        lib_ocaml: (name * dir list * string list) list;
        lib_c:     (name * dir * file list) list;
        flags:     (tag list * (spec OASISExpr.choices)) list;
        (* Replace the 'dir: include' from _tags by a precise interdepends in
         * directory.
         *)
        includes:  (dir * dir list) list;
      }


  let env_filename =
    Pathname.basename
      BaseEnvLight.default_filename


  let dispatch_combine lst =
    fun e ->
      List.iter
        (fun dispatch -> dispatch e)
        lst


  let tag_libstubs nm =
    "use_lib"^nm^"_stubs"


  let nm_libstubs nm =
    nm^"_stubs"


  let dispatch t e =
    let env =
      BaseEnvLight.load
        ~filename:env_filename
        ~allow_empty:true
        ()
    in
      match e with
        | Before_options ->
            let no_trailing_dot s =
              if String.length s >= 1 && s.[0] = '.' then
                String.sub s 1 ((String.length s) - 1)
              else
                s
            in
              List.iter
                (fun (opt, var) ->
                   try
                     opt := no_trailing_dot (BaseEnvLight.var_get var env)
                   with Not_found ->
                     Printf.eprintf "W: Cannot get variable %s\n" var)
                [
                  Options.ext_obj, "ext_obj";
                  Options.ext_lib, "ext_lib";
                  Options.ext_dll, "ext_dll";
                ]

        | After_rules ->
            (* Declare OCaml libraries *)
            List.iter
              (function
                 | nm, [], intf_modules ->
                     ocaml_lib nm;
                     let cmis =
                       List.map (fun m -> (OASISString.uncapitalize_ascii m) ^ ".cmi")
                                intf_modules in
                     dep ["ocaml"; "link"; "library"; "file:"^nm^".cma"] cmis
                 | nm, dir :: tl, intf_modules ->
                     ocaml_lib ~dir:dir (dir^"/"^nm);
                     List.iter
                       (fun dir ->
                          List.iter
                            (fun str ->
                               flag ["ocaml"; "use_"^nm; str] (S[A"-I"; P dir]))
                            ["compile"; "infer_interface"; "doc"])
                       tl;
                     let cmis =
                       List.map (fun m -> dir^"/"^(OASISString.uncapitalize_ascii m)^".cmi")
                                intf_modules in
                     dep ["ocaml"; "link"; "library"; "file:"^dir^"/"^nm^".cma"]
                         cmis)
              t.lib_ocaml;

            (* Declare directories dependencies, replace "include" in _tags. *)
            List.iter
              (fun (dir, include_dirs) ->
                 Pathname.define_context dir include_dirs)
              t.includes;

            (* Declare C libraries *)
            List.iter
              (fun (lib, dir, headers) ->
                   (* Handle C part of library *)
                   flag ["link"; "library"; "ocaml"; "byte"; tag_libstubs lib]
                     (S[A"-dllib"; A("-l"^(nm_libstubs lib)); A"-cclib";
                        A("-l"^(nm_libstubs lib))]);

                   flag ["link"; "library"; "ocaml"; "native"; tag_libstubs lib]
                     (S[A"-cclib"; A("-l"^(nm_libstubs lib))]);

                   flag ["link"; "program"; "ocaml"; "byte"; tag_libstubs lib]
                     (S[A"-dllib"; A("dll"^(nm_libstubs lib))]);

                   (* When ocaml link something that use the C library, then one
                      need that file to be up to date.
                      This holds both for programs and for libraries.
                    *)
  		 dep ["link"; "ocaml"; tag_libstubs lib]
  		     [dir/"lib"^(nm_libstubs lib)^"."^(!Options.ext_lib)];

  		 dep  ["compile"; "ocaml"; tag_libstubs lib]
  		      [dir/"lib"^(nm_libstubs lib)^"."^(!Options.ext_lib)];

                   (* TODO: be more specific about what depends on headers *)
                   (* Depends on .h files *)
                   dep ["compile"; "c"]
                     headers;

                   (* Setup search path for lib *)
                   flag ["link"; "ocaml"; "use_"^lib]
                     (S[A"-I"; P(dir)]);
              )
              t.lib_c;

              (* Add flags *)
              List.iter
              (fun (tags, cond_specs) ->
                 let spec = BaseEnvLight.var_choose cond_specs env in
                 let rec eval_specs =
                   function
                     | S lst -> S (List.map eval_specs lst)
                     | A str -> A (BaseEnvLight.var_expand str env)
                     | spec -> spec
                 in
                   flag tags & (eval_specs spec))
              t.flags
        | _ ->
            ()


  let dispatch_default conf t =
    dispatch_combine
      [
        dispatch t;
        MyOCamlbuildFindlib.dispatch conf;
      ]


end


# 766 "myocamlbuild.ml"
open Ocamlbuild_plugin;;
let package_default =
  {
     MyOCamlbuildBase.lib_ocaml = [("sqlite3", ["lib"], [])];
     lib_c = [("sqlite3", "lib", [])];
     flags =
       [
          (["oasis_library_sqlite3_ccopt"; "compile"],
            [
               (OASISExpr.EBool true,
                 S
                   [
                      A "-ccopt";
                      A "-g";
                      A "-ccopt";
                      A "-O2";
                      A "-ccopt";
                      A "-fPIC";
                      A "-ccopt";
                      A "-DPIC"
                   ]);
               (OASISExpr.ENot (OASISExpr.EFlag "loadable_extensions"),
                 S
                   [
                      A "-ccopt";
                      A "-g";
                      A "-ccopt";
                      A "-O2";
                      A "-ccopt";
                      A "-fPIC";
                      A "-ccopt";
                      A "-DPIC";
                      A "-ccopt";
                      A "-DSQLITE3_DISABLE_LOADABLE_EXTENSIONS"
                   ]);
               (OASISExpr.EAnd
                  (OASISExpr.EFlag "strict",
                    OASISExpr.ETest ("ccomp_type", "cc")),
                 S
                   [
                      A "-ccopt";
                      A "-g";
                      A "-ccopt";
                      A "-O2";
                      A "-ccopt";
                      A "-fPIC";
                      A "-ccopt";
                      A "-DPIC";
                      A "-ccopt";
                      A "-Wall";
                      A "-ccopt";
                      A "-pedantic";
                      A "-ccopt";
                      A "-Wextra";
                      A "-ccopt";
                      A "-Wunused";
                      A "-ccopt";
                      A "-Wno-long-long";
                      A "-ccopt";
                      A "-Wno-keyword-macro"
                   ]);
               (OASISExpr.EAnd
                  (OASISExpr.EAnd
                     (OASISExpr.EFlag "strict",
                       OASISExpr.ETest ("ccomp_type", "cc")),
                    OASISExpr.ENot (OASISExpr.EFlag "loadable_extensions")),
                 S
                   [
                      A "-ccopt";
                      A "-g";
                      A "-ccopt";
                      A "-O2";
                      A "-ccopt";
                      A "-fPIC";
                      A "-ccopt";
                      A "-DPIC";
                      A "-ccopt";
                      A "-Wall";
                      A "-ccopt";
                      A "-pedantic";
                      A "-ccopt";
                      A "-Wextra";
                      A "-ccopt";
                      A "-Wunused";
                      A "-ccopt";
                      A "-Wno-long-long";
                      A "-ccopt";
                      A "-Wno-keyword-macro";
                      A "-ccopt";
                      A "-DSQLITE3_DISABLE_LOADABLE_EXTENSIONS"
                   ])
            ]);
          (["oasis_library_sqlite3_cclib"; "link"],
            [
               (OASISExpr.EBool true,
                 S [A "-cclib"; A "-lsqlite3"; A "-cclib"; A "-lpthread"])
            ]);
          (["oasis_library_sqlite3_cclib"; "ocamlmklib"; "c"],
            [(OASISExpr.EBool true, S [A "-lsqlite3"; A "-lpthread"])])
       ];
     includes = [("test", ["lib"])]
  }
  ;;

let conf = {MyOCamlbuildFindlib.no_automatic_syntax = false}

let dispatch_default = MyOCamlbuildBase.dispatch_default conf package_default;;

# 876 "myocamlbuild.ml"
(* OASIS_STOP *)

let read_lines_from_cmd ~max_lines cmd =
  let ic = Unix.open_process_in cmd in
  let lines_ref = ref [] in
  let rec loop n =
    if n <= 0 then ()
    else begin
      lines_ref := input_line ic :: !lines_ref;
      loop (n - 1)
    end
  in
  begin
    try loop max_lines with
    | End_of_file -> ()
    | exc -> close_in_noerr ic; raise exc
  end;
  close_in ic;
  List.rev !lines_ref

(* TODO: remove once split-function in generated code is fixed *)
let rec split_string s =
  match try Some (String.index s ' ') with Not_found -> None with
  | Some pos -> String.before s pos :: split_string (String.after s (pos + 1))
  | None -> [s]

(* string_trim taken from OCaml 4.00 standard library (String.trim) *)
let is_space = function
  | ' ' | '\012' | '\n' | '\r' | '\t' -> true
  | _ -> false

let string_trim s =
  let len = String.length s in
  let i = ref 0 in
  while !i < len && is_space s.[!i] do incr i done;
  let j = ref (len - 1) in
  while !j >= !i && is_space s.[!j] do decr j done;
  if !i = 0 && !j = len - 1 then s
  else if !j >= !i then String.sub s !i (!j - !i + 1)
  else ""

let pkg_export =
  let env = BaseEnvLight.load () in
  let bcs = BaseEnvLight.var_get "brewcheck" env in
  let bcs = try bool_of_string bcs with _ -> false in
  let proc_env =
    try ignore (Sys.getenv "SQLITE3_OCAML_BREWCHECK"); true
    with _ -> false
  in
  if not (bcs || proc_env) then ""
  else
    let cmd = "brew ls sqlite | grep pkgconfig" in
    match read_lines_from_cmd ~max_lines:1 cmd with
    | [fullpath] when fullpath <> "" ->
      let path = Filename.dirname fullpath in
      Printf.sprintf "PKG_CONFIG_PATH=%s" path
    | _ -> ""

let () =
  let additional_rules = function
    | After_rules ->
        (* Add correct SQLite3 compilation and link flags *)
        let rec split_string s =
          match try Some (String.index s ' ') with Not_found -> None with
          | Some pos ->
              let before = string_trim (String.before s pos) in
              let after = String.after s (pos + 1) in
              if before = "" then split_string after
              else before :: split_string after
          | None when s = "" -> []
          | None -> [s]
        in
        let ocamlify ~ocaml_flag flags =
          let chunks = split_string flags in
          let cnv flag = [A ocaml_flag; A flag] in
          List.concat (List.map cnv chunks)
        in
        let split_flags flags =
          let chunks = split_string flags in
          let cnv flag = A flag in
          List.map cnv chunks
        in
        let osqlite3_cflags =
          let cmd = pkg_export ^ " pkg-config --cflags sqlite3" in
          match read_lines_from_cmd ~max_lines:1 cmd with
          | [cflags] -> S (ocamlify ~ocaml_flag:"-ccopt" cflags)
          | _ -> failwith "pkg-config failed for cflags"
        in
        let osqlite3_cflags =
          try
            ignore (Sys.getenv "SQLITE3_DISABLE_LOADABLE_EXTENSIONS");
            S [
              A "-ccopt"; A "-DSQLITE3_DISABLE_LOADABLE_EXTENSIONS";
              osqlite3_cflags
            ]
          with _ -> osqlite3_cflags
        in
        let sqlite3_clibs, osqlite3_clibs =
          let cmd = pkg_export ^ " pkg-config --libs sqlite3" in
          match read_lines_from_cmd ~max_lines:1 cmd with
          | [libs] ->
              S (split_flags libs), S (ocamlify ~ocaml_flag:"-cclib" libs)
          | _ -> failwith "pkg-config failed for libs"
        in
        flag ["compile"; "c"] osqlite3_cflags;
        flag ["link"; "ocaml"; "library"] osqlite3_clibs;
        flag ["oasis_library_sqlite3_cclib"; "ocamlmklib"; "c"] sqlite3_clibs;
        flag ["oasis_library_sqlite3_cclib"; "link"] osqlite3_clibs
      | _ -> ()
  in
  dispatch (
    MyOCamlbuildBase.dispatch_combine
      [MyOCamlbuildBase.dispatch_default conf package_default; additional_rules])
