                                                            /* -*- C++ -*- */
// %option defines the parameters with which the reflex will be launched
%option noyywrap
// To enable compatibility with bison
%option bison-complete
%option bison-cc-parser=parser
%option bison_cc_namespace=parse
%option bison-locations

%option lex=lex
// Add a param of function lex() generate in Lexer class
%option params="::parse::TigerDriver& td"
%option namespace=parse
// Name of the class generate by reflex
%option lexer=Lexer

%top{

#define YY_EXTERN_C extern "C" // For linkage rule

#include <cerrno>
#include <climits>
#include <regex>
#include <string>

#include <boost/lexical_cast.hpp>

#include <misc/contract.hh>
  // Using misc::escape is very useful to quote non printable characters.
  // For instance
  //
  //    std::cerr << misc::escape('\n') << '\n';
  //
  // reports about `\n' instead of an actual new-line character.
#include <misc/escape.hh>
#include <misc/symbol.hh>
#include <parse/parsetiger.hh>
#include <parse/tiger-driver.hh>

  // FIXED: Some code was deleted here (Define YY_USER_ACTION to update locations).
  #define YY_USER_ACTION td.location_.columns(size());

#define TOKEN(Type)                             \
  parser::make_ ## Type(td.location_)

#define TOKEN_VAL(Type, Value)                  \
  parser::make_ ## Type(Value, td.location_)

# define CHECK_EXTENSION()                              \
  do {                                                  \
    if (!td.enable_extensions_p_)                       \
      td.error_ << misc::error::error_type::scan        \
                << td.location_                         \
                << ": invalid identifier: `"            \
                << misc::escape(text()) << "'\n";       \
  } while (false)


%}

%x SC_COMMENT SC_STRING

/* Abbreviations.  */
int             [0-9]+

  /* FIXED: Some code was deleted here. */
id              [a-zA-Z][a-zA-Z0-9_]*
blank           [ \t\r]+
%class{
  // FIXED: Some code was deleted here (Local variables).
  std::string string_;
  int comment_depth_ = 0;
}

%%
/* The rules.  */
{int}         {
                int val = 0;
  // FIXED: Some code was deleted here (Decode, and check the value).
              try {
                  val = boost::lexical_cast<int>(text());
                }
                catch (const boost::bad_lexical_cast&) {
                  td.error_ << misc::error::error_type::scan
                            << td.location_
                            << ": integer out of range: `"
                            << misc::escape(text()) << "'\n";
                }
                return TOKEN_VAL(INT, val);
              }
  /* FIXED: Some code was deleted here. */
{blank}       {
                /* Skip blanks. */
              }

\n            {
                td.location_.lines(1);
                td.location_.step();
              }

","           return TOKEN(COMMA);
":"           return TOKEN(COLON);
";"           return TOKEN(SEMI);
"("           return TOKEN(LPAREN);
")"           return TOKEN(RPAREN);
"["           return TOKEN(LBRACK);
"]"           return TOKEN(RBRACK);
"{"           return TOKEN(LBRACE);
"}"           return TOKEN(RBRACE);
"."           return TOKEN(DOT);
"+"           return TOKEN(PLUS);
"-"           return TOKEN(MINUS);
"*"           return TOKEN(TIMES);
"/"           return TOKEN(DIVIDE);
"="           return TOKEN(EQ);
"<>"          return TOKEN(NE);
"<="          return TOKEN(LE);
">="          return TOKEN(GE);
"<"           return TOKEN(LT);
">"           return TOKEN(GT);
":="          return TOKEN(ASSIGN);

"array"       return TOKEN(ARRAY);
"if"          return TOKEN(IF);
"then"        return TOKEN(THEN);
"else"        return TOKEN(ELSE);
"while"       return TOKEN(WHILE);
"for"         return TOKEN(FOR);
"to"          return TOKEN(TO);
"do"          return TOKEN(DO);
"let"         return TOKEN(LET);
"in"          return TOKEN(IN);
"end"         return TOKEN(END);
"of"          return TOKEN(OF);
"break"       return TOKEN(BREAK);
"nil"         return TOKEN(NIL);
"function"    return TOKEN(FUNCTION);
"var"         return TOKEN(VAR);
"type"        return TOKEN(TYPE);

{id}          return TOKEN_VAL(ID, misc::symbol(text()));

.             {
                td.error_ << misc::error::error_type::scan
                          << td.location_
                          << ": invalid character: `"
                          << misc::escape(text()) << "'\n";
              }
%%



