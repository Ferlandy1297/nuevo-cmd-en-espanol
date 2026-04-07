%option noyywrap
%option yylineno
%option nounput
%option noinput

%{
#include "cmd_es.tab.h"
#include <stdio.h>
%}

WS          [ \t\r]+
AYUDA_K     [Aa][Yy][Uu][Dd][Aa]
VERSION_K   [Vv][Ee][Rr][Ss][Ii][Oo][Nn]
SALIR_K     [Ss][Aa][Ll][Ii][Rr]
IDERR       [A-Za-z0-9_./\\:-]+

%%
{WS}            ;
{AYUDA_K}       return AYUDA;
{VERSION_K}     return VERSION;
{SALIR_K}       return SALIR;
\n              return NEWLINE;

{IDERR}         { fprintf(stderr, "Error lexico (linea %d): '%s'\n", yylineno, yytext); }
.               { fprintf(stderr, "Error lexico (linea %d): '%s'\n", yylineno, yytext); }
%%