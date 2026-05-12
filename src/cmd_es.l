%option noyywrap
%option yylineno
%option nounput
%option noinput

%x ESTADO_TEXTO ESTADO_COLOR ESTADO_NOMBRE

%{
typedef struct CmdEsExpresion CmdEsExpresion;
typedef struct CmdEsValor CmdEsValor;
typedef struct CmdEsSentenciaLenguaje CmdEsSentenciaLenguaje;

#include "cmd_es.tab.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern int cmd_es_linea_invalida;

static char *duplicar_texto(const char *texto);
static char *desescapar_cadena(const char *texto);
%}

WS                  [ \t\r]+
AYUDA_K             [Aa][Yy][Uu][Dd][Aa]
VERSION_K           [Vv][Ee][Rr][Ss][Ii][Oo][Nn]
SALIR_K             [Ss][Aa][Ll][Ii][Rr]
LIMPIAR_K           [Ll][Ii][Mm][Pp][Ii][Aa][Rr]
FECHA_K             [Ff][Ee][Cc][Hh][Aa]
HORA_K              [Hh][Oo][Rr][Aa]
LISTAR_K            [Ll][Ii][Ss][Tt][Aa][Rr]
ECO_K               [Ee][Cc][Oo]
PAUSA_K             [Pp][Aa][Uu][Ss][Aa]
TITULO_K            [Tt][Ii][Tt][Uu][Ll][Oo]
COLOR_K             [Cc][Oo][Ll][Oo][Rr]
ARBOL_K             [Aa][Rr][Bb][Oo][Ll]
BUSCAR_K            [Bb][Uu][Ss][Cc][Aa][Rr]
BUSCAR_TEXTO_K      [Bb][Uu][Ss][Cc][Aa][Rr]_[Tt][Ee][Xx][Tt][Oo]
MAS_K               [Mm][Aa][Ss]
ORDENAR_K           [Oo][Rr][Dd][Ee][Nn][Aa][Rr]
COMPARAR_K          [Cc][Oo][Mm][Pp][Aa][Rr][Aa][Rr]
SIMBOLO_K           [Ss][Ii][Mm][Bb][Oo][Ll][Oo]
RUTA_K              [Rr][Uu][Tt][Aa]
DEFINIR_K           [Dd][Ee][Ff][Ii][Nn][Ii][Rr]
CAMBIAR_DIR_K       [Cc][Aa][Mm][Bb][Ii][Aa][Rr]_[Dd][Ii][Rr]
CREAR_DIR_K         [Cc][Rr][Ee][Aa][Rr]_[Dd][Ii][Rr]
ELIMINAR_DIR_K      [Ee][Ll][Ii][Mm][Ii][Nn][Aa][Rr]_[Dd][Ii][Rr]
MOSTRAR_K           [Mm][Oo][Ss][Tt][Rr][Aa][Rr]
ELIMINAR_K          [Ee][Ll][Ii][Mm][Ii][Nn][Aa][Rr]
RENOMBRAR_K         [Rr][Ee][Nn][Oo][Mm][Bb][Rr][Aa][Rr]
COPIAR_K            [Cc][Oo][Pp][Ii][Aa][Rr]
MOVER_K             [Mm][Oo][Vv][Ee][Rr]
VAR_K               [Vv][Aa][Rr]
ENTERO_K            [Ee][Nn][Tt][Ee][Rr][Oo]
DECIMAL_K           [Dd][Ee][Cc][Ii][Mm][Aa][Ll]
CADENA_K            [Cc][Aa][Dd][Ee][Nn][Aa]
BOOLEANO_K          [Bb][Oo][Oo][Ll][Ee][Aa][Nn][Oo]
IMPRIMIR_K          [Ii][Mm][Pp][Rr][Ii][Mm][Ii][Rr]
SI_K                [Ss][Ii]
SINO_K              [Ss][Ii][Nn][Oo]
MIENTRAS_K          [Mm][Ii][Ee][Nn][Tt][Rr][Aa][Ss]
PARA_K              [Pp][Aa][Rr][Aa]
HASTA_K             [Hh][Aa][Ss][Tt][Aa]
ROMPER_K            [Rr][Oo][Mm][Pp][Ee][Rr]
CONTINUAR_K         [Cc][Oo][Nn][Tt][Ii][Nn][Uu][Aa][Rr]
VERDADERO_K         [Vv][Ee][Rr][Dd][Aa][Dd][Ee][Rr][Oo]
FALSO_K             [Ff][Aa][Ll][Ss][Oo]
Y_K                 [Yy]
O_K                 [Oo]
NO_K                [Nn][Oo]
PUNTO_PUNTO_K       \.\.
PUNTO_K             \.
DECIMAL_LIT         [0-9]+\.[0-9]+
ENTERO_LIT          [0-9]+
IDENTIFICADOR_L     [A-Za-z_][A-Za-z0-9_]*
CADENA_LIT          \"([^\\\"\n]|\\.)*\"
NOMBRE_ARG          [^ \t\r\n]+

%%
<INITIAL>{WS}                    ;
<INITIAL>{AYUDA_K}               return AYUDA;
<INITIAL>{VERSION_K}             return VERSION;
<INITIAL>{SALIR_K}               return SALIR;
<INITIAL>{LIMPIAR_K}             return LIMPIAR;
<INITIAL>{FECHA_K}               return FECHA;
<INITIAL>{HORA_K}                return HORA;
<INITIAL>{LISTAR_K}              return LISTAR;
<INITIAL>{ECO_K}                 { BEGIN(ESTADO_TEXTO); return ECO; }
<INITIAL>{PAUSA_K}               return PAUSA;
<INITIAL>{TITULO_K}              { BEGIN(ESTADO_TEXTO); return TITULO; }
<INITIAL>{COLOR_K}               { BEGIN(ESTADO_COLOR); return COLOR; }
<INITIAL>{ARBOL_K}               return ARBOL;
<INITIAL>{BUSCAR_TEXTO_K}        { BEGIN(ESTADO_NOMBRE); return BUSCAR_TEXTO; }
<INITIAL>{BUSCAR_K}              { BEGIN(ESTADO_NOMBRE); return BUSCAR; }
<INITIAL>{MAS_K}                 { BEGIN(ESTADO_NOMBRE); return MAS; }
<INITIAL>{ORDENAR_K}             { BEGIN(ESTADO_NOMBRE); return ORDENAR; }
<INITIAL>{COMPARAR_K}            { BEGIN(ESTADO_NOMBRE); return COMPARAR; }
<INITIAL>{SIMBOLO_K}             { BEGIN(ESTADO_TEXTO); return SIMBOLO; }
<INITIAL>{RUTA_K}                { BEGIN(ESTADO_TEXTO); return RUTA; }
<INITIAL>{DEFINIR_K}             { BEGIN(ESTADO_TEXTO); return DEFINIR; }
<INITIAL>{CAMBIAR_DIR_K}         { BEGIN(ESTADO_NOMBRE); return CAMBIAR_DIR; }
<INITIAL>{CREAR_DIR_K}           { BEGIN(ESTADO_NOMBRE); return CREAR_DIR; }
<INITIAL>{ELIMINAR_DIR_K}        { BEGIN(ESTADO_NOMBRE); return ELIMINAR_DIR; }
<INITIAL>{MOSTRAR_K}             { BEGIN(ESTADO_NOMBRE); return MOSTRAR; }
<INITIAL>{ELIMINAR_K}            { BEGIN(ESTADO_NOMBRE); return ELIMINAR; }
<INITIAL>{RENOMBRAR_K}           { BEGIN(ESTADO_NOMBRE); return RENOMBRAR; }
<INITIAL>{COPIAR_K}              { BEGIN(ESTADO_NOMBRE); return COPIAR; }
<INITIAL>{MOVER_K}               { BEGIN(ESTADO_NOMBRE); return MOVER; }
<INITIAL>{VAR_K}                 return VAR;
<INITIAL>{ENTERO_K}              return TIPO_ENTERO;
<INITIAL>{DECIMAL_K}             return TIPO_DECIMAL;
<INITIAL>{CADENA_K}              return TIPO_CADENA;
<INITIAL>{BOOLEANO_K}            return TIPO_BOOLEANO;
<INITIAL>{IMPRIMIR_K}            return IMPRIMIR;
<INITIAL>{SINO_K}                return SINO;
<INITIAL>{SI_K}                  return SI;
<INITIAL>{MIENTRAS_K}            return MIENTRAS;
<INITIAL>{PARA_K}                return PARA;
<INITIAL>{HASTA_K}               return HASTA;
<INITIAL>{ROMPER_K}              return ROMPER;
<INITIAL>{CONTINUAR_K}           return CONTINUAR;
<INITIAL>{VERDADERO_K}           return VERDADERO;
<INITIAL>{FALSO_K}               return FALSO;
<INITIAL>{NO_K}                  return NO;
<INITIAL>{Y_K}                   return Y;
<INITIAL>{O_K}                   return O;
<INITIAL>"=="                    return IGUAL_IGUAL;
<INITIAL>"!="                    return DIFERENTE;
<INITIAL>"<="                    return MENOR_IGUAL;
<INITIAL>">="                    return MAYOR_IGUAL;
<INITIAL>{DECIMAL_LIT}           {
                            yylval.decimal = atof(yytext);
                            return LITERAL_DECIMAL;
                        }
<INITIAL>{ENTERO_LIT}            {
                            yylval.entero = atol(yytext);
                            return LITERAL_ENTERO;
                        }
<INITIAL>{CADENA_LIT}            {
                            yylval.texto = desescapar_cadena(yytext);
                            return LITERAL_CADENA;
                        }
<INITIAL>{IDENTIFICADOR_L}       {
                            yylval.texto = duplicar_texto(yytext);
                            return IDENTIFICADOR;
                        }
<INITIAL>";"                     return ';';
<INITIAL>"("                     return '(';
<INITIAL>")"                     return ')';
<INITIAL>"{"                     return '{';
<INITIAL>"}"                     return '}';
<INITIAL>"="                     return '=';
<INITIAL>"+"                     return '+';
<INITIAL>"-"                     return '-';
<INITIAL>"*"                     return '*';
<INITIAL>"/"                     return '/';
<INITIAL>"%"                     return '%';
<INITIAL>"<"                     return '<';
<INITIAL>">"                     return '>';

<ESTADO_TEXTO>{WS}               ;
<ESTADO_TEXTO>[^ \t\r\n][^\r\n]* {
                            yylval.texto = duplicar_texto(yytext);
                            BEGIN(INITIAL);
                            return TEXTO;
                        }

<ESTADO_COLOR>{WS}               ;
<ESTADO_COLOR>[^ \t\r\n][^\r\n]* {
                            yylval.texto = duplicar_texto(yytext);
                            BEGIN(INITIAL);
                            return TEXTO;
                        }

<ESTADO_NOMBRE>{WS}              ;
<ESTADO_NOMBRE>{PUNTO_PUNTO_K}   return PUNTO_PUNTO;
<ESTADO_NOMBRE>{PUNTO_K}         return PUNTO;
<ESTADO_NOMBRE>{NOMBRE_ARG}      {
                            yylval.texto = duplicar_texto(yytext);
                            return NOMBRE;
                        }

<INITIAL,ESTADO_TEXTO,ESTADO_COLOR,ESTADO_NOMBRE>\n {
                            BEGIN(INITIAL);
                            return NEWLINE;
                        }

<INITIAL>.                       {
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

static char *desescapar_cadena(const char *texto) {
    size_t longitud;
    size_t i;
    size_t j;
    char *resultado;

    longitud = strlen(texto);

    if (longitud < 2) {
        return duplicar_texto("");
    }

    resultado = (char *)malloc(longitud);

    if (resultado == NULL) {
        fprintf(stderr, "Error: memoria insuficiente.\n");
        exit(1);
    }

    j = 0;

    for (i = 1; i + 1 < longitud; ++i) {
        if (texto[i] == '\\' && i + 2 < longitud) {
            ++i;

            switch (texto[i]) {
                case 'n':
                    resultado[j++] = '\n';
                    break;
                case 't':
                    resultado[j++] = '\t';
                    break;
                case 'r':
                    resultado[j++] = '\r';
                    break;
                case '"':
                    resultado[j++] = '"';
                    break;
                case '\\':
                    resultado[j++] = '\\';
                    break;
                default:
                    resultado[j++] = texto[i];
                    break;
            }
        } else {
            resultado[j++] = texto[i];
        }
    }

    resultado[j] = '\0';
    return resultado;
}
