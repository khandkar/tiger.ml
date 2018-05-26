%{
  open Printf
%}

/* Declarations */
%token AND
%token ARRAY
%token ASSIGN
%token BREAK
%token COLON
%token COMMA
%token DIVIDE
%token DO
%token DOT
%token ELSE
%token END
%token EOF
%token EQ
%token FOR
%token FUNCTION
%token GE
%token GT
%token <string> ID
%token IF
%token IN
%token <int> INT
%token LBRACE
%token LBRACK
%token LE
%token LET
%token LPAREN
%token LT
%token MINUS
%token NEQ
%token NIL
%token OF
%token OR
%token PLUS
%token RBRACE
%token RBRACK
%token RPAREN
%token SEMICOLON
%token <string> STRING
%token THEN
%token TIMES
%token TO
%token TYPE
%token VAR
%token WHILE

/* from lowest precedence */
%left OR
%left AND
%nonassoc EQ NEQ GT LT GE LE
%left PLUS MINUS
%left TIMES DIVIDE
%nonassoc UMINUS
/* to highest precedence */

%type <string> program

%start program

%%

program:
  | exp EOF
    {
      sprintf "program[%s]" $1
    }

exp:
  | NIL
    {
      "nil[]"
    }
  | INT
    {
      sprintf "int[%d]" $1
    }
  | MINUS exp %prec UMINUS
    {
      sprintf "negation[%s]" $2
    }
  | type_id LBRACK exp RBRACK OF exp
    {
      sprintf "array[type[%s], size[%s], val[%s]]" $1 $3 $6
    }
  | type_id LBRACE rec_field_assignments RBRACE
    {
      sprintf "record[type[%s], rec_field_assignments[%s]]" $1 $3
    }
  | lvalue
    {
      $1
    }
  | lvalue ASSIGN exp
    {
      sprintf "assign[%s := %s]" $1 $3
    }
  | STRING
    {
      sprintf "string[%S]" $1
    }
  | fun_call
    {
      $1
    }
  | exp op exp
    {
      sprintf "op[%s %s %s]" $1 $2 $3
    }
  | IF exp THEN exp ELSE exp
    {
      let e1 = $2 in
      let e2 = $4 in
      let e3 = $6 in
      sprintf "if_then_else[%s, then[%s], else[%s]]" e1 e2 e3
    }
  | IF exp THEN exp
    {
      sprintf "if_then[%s, then[%s]]" $2 $4
    }
  | WHILE exp DO exp
    {
      sprintf "while[%s, do[%s]]" $2 $4
    }
  | FOR id ASSIGN exp TO exp DO exp
    {
      let id = $2 in
      let e1 = $4 in
      let e2 = $6 in
      let e3 = $8 in
      sprintf "for[%s := %s, to[%s], do[%s]]" id e1 e2 e3
    }
  | BREAK
    {
      "break[]"
    }
  | LPAREN seq RPAREN
    {
      sprintf "seq[%s]" $2
    }
  | LET decs IN seq END
    {
      let decs = $2 in
      let seq = $4 in
      sprintf "let[decs[%s], in[seq[%s]]]" decs seq
    }
  | unit
    {
      $1
    }

seq:
  | exp
    {
      sprintf "%s" $1
    }
  | exp SEMICOLON seq
    {
      sprintf "%s; %s" $1 $3
    }

decs:
  | dec
    {
      sprintf "%s" $1
    }
  | dec decs
    {
      sprintf "%s %s" $1 $2
    }

dec:
  | tydec  {$1}
  | vardec {$1}
  | fundec {$1}

fundec:
  | FUNCTION id LPAREN tyfields RPAREN EQ exp
    {
      let id       = $2 in
      let tyfields = $4 in
      let exp      = $7 in
      sprintf "fundec[%s, tyfields[%s], exp[%s]]" id tyfields exp
    }
  | FUNCTION id LPAREN tyfields RPAREN COLON type_id EQ exp
    {
      let id       = $2 in
      let tyfields = $4 in
      let type_id  = $7 in
      let exp      = $9 in
      sprintf
        "fundec[%s, tyfields[%s], type_id[%s], exp[%s]]"
        id tyfields type_id exp
    }

vardec:
  | VAR id ASSIGN exp
    {
      let id = $2 in
      let exp = $4 in
      sprintf "vardec[%s, exp[%s]]" id exp
    }
  | VAR id COLON type_id ASSIGN exp
    {
      let id = $2 in
      let tyid = $4 in
      let exp = $6 in
      sprintf "vardec[%s, type_id[%s], exp[%s]]" id tyid exp
    }

tydec:
  | TYPE type_id EQ ty
    {
      sprintf "tydec[%s, %s]" $2 $4
    }

ty:
  | type_id
    {$1}
  | LBRACE RBRACE
    {
      "record[]"
    }
  | LBRACE tyfields RBRACE
    {
      let tyfields = $2 in
      sprintf "record[%s]" tyfields
    }
  | ARRAY OF type_id
    {
      let type_id = $3 in
      sprintf "array_of_type[%s]" type_id
    }

tyfields:
/*| epsilon */
  | tyfield
    {$1}
  | tyfield COMMA tyfields
    {
      let tyfield = $1 in
      let tyfields = $3 in
      sprintf "%s, %s" tyfield tyfields
    }

tyfield:
  | id COLON type_id
    {
      let id = $1 in
      let type_id = $3 in
      sprintf "tyfield[%s, %s]" id type_id
    }

id:
  | ID
    {
      sprintf "id[%S]" $1
    }

/* Perhaps "void"? */
unit:
  | LPAREN RPAREN
    {
      "unit[]"
    }

type_id:
  | id
    {
      sprintf "type_id[%S]" $1
    }

rec_field_assignments:
  | id EQ exp
    {
      sprintf "%S = %s" $1 $3
    }
  | id EQ exp COMMA rec_field_assignments
    {
      sprintf "%S = %s, %s" $1 $3 $5
    }

fun_call:
  | id unit
    {
      sprintf "fun_call[%s, %s]" $1 $2
    }
  | id LPAREN fun_args RPAREN
    {
      sprintf "fun_call[%s, %s]" $1 $3
    }

fun_args:
  | exp
    {
      $1
    }
  | exp COMMA fun_args
    {
      sprintf "%s, %s" $1 $3
    }

op:
  | PLUS   {"+"}
  | MINUS  {"-"}
  | TIMES  {"*"}
  | DIVIDE {"/"}
  | EQ     {"="}
  | NEQ    {"<>"}
  | GT     {">"}
  | LT     {"<"}
  | GE     {">="}
  | LE     {"<="}
  | AND    {"&"}
  | OR     {"|"}

lvalue:
  | id
    {
      sprintf "lvalue[%s]" $1
    }
  | lvalue DOT id
    {
      sprintf "get_record_field[%s, %s]" $1 $3
    }
  | lvalue LBRACK exp RBRACK
    {
      sprintf "get_array_subscript[%s, %s]" $1 $3
    }

%%
