                                                                // -*- C++ -*-
%require "3.8"
%language "c++"
// Set the namespace name to `parse', instead of `yy'.
%define api.prefix {parse}
%define api.namespace {parse}
%define api.parser.class {parser}
%define api.value.type variant
%define api.token.constructor

// We use a GLR parser because it is able to handle Shift-Reduce and
// Reduce-Reduce conflicts by forking and testing each way at runtime. GLR
// permits, by allowing few conflicts, more readable and maintainable grammars.
%glr-parser
%skeleton "glr2.cc"

// In TC, we expect the GLR to resolve one Shift-Reduce and zero Reduce-Reduce
// conflict at runtime. Use %expect and %expect-rr to tell Bison about it.
%expect 2
%expect-rr 0

%define parse.error verbose
%defines
%debug
// Prefix all the tokens with TOK_ to avoid colisions.
%define api.token.prefix {TOK_}

%define api.filename.type {const std::string}
%locations

/*---------------------.
| Support for tokens.  |
`---------------------*/
%code requires
{
#include <string>
#include <misc/algorithm.hh>
#include <misc/separator.hh>
#include <misc/symbol.hh>
#include <parse/fwd.hh>

  namespace parse
  {
    ast_type parse(Tweast& input);
  }
}

// The parsing context.
%param { ::parse::TigerDriver& td }
%parse-param { ::parse::Lexer& lexer }

%printer { yyo << $$; } <int> <std::string> <misc::symbol>;

%token <std::string>    STRING "string"
%token <misc::symbol>   ID     "identifier"
%token <int>            INT    "integer"

/*--------------------------------.
| Support for the non-terminals.  |
`--------------------------------*/

%code requires
{
# include <ast/fwd.hh>
# include <ast/exp.hh>
# include <ast/var.hh>
# include <ast/ty.hh>
# include <ast/name-ty.hh>
# include <ast/field.hh>
# include <ast/field-init.hh>
# include <ast/function-dec.hh>
# include <ast/type-dec.hh>
# include <ast/var-dec.hh>
# include <ast/chunk.hh>
# include <ast/chunk-list.hh>
}

%printer { yyo << *$$; } <ast::Exp*> <ast::Var*> <ast::Ty*>
                          <ast::NameTy*> <ast::Field*>
                          <ast::FieldInit*> <ast::FunctionDec*>
                          <ast::TypeDec*> <ast::VarDec*>
                          <ast::ChunkList*> <ast::VarChunk*>
                          <ast::FunctionChunk*> <ast::TypeChunk*>;

%destructor { delete $$; } <ast::Exp*> <ast::Var*> <ast::Ty*>
                           <ast::NameTy*> <ast::Field*>
                           <ast::FieldInit*> <ast::FunctionDec*>
                           <ast::TypeDec*> <ast::VarDec*>
                           <ast::ChunkList*> <ast::VarChunk*>
                           <ast::FunctionChunk*> <ast::TypeChunk*>;

%printer { yyo << "<fields>"; } <ast::fields_type*>;
%printer { yyo << "<fieldinits>"; } <ast::fieldinits_type*>;
%printer { yyo << "<exps>"; } <ast::exps_type*>;

%destructor { delete $$; } <ast::fields_type*> <ast::fieldinits_type*>
                           <ast::exps_type*>;

/*-----------------------------------------.
| Code output in the implementation file.  |
`-----------------------------------------*/

%code
{
# include <parse/tweast.hh>
# include <parse/tiger-driver.hh>
# include <misc/separator.hh>
# include <misc/symbol.hh>
# include <ast/all.hh>
# include <ast/libast.hh>
# include <parse/tiger-factory.hh>

  namespace
  {
    template <typename T>
    T*
    metavar(parse::TigerDriver& td, unsigned key)
    {
      parse::Tweast* input = td.input_;
      return input->template take<T>(key);
    }
  }
}

%code
{
  #include <parse/scantiger.hh>
  #undef yylex
  #define yylex lexer.lex
}

// Definition of the tokens, and their pretty-printing.
%token AND          "&"
       ARRAY        "array"
       ASSIGN       ":="
       BREAK        "break"
       CAST         "_cast"
       CLASS        "class"
       COLON        ":"
       COMMA        ","
       DIVIDE       "/"
       DO           "do"
       DOT          "."
       ELSE         "else"
       END          "end"
       EQ           "="
       EXTENDS      "extends"
       FOR          "for"
       FUNCTION     "function"
       GE           ">="
       GT           ">"
       IF           "if"
       IMPORT       "import"
       IN           "in"
       LBRACE       "{"
       LBRACK       "["
       LE           "<="
       LET          "let"
       LPAREN       "("
       LT           "<"
       MINUS        "-"
       METHOD       "method"
       NE           "<>"
       NEW          "new"
       NIL          "nil"
       OF           "of"
       OR           "|"
       PLUS         "+"
       PRIMITIVE    "primitive"
       RBRACE       "}"
       RBRACK       "]"
       RPAREN       ")"
       SEMI         ";"
       THEN         "then"
       TIMES        "*"
       TO           "to"
       TYPE         "type"
       VAR          "var"
       WHILE        "while"
       EOF 0        "end of file"

%type <ast::Exp*>             exp
%type <ast::ChunkList*>       chunks

%type <ast::TypeChunk*>       tychunk
%type <ast::TypeDec*>         tydec
%type <ast::NameTy*>          typeid
%type <ast::Ty*>              ty

%type <ast::Field*>           tyfield
%type <ast::fields_type*>     tyfields tyfields.1

%type <ast::Var*>             lvalue
%type <ast::exps_type*>       exps.0 exps

%type <ast::VarDec*>          vardec
%type <ast::VarChunk*>        varchunk
%type <ast::VarChunk*>        funargs funargs.1

%type <ast::FunctionDec*>     fundec
%type <ast::FunctionChunk*>   funchunk

%type <ast::NameTy*>          typeid.opt
%type <ast::FieldInit*>       fieldinit
%type <ast::fieldinits_type*> fieldinits fieldinits.1

%left "|"
%left "&"
%nonassoc "=" "<>" "<" "<=" ">" ">="
%left "+" "-"
%left "*" "/"
%precedence UMINUS
%precedence "then"
%precedence "else"
%nonassoc "do"
%nonassoc "of"
%nonassoc ":="

%precedence CHUNKS
%precedence TYPE

%token EXP "_exp"
%token LVALUE "_lvalue"
%token FIELD "_field"
%token FIELDINIT "_fieldinit"
%token CASTEXP "_cast_exp"
%token NAMETY "_namety"
%token CHUNKS "_chunks"

%start program

%%
program:
  exp
    { td.ast_ = $1; }
| chunks
    { td.ast_ = $1; }
;

/*----------------.
| Expressions.    |
`----------------*/

exp:
  INT
    { $$ = make_IntExp(@$, $1); }

| STRING
    { $$ = make_StringExp(@$, $1); }

| NIL
    { $$ = make_NilExp(@$); }

| ID
    { $$ = make_SimpleVar(@$, $1); }

| ID "(" exps.0 ")"
    { $$ = make_CallExp(@$, $1, $3); }

| "(" exps.0 ")"
    { $$ = make_SeqExp(@$, $2); }

| lvalue ":=" exp
    { $$ = make_AssignExp(@$, $1, $3); }

| "if" exp "then" exp %prec "then"
    { $$ = make_IfExp(@$, $2, $4); }

| "if" exp "then" exp "else" exp
    { $$ = make_IfExp(@$, $2, $4, $6); }

| "while" exp "do" exp
    { $$ = make_WhileExp(@$, $2, $4); }

| "for" ID ":=" exp "to" exp "do" exp
    {
      $$ = make_ForExp(@$,
                       make_VarDec(@2, $2, nullptr, $4),
                       $6,
                       $8);
    }

| "break"
    { $$ = make_BreakExp(@$); }

| "let" chunks "in" exps.0 "end"
    { $$ = make_LetExp(@$, $2, make_SeqExp(@4, $4)); }

| exp "+" exp
    { $$ = make_OpExp(@$, $1, ast::OpExp::Oper::add, $3); }

| exp "-" exp
    { $$ = make_OpExp(@$, $1, ast::OpExp::Oper::sub, $3); }

| exp "*" exp
    { $$ = make_OpExp(@$, $1, ast::OpExp::Oper::mul, $3); }

| exp "/" exp
    { $$ = make_OpExp(@$, $1, ast::OpExp::Oper::div, $3); }

| exp "=" exp
    { $$ = make_OpExp(@$, $1, ast::OpExp::Oper::eq, $3); }

| exp "<>" exp
    { $$ = make_OpExp(@$, $1, ast::OpExp::Oper::ne, $3); }

| exp "<" exp
    { $$ = make_OpExp(@$, $1, ast::OpExp::Oper::lt, $3); }

| exp "<=" exp
    { $$ = make_OpExp(@$, $1, ast::OpExp::Oper::le, $3); }

| exp ">" exp
    { $$ = make_OpExp(@$, $1, ast::OpExp::Oper::gt, $3); }

| exp ">=" exp
    { $$ = make_OpExp(@$, $1, ast::OpExp::Oper::ge, $3); }

| "-" exp %prec UMINUS
    { $$ = make_OpExp(@$, make_IntExp(@1, 0), ast::OpExp::Oper::sub, $2); }

| exp "&" exp
    {
      $$ = make_IfExp(@$, $1,
                      make_OpExp(@3, $3, ast::OpExp::Oper::ne,
                                 make_IntExp(@3, 0)),
                      make_IntExp(@$, 0));
    }

| exp "|" exp
    {
      $$ = make_IfExp(@$, $1,
                      make_IntExp(@$, 1),
                      make_OpExp(@3, $3, ast::OpExp::Oper::ne,
                                 make_IntExp(@3, 0)));
    }

| ID "[" exp "]" "of" exp
    { $$ = make_ArrayExp(@$, make_NameTy(@1, $1), $3, $6); }

| ID "{" fieldinits "}"
    { $$ = make_RecordExp(@$, make_NameTy(@1, $1), $3); }

| "_exp" "(" INT ")"
    { $$ = metavar<ast::Exp>(td, $3); }
;

/*----------------.
| Lvalues.        |
`----------------*/

lvalue:
  ID
    { $$ = make_SimpleVar(@$, $1); }

| lvalue "[" exp "]"
    { $$ = make_SubscriptVar(@$, $1, $3); }

| lvalue "." ID
    { $$ = make_FieldVar(@$, $1, $3); }
;

/*----------------.
| Expression list |
`----------------*/

exps.0:
  %empty
    { $$ = make_exps_type(); }

| exps
    { $$ = $1; }
;

exps:
  exp
    { $$ = make_exps_type($1); }

| exps ";" exp
    { $$ = $1; $$->push_back($3); }
;

/*----------------.
| Field inits.    |
`----------------*/

fieldinits:
  %empty
    { $$ = make_fieldinits_type(); }

| fieldinits.1
    { $$ = $1; }
;

fieldinits.1:
  fieldinit
    { $$ = make_fieldinits_type($1); }

| fieldinits.1 "," fieldinit
    { $$ = $1; $$->push_back($3); }
;

fieldinit:
  ID "=" exp
    { $$ = make_FieldInit(@$, $1, $3); }
;

/*---------------.
| Declarations.  |
`---------------*/

chunks:
  %empty
    { $$ = make_ChunkList(@$); }

| tychunk chunks
    { $$ = $2; $$->push_front($1); }

| funchunk chunks
    { $$ = $2; $$->push_front($1); }

| varchunk chunks
    { $$ = $2; $$->push_front($1); }
;

/*------------------------.
| Function Declarations.  |
`------------------------*/

funchunk:
  fundec %prec CHUNKS
    { $$ = make_FunctionChunk(@1); $$->push_front(*$1); }

| fundec funchunk
    { $$ = $2; $$->push_front(*$1); }
;

fundec:
  "function" ID "(" funargs ")" typeid.opt "=" exp
    { $$ = make_FunctionDec(@$, $2, $4, $6, $8); }
;

funargs:
  %empty
    { $$ = make_VarChunk(@$); }

| funargs.1
    { $$ = $1; }
;

funargs.1:
  ID ":" typeid
    {
      $$ = make_VarChunk(@$);
      $$->emplace_back(*make_VarDec(@$, $1, $3, nullptr));
    }

| funargs.1 "," ID ":" typeid
    {
      $$ = $1;
      $$->emplace_back(*make_VarDec(@3, $3, $5, nullptr));
    }
;

typeid.opt:
  %empty
    { $$ = nullptr; }

| ":" typeid
    { $$ = $2; }
;

/*------------------------.
| Variable Declarations.  |
`------------------------*/

varchunk:
  vardec %prec CHUNKS
    { $$ = make_VarChunk(@1); $$->push_front(*$1); }
;

vardec:
  "var" ID ":=" exp
    { $$ = make_VarDec(@$, $2, nullptr, $4); }

| "var" ID ":" typeid ":=" exp
    { $$ = make_VarDec(@$, $2, $4, $6); }
;

/*--------------------.
| Type Declarations.  |
`--------------------*/

tychunk:
  tydec %prec CHUNKS
    { $$ = make_TypeChunk(@1); $$->push_front(*$1); }

| tydec tychunk
    { $$ = $2; $$->push_front(*$1); }
;

tydec:
  "type" ID "=" ty
    { $$ = make_TypeDec(@$, $2, $4); }
;

ty:
  typeid
    { $$ = $1; }

| "{" tyfields "}"
    { $$ = make_RecordTy(@$, $2); }

| "array" "of" typeid
    { $$ = make_ArrayTy(@$, $3); }
;

tyfields:
  %empty
    { $$ = make_fields_type(); }

| tyfields.1
    { $$ = $1; }
;

tyfields.1:
  tyfield
    { $$ = make_fields_type($1); }

| tyfields.1 "," tyfield
    { $$ = $1; $$->emplace_back($3); }
;

tyfield:
  ID ":" typeid
    { $$ = make_Field(@$, $1, $3); }
;

typeid:
  ID
    { $$ = make_NameTy(@$, $1); }

| NAMETY "(" INT ")"
    { $$ = metavar<ast::NameTy>(td, $3); }
;

%%

void
parse::parser::error(const location_type& l, const std::string& m)
{
  td.error_ << l << ": " << m << '\n';
}