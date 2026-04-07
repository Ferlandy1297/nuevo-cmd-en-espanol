%option noyywrap
%option yylineno
%option nounput
%option noinput
%option caseless   /* Comandos no sensibles a mayusculas/minusculas */

%{
#include "cmd_es.tab.h"
#include <stdio.h>
%}

WS      [ \t\r]+
IDERR   [A-Za-z0-9_./\\:-]+

%%

{WS}                ; /* ignorar espacios y tabulaciones */
"AYUDA"            return AYUDA;
"VERSION"          return VERSION;
"SALIR"            return SALIR;
\n                  return NEWLINE;

/* Reporte de error lexico: consumir y continuar */
{IDERR}            { fprintf(stderr, "Error lexico (linea %d): '%s'\n", yylineno, yytext); }
.                   { fprintf(stderr, "Error lexico (linea %d): '%s'\n", yylineno, yytext); }

%%

int yywrap(void) { return 1; }
