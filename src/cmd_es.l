%option noyywrap
%option yylineno
%option nounput
%option noinput

%{
#include "cmd_es.tab.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern int cmd_es_linea_invalida;

static char *duplicar_texto(const char *texto);
%}

WS              [ \t\r]+
AYUDA_K         [Aa][Yy][Uu][Dd][Aa]
VERSION_K       [Vv][Ee][Rr][Ss][Ii][Oo][Nn]
SALIR_K         [Ss][Aa][Ll][Ii][Rr]
LIMPIAR_K       [Ll][Ii][Mm][Pp][Ii][Aa][Rr]
FECHA_K         [Ff][Ee][Cc][Hh][Aa]
HORA_K          [Hh][Oo][Rr][Aa]
LISTAR_K        [Ll][Ii][Ss][Tt][Aa][Rr]
CAMBIAR_DIR_K   [Cc][Aa][Mm][Bb][Ii][Aa][Rr]_[Dd][Ii][Rr]
CREAR_DIR_K     [Cc][Rr][Ee][Aa][Rr]_[Dd][Ii][Rr]
ELIMINAR_DIR_K  [Ee][Ll][Ii][Mm][Ii][Nn][Aa][Rr]_[Dd][Ii][Rr]
PUNTO_PUNTO_K   \.\.
PUNTO_K         \.
NOMBRE_DIR      [A-Za-z0-9_][A-Za-z0-9_.-]*

%%
{WS}                ;
{AYUDA_K}           return AYUDA;
{VERSION_K}         return VERSION;
{SALIR_K}           return SALIR;
{LIMPIAR_K}         return LIMPIAR;
{FECHA_K}           return FECHA;
{HORA_K}            return HORA;
{LISTAR_K}          return LISTAR;
{CAMBIAR_DIR_K}     return CAMBIAR_DIR;
{CREAR_DIR_K}       return CREAR_DIR;
{ELIMINAR_DIR_K}    return ELIMINAR_DIR;
{PUNTO_PUNTO_K}     return PUNTO_PUNTO;
{PUNTO_K}           return PUNTO;
{NOMBRE_DIR}        {
                        yylval.texto = duplicar_texto(yytext);
                        return NOMBRE;
                    }
\n                  return NEWLINE;

.                   {
                        cmd_es_linea_invalida = 1;
                        fprintf(stderr, "Error lexico (linea %d): '%s'\n", yylineno, yytext);
                    }
%%

static char *duplicar_texto(const char *texto) {
    size_t longitud;
    char *copia;

    longitud = strlen(texto) + 1;
    copia = (char *)malloc(longitud);

    if (copia == NULL) {
        fprintf(stderr, "Error: memoria insuficiente.\n");
        exit(1);
    }

    memcpy(copia, texto, longitud);
    return copia;
}
