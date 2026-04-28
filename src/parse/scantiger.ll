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
#include <misc/escape.hh>
#include <misc/symbol.hh>
#include <parse/parsetiger.hh>
#include <parse/tiger-driver.hh>

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
id              [a-zA-Z][a-zA-Z0-9_]*
blank           [ \t\r]+

%class{
  std::string string_;
  int comment_depth_ = 0;
}

%%

/* Integers.  */
{int}         {
                int val = 0;
                try
                  {
                    val = boost::lexical_cast<int>(text());
                  }
                catch (const boost::bad_lexical_cast&)
                  {
                    td.error_ << misc::error::error_type::scan
                              << td.location_
                              << ": integer out of range: `"
                              << misc::escape(text()) << "'\n";
                  }
                return TOKEN_VAL(INT, val);
              }

/* Blanks and new lines.  */
{blank}       {
                /* Skip blanks. */
              }

\n            {
                td.location_.lines(1);
                td.location_.step();
              }

/* Comments.  */
"/*"          {
                comment_depth_ = 1;
                start(SC_COMMENT);
              }

<SC_COMMENT>"/*" {
                ++comment_depth_;
              }

<SC_COMMENT>"*/" {
                --comment_depth_;
                if (comment_depth_ == 0)
                  start(INITIAL);
              }

<SC_COMMENT>\n {
                td.location_.lines(1);
                td.location_.step();
              }

<SC_COMMENT>. {
                /* Skip comment characters. */
              }

<SC_COMMENT><<EOF>> {
                td.error_ << misc::error::error_type::scan
                          << td.location_
                          << ": unterminated comment\n";
                start(INITIAL);
              }

/* Strings.  */
\"            {
                string_.clear();
                start(SC_STRING);
              }

<SC_STRING>\" {
                start(INITIAL);
                return TOKEN_VAL(STRING, string_);
              }

<SC_STRING>\\n {
                string_ += '\n';
              }

<SC_STRING>\\t {
                string_ += '\t';
              }

<SC_STRING>\\\" {
                string_ += '"';
              }

<SC_STRING>\\\\ {
                string_ += '\\';
              }

<SC_STRING>\\[0-9][0-9][0-9] {
                int c = std::stoi(text() + 1);
                if (c > UCHAR_MAX)
                  td.error_ << misc::error::error_type::scan
                            << td.location_
                            << ": invalid escape sequence: `"
                            << misc::escape(text()) << "'\n";
                else
                  string_ += static_cast<char>(c);
              }

<SC_STRING>\n {
                td.error_ << misc::error::error_type::scan
                          << td.location_
                          << ": unterminated string\n";
                td.location_.lines(1);
                td.location_.step();
                start(INITIAL);
              }

<SC_STRING><<EOF>> {
                td.error_ << misc::error::error_type::scan
                          << td.location_
                          << ": unterminated string\n";
                start(INITIAL);
              }

<SC_STRING>. {
                string_ += text();
              }

/* Punctuation and operators.  */
":="          return TOKEN(ASSIGN);
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

/* Keywords.  */
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

/* Identifiers.  */
{id}          return TOKEN_VAL(ID, misc::symbol(text()));

/* Lexical errors.  */
.             {
                td.error_ << misc::error::error_type::scan
                          << td.location_
                          << ": invalid character: `"
                          << misc::escape(text()) << "'\n";
              }

%%