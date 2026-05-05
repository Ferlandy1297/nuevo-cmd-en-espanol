%{
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

int yylex(void);
void yyerror(const char *s);
extern int yylineno;

static void mostrar_ayuda(void);
static void limpiar_pantalla_simple(void);
static void mostrar_fecha_actual(void);
static void mostrar_hora_actual(void);
%}

%token AYUDA VERSION SALIR LIMPIAR FECHA HORA NEWLINE

/* Nota: Los comandos se reconocen sin diferenciar mayusculas/minusculas
   (ver reglas del lexer). */

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
    : AYUDA      { mostrar_ayuda(); }
    | VERSION    { printf("CMD Espanol v0.1\n"); }
    | SALIR      { printf("Saliendo...\n"); exit(0); }
    | LIMPIAR    { limpiar_pantalla_simple(); }
    | FECHA      { mostrar_fecha_actual(); }
    | HORA       { mostrar_hora_actual(); }
    ;

%%

static void mostrar_ayuda(void) {
    printf("AYUDA: Comandos disponibles: AYUDA, VERSION, FECHA, HORA, LIMPIAR, SALIR\n");
}

static void limpiar_pantalla_simple(void) {
    int i;

    for (i = 0; i < 20; ++i) {
        putchar('\n');
    }
}

static void mostrar_fecha_actual(void) {
    time_t ahora;
    struct tm *info_tiempo;
    char buffer[32];

    ahora = time(NULL);
    info_tiempo = localtime(&ahora);

    if (info_tiempo == NULL) {
        printf("No se pudo obtener la fecha actual.\n");
        return;
    }

    if (strftime(buffer, sizeof(buffer), "%d/%m/%Y", info_tiempo) == 0) {
        printf("No se pudo formatear la fecha actual.\n");
        return;
    }

    printf("%s\n", buffer);
}

static void mostrar_hora_actual(void) {
    time_t ahora;
    struct tm *info_tiempo;
    char buffer[32];

    ahora = time(NULL);
    info_tiempo = localtime(&ahora);

    if (info_tiempo == NULL) {
        printf("No se pudo obtener la hora actual.\n");
        return;
    }

    if (strftime(buffer, sizeof(buffer), "%H:%M:%S", info_tiempo) == 0) {
        printf("No se pudo formatear la hora actual.\n");
        return;
    }

    printf("%s\n", buffer);
}

void yyerror(const char *s) {
    fprintf(stderr, "Error sintactico (linea %d): %s\n", yylineno, s);
}

int main(void) {
    return yyparse();
}
