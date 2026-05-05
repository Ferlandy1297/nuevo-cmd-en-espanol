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
LIMPIAR_K   [Ll][Ii][Mm][Pp][Ii][Aa][Rr]
FECHA_K     [Ff][Ee][Cc][Hh][Aa]
HORA_K      [Hh][Oo][Rr][Aa]
IDERR       [A-Za-z0-9_./\\:-]+

%%
{WS}            ;
{AYUDA_K}       return AYUDA;
{VERSION_K}     return VERSION;
{SALIR_K}       return SALIR;
{LIMPIAR_K}     return LIMPIAR;
{FECHA_K}       return FECHA;
{HORA_K}        return HORA;
\n              return NEWLINE;

{IDERR}         { fprintf(stderr, "Error lexico (linea %d): '%s'\n", yylineno, yytext); }
.               { fprintf(stderr, "Error lexico (linea %d): '%s'\n", yylineno, yytext); }
%%
