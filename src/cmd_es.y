%{
#include <stdio.h>
#include <stdlib.h>

int yylex(void);
void yyerror(const char *s);
extern int yylineno;
%}

%token AYUDA VERSION SALIR NEWLINE

/* Nota: Los comandos se reconocen sin diferenciar mayusculas/minusculas
   (ver %option caseless en el lexer). */

%start input

%%

input
    : /* vacio */
    | input linea
    ;

linea
    : instruccion NEWLINE
    | NEWLINE
    | error NEWLINE   /* recuperacion por linea */
    ;

instruccion
    : AYUDA      { printf("AYUDA: Comandos disponibles: AYUDA, VERSION, SALIR\n"); }
    | VERSION    { printf("CMD Espanol v0.1\n"); }
    | SALIR      { printf("Saliendo...\n"); exit(0); }
    ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Error sintactico (linea %d): %s\n", yylineno, s);
}

int main(void) {
    return yyparse();
}
