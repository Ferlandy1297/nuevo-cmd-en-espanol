%option noyywrap
%option yylineno
%option nounput
%option noinput

%x ESTADO_TEXTO ESTADO_COLOR

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
ECO_K           [Ee][Cc][Oo]
PAUSA_K         [Pp][Aa][Uu][Ss][Aa]
TITULO_K        [Tt][Ii][Tt][Uu][Ll][Oo]
COLOR_K         [Cc][Oo][Ll][Oo][Rr]
ARBOL_K         [Aa][Rr][Bb][Oo][Ll]
BUSCAR_K        [Bb][Uu][Ss][Cc][Aa][Rr]
BUSCAR_TEXTO_K  [Bb][Uu][Ss][Cc][Aa][Rr]_[Tt][Ee][Xx][Tt][Oo]
MAS_K           [Mm][Aa][Ss]
ORDENAR_K       [Oo][Rr][Dd][Ee][Nn][Aa][Rr]
COMPARAR_K      [Cc][Oo][Mm][Pp][Aa][Rr][Aa][Rr]
CAMBIAR_DIR_K   [Cc][Aa][Mm][Bb][Ii][Aa][Rr]_[Dd][Ii][Rr]
CREAR_DIR_K     [Cc][Rr][Ee][Aa][Rr]_[Dd][Ii][Rr]
ELIMINAR_DIR_K  [Ee][Ll][Ii][Mm][Ii][Nn][Aa][Rr]_[Dd][Ii][Rr]
MOSTRAR_K       [Mm][Oo][Ss][Tt][Rr][Aa][Rr]
ELIMINAR_K      [Ee][Ll][Ii][Mm][Ii][Nn][Aa][Rr]
RENOMBRAR_K     [Rr][Ee][Nn][Oo][Mm][Bb][Rr][Aa][Rr]
COPIAR_K        [Cc][Oo][Pp][Ii][Aa][Rr]
MOVER_K         [Mm][Oo][Vv][Ee][Rr]
PUNTO_PUNTO_K   \.\.
PUNTO_K         \.
NOMBRE_DIR      [A-Za-z0-9_][A-Za-z0-9_.-]*

%%
<INITIAL>{WS}                ;
<INITIAL>{AYUDA_K}           return AYUDA;
<INITIAL>{VERSION_K}         return VERSION;
<INITIAL>{SALIR_K}           return SALIR;
<INITIAL>{LIMPIAR_K}         return LIMPIAR;
<INITIAL>{FECHA_K}           return FECHA;
<INITIAL>{HORA_K}            return HORA;
<INITIAL>{LISTAR_K}          return LISTAR;
<INITIAL>{ECO_K}             { BEGIN(ESTADO_TEXTO); return ECO; }
<INITIAL>{PAUSA_K}           return PAUSA;
<INITIAL>{TITULO_K}          { BEGIN(ESTADO_TEXTO); return TITULO; }
<INITIAL>{COLOR_K}           { BEGIN(ESTADO_COLOR); return COLOR; }
<INITIAL>{ARBOL_K}           return ARBOL;
<INITIAL>{BUSCAR_TEXTO_K}    return BUSCAR_TEXTO;
<INITIAL>{BUSCAR_K}          return BUSCAR;
<INITIAL>{MAS_K}             return MAS;
<INITIAL>{ORDENAR_K}         return ORDENAR;
<INITIAL>{COMPARAR_K}        return COMPARAR;
<INITIAL>{CAMBIAR_DIR_K}     return CAMBIAR_DIR;
<INITIAL>{CREAR_DIR_K}       return CREAR_DIR;
<INITIAL>{ELIMINAR_DIR_K}    return ELIMINAR_DIR;
<INITIAL>{MOSTRAR_K}         return MOSTRAR;
<INITIAL>{ELIMINAR_K}        return ELIMINAR;
<INITIAL>{RENOMBRAR_K}       return RENOMBRAR;
<INITIAL>{COPIAR_K}          return COPIAR;
<INITIAL>{MOVER_K}           return MOVER;
<INITIAL>{PUNTO_PUNTO_K}     return PUNTO_PUNTO;
<INITIAL>{PUNTO_K}           return PUNTO;
<INITIAL>{NOMBRE_DIR}        {
                        yylval.texto = duplicar_texto(yytext);
                        return NOMBRE;
                    }
<ESTADO_TEXTO>{WS}           ;
<ESTADO_TEXTO>[^ \t\r\n][^\r\n]* {
                        yylval.texto = duplicar_texto(yytext);
                        BEGIN(INITIAL);
                        return TEXTO;
                    }
<ESTADO_COLOR>{WS}           ;
<ESTADO_COLOR>[^ \t\r\n][^\r\n]* {
                        yylval.texto = duplicar_texto(yytext);
                        BEGIN(INITIAL);
                        return TEXTO;
                    }
<INITIAL,ESTADO_TEXTO,ESTADO_COLOR>\n {
                        BEGIN(INITIAL);
                        return NEWLINE;
                    }

<INITIAL>.                   {
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
