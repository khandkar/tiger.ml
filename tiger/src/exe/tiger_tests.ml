open Printf

module List = ListLabels

let test_01 =
  let name = "an array type and an array variable" in
  let code =
    " \
    /* "^name^" */ \
    let \
      type arrtype = array of int \
      var arr1:arrtype := \
        arrtype [10] of 0 \
    in \
      arr1 \
    end \
    "
  in
  let tokens =
    let open Tiger.Parser in
    [ LET;
        TYPE; ID "arrtype"; EQ; ARRAY; OF; ID "int";
        VAR; ID "arr1"; COLON; ID "arrtype"; ASSIGN;
          ID "arrtype"; LBRACK; INT 10; RBRACK; OF; INT 0;
      IN;
        ID "arr1";
      END
    ]
  in
  (name, code, tokens)

let test_02 =
  let name = "arr1 is valid since expression 0 is int = myint" in
  let code =
    " \
    /* "^name^" */ \
    let \
      type myint = int \
      type arrtype = array of myint \
      var arr1:arrtype := \
        arrtype [10] of 0 \
    in \
      arr1 \
    end \
    "
  in
  let tokens =
    let open Tiger.Parser in
    [ LET;
        TYPE; ID "myint"; EQ; ID "int";
        TYPE; ID "arrtype"; EQ; ARRAY; OF; ID "myint";
        VAR; ID "arr1"; COLON; ID "arrtype"; ASSIGN;
          ID "arrtype"; LBRACK; INT 10; RBRACK; OF; INT 0;
      IN;
        ID "arr1";
      END
    ]
  in
  (name, code, tokens)

let test_03 =
  let name = "a record type and a record variable" in
  let code =
    " \
    /* "^name^" */ \
    let \
      type rectype = \
        { name : string \
        , age  : int \
        } \
      var rec1 : rectype := \
        rectype \
        { name = \"Nobody\" \
        , age  = 1000 \
        } \
    in \
      rec1.name := \"Somebody\"; \
      rec1 \
    end \
    "
  in
  let tokens =
    let open Tiger.Parser in
    [ LET;
        TYPE; ID "rectype"; EQ;
          LBRACE; ID "name"; COLON; ID "string";
          COMMA;  ID "age";  COLON; ID "int";
          RBRACE;
        VAR; ID "rec1"; COLON; ID "rectype"; ASSIGN;
          ID "rectype";
          LBRACE; ID "name"; EQ; STRING "Nobody";
          COMMA;  ID "age";  EQ; INT 1000;
          RBRACE;
      IN;
        ID "rec1"; DOT; ID "name"; ASSIGN; STRING "Somebody"; SEMICOLON;
        ID "rec1";
      END
    ]
  in
  (name, code, tokens)

let test_04 =
  let name = "define a recursive function" in
  let code =
    " \
    /* "^name^" */ \
    let \
    \
      /* calculate n! */ \
      function nfactor(n: int): int = \
        if n = 0  \
        then 1 \
        else n * nfactor(n-1) \
    \
    in \
      nfactor(10) \
    end \
    "
  in
  let tokens =
    let open Tiger.Parser in
    [ LET;
        FUNCTION; ID "nfactor"; LPAREN; ID "n"; COLON; ID "int"; RPAREN; COLON; ID "int"; EQ;
          IF; ID "n"; EQ; INT 0;
          THEN; INT 1;
          ELSE; ID "n"; TIMES; ID "nfactor"; LPAREN; ID "n"; MINUS; INT 1; RPAREN;
      IN;
        ID "nfactor"; LPAREN; INT 10; RPAREN;
      END
    ]
  in
  (name, code, tokens)

let test_09 =
  let name = "error : types of then - else differ" in
  let code =
    " \
    /* "^name^" */ \
    if (5>4) then 13 else  \" \" \
    "
  in
  let tokens =
    let open Tiger.Parser in
    [ IF; LPAREN; INT 5; GT; INT 4; RPAREN; THEN; INT 13; ELSE; STRING " "
    ]
  in
  (* TODO: Type error test case *)
  (name, code, tokens)

let tokens_of_code code =
  let lexbuf = Lexing.from_string code in
  let rec tokens () =
    let token = Tiger.Lexer.token lexbuf in
    (* Avoiding fragile pattern-matching *)
    if token = Tiger.Parser.EOF then [] else token :: tokens ()
  in
  tokens ()

let parsetree_of_code code =
  let lb = Lexing.from_string code in
  (match Tiger.Parser.program Tiger.Lexer.token lb with
  | exception Parsing.Parse_error ->
      let module L = Lexing in
      let L.({lex_curr_p = {pos_lnum=l; pos_bol=b; pos_cnum=c; _}; _}) = lb in
      let msg = sprintf "Syntax error around line: %d, column: %d" l (c - b) in
      Error msg
  | parsetree ->
      Ok parsetree
  )

let tests =
  [ test_01
  ; test_02
  ; test_03
  ; test_04
  ; test_09
  ]

let () =
  let bar_sep = String.make 80 '-' in
  let bar_end = String.make 80 '=' in
  let indent n = String.make (2 * n) ' ' in
  let color_on_green = "\027[0;32m" in
  let color_on_red   = "\027[1;31m" in
  let color_off      = "\027[0m" in
  List.iteri tests ~f:(fun i (name, code, tokens_expected) ->
    let i = i + 1 in  (* Because iteri starts with 0 *)
    printf "%s\n%sTest %d : %S\n" bar_sep (indent 0) i name;

    printf "%sLexing : " (indent 1);
    let tokens_emitted = tokens_of_code code in
    (try
      assert (tokens_emitted = tokens_expected);
      printf "%sOK%s\n" color_on_green color_off;
    with Assert_failure _ ->
      let tokens_to_string tokens =
        String.concat "; " (List.map ~f:Tiger.Parser_token.to_string tokens)
      in
      printf
        "%sERROR%s\n%sExpected: %s\n%sEmitted : %s\n\n"
        color_on_red
        color_off
        (indent 2)
        (tokens_to_string tokens_expected)
        (indent 2)
        (tokens_to_string tokens_emitted)
    );

    printf "%sParsing: " (indent 1);
    (match parsetree_of_code code with
    | Error errmsg -> printf "%sERROR:%s %s\n" color_on_red   color_off errmsg
    | Ok parsetree -> printf "%sOK:%s %s\n"    color_on_green color_off parsetree
    );

  );
  print_endline bar_end;
