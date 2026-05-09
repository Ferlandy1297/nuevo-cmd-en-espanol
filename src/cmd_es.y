%{
#include <ctype.h>
#include <conio.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <errno.h>
#include <direct.h>
#include <windows.h>

int yylex(void);
void yyerror(const char *s);
extern int yylineno;
int cmd_es_linea_invalida;

#define CMD_ES_MAX_VARIABLES 32
#define CMD_ES_MAX_NOMBRE_VARIABLE 64
#define CMD_ES_MAX_VALOR_VARIABLE 256
#define CMD_ES_MAX_TEXTO_INTERNO MAX_PATH

typedef struct {
    int en_uso;
    char nombre[CMD_ES_MAX_NOMBRE_VARIABLE];
    char valor[CMD_ES_MAX_VALOR_VARIABLE];
} CmdEsVariableInterna;

static char cmd_es_simbolo_actual[CMD_ES_MAX_TEXTO_INTERNO] = "CMD-ES>";
static char cmd_es_ruta_actual[CMD_ES_MAX_TEXTO_INTERNO];
static int cmd_es_ruta_inicializada;
static CmdEsVariableInterna cmd_es_variables[CMD_ES_MAX_VARIABLES];

static void mostrar_ayuda(void);
static void inicializar_entorno_interno(void);
static void limpiar_pantalla_simple(void);
static void mostrar_fecha_actual(void);
static void mostrar_hora_actual(void);
static void listar_elementos(void);
static void eco_texto(const char *texto);
static void pausar_consola(void);
static void cambiar_titulo_consola(const char *texto);
static void cambiar_color_consola(const char *codigo);
static void mostrar_arbol_directorios(void);
static void cambiar_simbolo_interno(const char *texto);
static void mostrar_ruta_interna(void);
static void cambiar_ruta_interna(const char *texto);
static void manejar_definir(const char *texto);
static void mostrar_variables_internas(void);
static void mostrar_variable_interna(const char *nombre);
static void asignar_variable_interna(const char *texto);
static void buscar_en_archivo(const char *texto, const char *archivo, int ignorar_mayusculas);
static void mostrar_mas_simple(const char *archivo);
static void ordenar_archivo(const char *archivo);
static void comparar_archivos(const char *archivo1, const char *archivo2);
static void cambiar_directorio(const char *nombre);
static void crear_directorio(const char *nombre);
static void eliminar_directorio(const char *nombre);
static void mostrar_archivo(const char *nombre);
static void eliminar_archivo(const char *nombre);
static void renombrar_archivo(const char *origen, const char *destino);
static void copiar_archivo(const char *origen, const char *destino);
static void mover_archivo(const char *origen, const char *destino);
static void imprimir_arbol_directorio(const char *ruta, int nivel, int *hay_subdirectorios);
static void imprimir_sangria_arbol(int nivel);
static int copiar_texto_recortado(const char *texto, char *destino, size_t tamanio);
static int es_hexadecimal(char caracter);
static int valor_hexadecimal(char caracter);
static int abrir_archivo_simple(const char *nombre, const char *modo, FILE **archivo);
static int linea_contiene_texto(const char *linea, const char *texto, int ignorar_mayusculas);
static int contiene_texto_sin_mayusculas(const char *linea, const char *texto);
static int comparar_lineas_alfabetico(const void *izquierda, const void *derecha);
static int copiar_segmento_recortado(const char *inicio, const char *fin, char *destino, size_t tamanio);
static int guardar_texto_limitado(const char *origen, char *destino, size_t tamanio);
static int buscar_indice_variable(const char *nombre);
static int nombre_variable_valido(const char *nombre);
static char *duplicar_cadena_simple(const char *texto);
static void liberar_lineas_archivo(char **lineas, size_t cantidad);
static void mostrar_directorio_actual(void);
static const char *descripcion_error_operacion(int codigo_error);
static int numero_linea_comando(void);
static void reiniciar_estado_linea(void);
%}

%union {
    char *texto;
}

%token AYUDA VERSION SALIR LIMPIAR FECHA HORA
%token LISTAR ECO PAUSA TITULO COLOR ARBOL BUSCAR BUSCAR_TEXTO MAS ORDENAR COMPARAR SIMBOLO RUTA DEFINIR CAMBIAR_DIR CREAR_DIR ELIMINAR_DIR MOSTRAR ELIMINAR RENOMBRAR COPIAR MOVER
%token PUNTO PUNTO_PUNTO
%token NEWLINE
%token <texto> NOMBRE TEXTO

%destructor { free($$); } NOMBRE TEXTO

/* Nota: Los comandos se reconocen sin diferenciar mayusculas/minusculas
   (ver reglas del lexer). */

%start input

%%

input
    : /* vacio */
    | input linea
    ;

linea
    : AYUDA NEWLINE               { if (!cmd_es_linea_invalida) { mostrar_ayuda(); } reiniciar_estado_linea(); }
    | VERSION NEWLINE             { if (!cmd_es_linea_invalida) { printf("CMD Espanol v0.1\n"); } reiniciar_estado_linea(); }
    | SALIR NEWLINE               { if (!cmd_es_linea_invalida) { printf("Saliendo...\n"); exit(0); } reiniciar_estado_linea(); }
    | LIMPIAR NEWLINE             { if (!cmd_es_linea_invalida) { limpiar_pantalla_simple(); } reiniciar_estado_linea(); }
    | FECHA NEWLINE               { if (!cmd_es_linea_invalida) { mostrar_fecha_actual(); } reiniciar_estado_linea(); }
    | HORA NEWLINE                { if (!cmd_es_linea_invalida) { mostrar_hora_actual(); } reiniciar_estado_linea(); }
    | LISTAR NEWLINE              { if (!cmd_es_linea_invalida) { listar_elementos(); } reiniciar_estado_linea(); }
    | ECO TEXTO NEWLINE           { if (!cmd_es_linea_invalida) { eco_texto($2); } free($2); reiniciar_estado_linea(); }
    | PAUSA NEWLINE               { if (!cmd_es_linea_invalida) { pausar_consola(); } reiniciar_estado_linea(); }
    | TITULO TEXTO NEWLINE        { if (!cmd_es_linea_invalida) { cambiar_titulo_consola($2); } free($2); reiniciar_estado_linea(); }
    | COLOR TEXTO NEWLINE         { if (!cmd_es_linea_invalida) { cambiar_color_consola($2); } free($2); reiniciar_estado_linea(); }
    | ARBOL NEWLINE               { if (!cmd_es_linea_invalida) { mostrar_arbol_directorios(); } reiniciar_estado_linea(); }
    | SIMBOLO TEXTO NEWLINE       { if (!cmd_es_linea_invalida) { cambiar_simbolo_interno($2); } free($2); reiniciar_estado_linea(); }
    | RUTA NEWLINE                { if (!cmd_es_linea_invalida) { mostrar_ruta_interna(); } reiniciar_estado_linea(); }
    | RUTA TEXTO NEWLINE          { if (!cmd_es_linea_invalida) { cambiar_ruta_interna($2); } free($2); reiniciar_estado_linea(); }
    | DEFINIR NEWLINE             { if (!cmd_es_linea_invalida) { mostrar_variables_internas(); } reiniciar_estado_linea(); }
    | DEFINIR TEXTO NEWLINE       { if (!cmd_es_linea_invalida) { manejar_definir($2); } free($2); reiniciar_estado_linea(); }
    | BUSCAR NOMBRE NOMBRE NEWLINE { if (!cmd_es_linea_invalida) { buscar_en_archivo($2, $3, 0); } free($2); free($3); reiniciar_estado_linea(); }
    | BUSCAR_TEXTO NOMBRE NOMBRE NEWLINE { if (!cmd_es_linea_invalida) { buscar_en_archivo($2, $3, 1); } free($2); free($3); reiniciar_estado_linea(); }
    | MAS NOMBRE NEWLINE          { if (!cmd_es_linea_invalida) { mostrar_mas_simple($2); } free($2); reiniciar_estado_linea(); }
    | ORDENAR NOMBRE NEWLINE      { if (!cmd_es_linea_invalida) { ordenar_archivo($2); } free($2); reiniciar_estado_linea(); }
    | COMPARAR NOMBRE NOMBRE NEWLINE { if (!cmd_es_linea_invalida) { comparar_archivos($2, $3); } free($2); free($3); reiniciar_estado_linea(); }
    | CAMBIAR_DIR NOMBRE NEWLINE  { if (!cmd_es_linea_invalida) { cambiar_directorio($2); } free($2); reiniciar_estado_linea(); }
    | CAMBIAR_DIR PUNTO NEWLINE   { if (!cmd_es_linea_invalida) { cambiar_directorio("."); } reiniciar_estado_linea(); }
    | CAMBIAR_DIR PUNTO_PUNTO NEWLINE { if (!cmd_es_linea_invalida) { cambiar_directorio(".."); } reiniciar_estado_linea(); }
    | CREAR_DIR NOMBRE NEWLINE    { if (!cmd_es_linea_invalida) { crear_directorio($2); } free($2); reiniciar_estado_linea(); }
    | ELIMINAR_DIR NOMBRE NEWLINE { if (!cmd_es_linea_invalida) { eliminar_directorio($2); } free($2); reiniciar_estado_linea(); }
    | MOSTRAR NOMBRE NEWLINE      { if (!cmd_es_linea_invalida) { mostrar_archivo($2); } free($2); reiniciar_estado_linea(); }
    | ELIMINAR NOMBRE NEWLINE     { if (!cmd_es_linea_invalida) { eliminar_archivo($2); } free($2); reiniciar_estado_linea(); }
    | RENOMBRAR NOMBRE NOMBRE NEWLINE { if (!cmd_es_linea_invalida) { renombrar_archivo($2, $3); } free($2); free($3); reiniciar_estado_linea(); }
    | COPIAR NOMBRE NOMBRE NEWLINE { if (!cmd_es_linea_invalida) { copiar_archivo($2, $3); } free($2); free($3); reiniciar_estado_linea(); }
    | MOVER NOMBRE NOMBRE NEWLINE { if (!cmd_es_linea_invalida) { mover_archivo($2, $3); } free($2); free($3); reiniciar_estado_linea(); }
    | ECO NEWLINE                 { if (!cmd_es_linea_invalida) { fprintf(stderr, "Error sintactico (linea %d): ECO requiere un texto.\n", numero_linea_comando()); } reiniciar_estado_linea(); }
    | TITULO NEWLINE              { if (!cmd_es_linea_invalida) { fprintf(stderr, "Error sintactico (linea %d): TITULO requiere un texto.\n", numero_linea_comando()); } reiniciar_estado_linea(); }
    | COLOR NEWLINE               { if (!cmd_es_linea_invalida) { fprintf(stderr, "Error sintactico (linea %d): COLOR requiere un codigo.\n", numero_linea_comando()); } reiniciar_estado_linea(); }
    | SIMBOLO NEWLINE             { if (!cmd_es_linea_invalida) { fprintf(stderr, "Error sintactico (linea %d): SIMBOLO requiere un texto.\n", numero_linea_comando()); } reiniciar_estado_linea(); }
    | BUSCAR NEWLINE              { if (!cmd_es_linea_invalida) { fprintf(stderr, "Error sintactico (linea %d): BUSCAR requiere un texto y un archivo.\n", numero_linea_comando()); } reiniciar_estado_linea(); }
    | BUSCAR NOMBRE NEWLINE       { if (!cmd_es_linea_invalida) { fprintf(stderr, "Error sintactico (linea %d): BUSCAR requiere un texto y un archivo.\n", numero_linea_comando()); } free($2); reiniciar_estado_linea(); }
    | BUSCAR_TEXTO NEWLINE        { if (!cmd_es_linea_invalida) { fprintf(stderr, "Error sintactico (linea %d): BUSCAR_TEXTO requiere un texto y un archivo.\n", numero_linea_comando()); } reiniciar_estado_linea(); }
    | BUSCAR_TEXTO NOMBRE NEWLINE { if (!cmd_es_linea_invalida) { fprintf(stderr, "Error sintactico (linea %d): BUSCAR_TEXTO requiere un texto y un archivo.\n", numero_linea_comando()); } free($2); reiniciar_estado_linea(); }
    | MAS NEWLINE                 { if (!cmd_es_linea_invalida) { fprintf(stderr, "Error sintactico (linea %d): MAS requiere un archivo.\n", numero_linea_comando()); } reiniciar_estado_linea(); }
    | ORDENAR NEWLINE             { if (!cmd_es_linea_invalida) { fprintf(stderr, "Error sintactico (linea %d): ORDENAR requiere un archivo.\n", numero_linea_comando()); } reiniciar_estado_linea(); }
    | COMPARAR NEWLINE            { if (!cmd_es_linea_invalida) { fprintf(stderr, "Error sintactico (linea %d): COMPARAR requiere dos archivos.\n", numero_linea_comando()); } reiniciar_estado_linea(); }
    | COMPARAR NOMBRE NEWLINE     { if (!cmd_es_linea_invalida) { fprintf(stderr, "Error sintactico (linea %d): COMPARAR requiere dos archivos.\n", numero_linea_comando()); } free($2); reiniciar_estado_linea(); }
    | CAMBIAR_DIR NEWLINE         { if (!cmd_es_linea_invalida) { fprintf(stderr, "Error sintactico (linea %d): CAMBIAR_DIR requiere un nombre.\n", numero_linea_comando()); } reiniciar_estado_linea(); }
    | CREAR_DIR NEWLINE           { if (!cmd_es_linea_invalida) { fprintf(stderr, "Error sintactico (linea %d): CREAR_DIR requiere un nombre.\n", numero_linea_comando()); } reiniciar_estado_linea(); }
    | ELIMINAR_DIR NEWLINE        { if (!cmd_es_linea_invalida) { fprintf(stderr, "Error sintactico (linea %d): ELIMINAR_DIR requiere un nombre.\n", numero_linea_comando()); } reiniciar_estado_linea(); }
    | MOSTRAR NEWLINE             { if (!cmd_es_linea_invalida) { fprintf(stderr, "Error sintactico (linea %d): MOSTRAR requiere un nombre de archivo.\n", numero_linea_comando()); } reiniciar_estado_linea(); }
    | ELIMINAR NEWLINE            { if (!cmd_es_linea_invalida) { fprintf(stderr, "Error sintactico (linea %d): ELIMINAR requiere un nombre de archivo.\n", numero_linea_comando()); } reiniciar_estado_linea(); }
    | RENOMBRAR NEWLINE           { if (!cmd_es_linea_invalida) { fprintf(stderr, "Error sintactico (linea %d): RENOMBRAR requiere un nombre de origen y otro de destino.\n", numero_linea_comando()); } reiniciar_estado_linea(); }
    | RENOMBRAR NOMBRE NEWLINE    { if (!cmd_es_linea_invalida) { fprintf(stderr, "Error sintactico (linea %d): RENOMBRAR requiere un nombre de origen y otro de destino.\n", numero_linea_comando()); } free($2); reiniciar_estado_linea(); }
    | COPIAR NEWLINE              { if (!cmd_es_linea_invalida) { fprintf(stderr, "Error sintactico (linea %d): COPIAR requiere un nombre de origen y otro de destino.\n", numero_linea_comando()); } reiniciar_estado_linea(); }
    | COPIAR NOMBRE NEWLINE       { if (!cmd_es_linea_invalida) { fprintf(stderr, "Error sintactico (linea %d): COPIAR requiere un nombre de origen y otro de destino.\n", numero_linea_comando()); } free($2); reiniciar_estado_linea(); }
    | MOVER NEWLINE               { if (!cmd_es_linea_invalida) { fprintf(stderr, "Error sintactico (linea %d): MOVER requiere un nombre de origen y otro de destino.\n", numero_linea_comando()); } reiniciar_estado_linea(); }
    | MOVER NOMBRE NEWLINE        { if (!cmd_es_linea_invalida) { fprintf(stderr, "Error sintactico (linea %d): MOVER requiere un nombre de origen y otro de destino.\n", numero_linea_comando()); } free($2); reiniciar_estado_linea(); }
    | NEWLINE                     { reiniciar_estado_linea(); }
    | error NEWLINE               { reiniciar_estado_linea(); yyerrok; }
    ;
%%

static void mostrar_ayuda(void) {
    printf("AYUDA: Comandos disponibles: AYUDA, VERSION, FECHA, HORA, LIMPIAR, LISTAR, ECO <texto>, PAUSA, TITULO <texto>, COLOR <codigo>, ARBOL, BUSCAR <texto> <archivo>, BUSCAR_TEXTO <texto> <archivo>, MAS <archivo>, ORDENAR <archivo>, COMPARAR <archivo1> <archivo2>, SIMBOLO <texto>, RUTA [texto], DEFINIR [nombre | nombre=valor], CAMBIAR_DIR <nombre | . | ..>, CREAR_DIR <nombre>, ELIMINAR_DIR <nombre>, MOSTRAR <archivo>, ELIMINAR <archivo>, RENOMBRAR <origen> <destino>, COPIAR <origen> <destino>, MOVER <origen> <destino>, SALIR\n");
}

static void inicializar_entorno_interno(void) {
    if (cmd_es_ruta_inicializada) {
        return;
    }

    if (_getcwd(cmd_es_ruta_actual, sizeof(cmd_es_ruta_actual)) == NULL) {
        strcpy(cmd_es_ruta_actual, ".");
    }

    cmd_es_ruta_inicializada = 1;
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

static void listar_elementos(void) {
    WIN32_FIND_DATAA datos;
    HANDLE manejador;
    int hay_elementos;

    hay_elementos = 0;
    manejador = FindFirstFileA("*", &datos);

    if (manejador == INVALID_HANDLE_VALUE) {
        if (GetLastError() == ERROR_FILE_NOT_FOUND) {
            printf("No hay elementos en el directorio actual.\n");
        } else {
            printf("No se pudo listar el directorio actual.\n");
        }
        return;
    }

    do {
        if (strcmp(datos.cFileName, ".") == 0 || strcmp(datos.cFileName, "..") == 0) {
            continue;
        }

        if ((datos.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) != 0) {
            printf("[DIR] %s\n", datos.cFileName);
        } else {
            printf("[ARC] %s\n", datos.cFileName);
        }

        hay_elementos = 1;
    } while (FindNextFileA(manejador, &datos) != 0);

    FindClose(manejador);

    if (!hay_elementos) {
        printf("No hay elementos en el directorio actual.\n");
    }
}

static void eco_texto(const char *texto) {
    printf("%s\n", texto);
}

static void pausar_consola(void) {
    printf("Presione una tecla para continuar...");
    fflush(stdout);
    _getch();
    putchar('\n');
}

static void cambiar_titulo_consola(const char *texto) {
    if (SetConsoleTitleA(texto) == 0) {
        printf("No se pudo cambiar el titulo de la consola.\n");
    }
}

static void cambiar_color_consola(const char *codigo) {
    char codigo_limpio[16];
    int fondo;
    int texto_color;
    HANDLE salida;
    int cerrar_salida;

    if (!copiar_texto_recortado(codigo, codigo_limpio, sizeof(codigo_limpio))) {
        printf("Codigo de COLOR invalido. Use dos digitos hexadecimales, por ejemplo 0A.\n");
        return;
    }

    if (strlen(codigo_limpio) != 2 || !es_hexadecimal(codigo_limpio[0]) || !es_hexadecimal(codigo_limpio[1])) {
        printf("Codigo de COLOR invalido. Use dos digitos hexadecimales, por ejemplo 0A.\n");
        return;
    }

    fondo = valor_hexadecimal(codigo_limpio[0]);
    texto_color = valor_hexadecimal(codigo_limpio[1]);

    if (fondo == texto_color) {
        printf("Codigo de COLOR invalido: fondo y texto no deben ser iguales.\n");
        return;
    }

    salida = CreateFileA(
        "CONOUT$",
        GENERIC_READ | GENERIC_WRITE,
        FILE_SHARE_READ | FILE_SHARE_WRITE,
        NULL,
        OPEN_EXISTING,
        0,
        NULL
    );
    cerrar_salida = 0;

    if (salida != INVALID_HANDLE_VALUE) {
        cerrar_salida = 1;
    } else {
        salida = GetStdHandle(STD_OUTPUT_HANDLE);
    }

    if (salida == NULL || salida == INVALID_HANDLE_VALUE) {
        printf("No se pudo cambiar el color de la consola.\n");
        return;
    }

    if (SetConsoleTextAttribute(salida, (WORD)((fondo << 4) | texto_color)) == 0) {
        printf("No se pudo cambiar el color de la consola.\n");
    }

    if (cerrar_salida) {
        CloseHandle(salida);
    }
}

static void mostrar_arbol_directorios(void) {
    char directorio_actual[MAX_PATH];
    int hay_subdirectorios;

    if (_getcwd(directorio_actual, sizeof(directorio_actual)) == NULL) {
        printf("No se pudo obtener el directorio actual.\n");
        return;
    }

    printf("%s\n", directorio_actual);
    hay_subdirectorios = 0;
    imprimir_arbol_directorio(directorio_actual, 0, &hay_subdirectorios);

    if (!hay_subdirectorios) {
        printf("No hay subdirectorios en el directorio actual.\n");
    }
}

static void cambiar_simbolo_interno(const char *texto) {
    char simbolo[CMD_ES_MAX_TEXTO_INTERNO];

    if (!copiar_texto_recortado(texto, simbolo, sizeof(simbolo)) || simbolo[0] == '\0') {
        printf("No se pudo actualizar el simbolo interno.\n");
        return;
    }

    if (!guardar_texto_limitado(simbolo, cmd_es_simbolo_actual, sizeof(cmd_es_simbolo_actual))) {
        printf("No se pudo actualizar el simbolo interno.\n");
        return;
    }

    printf("Simbolo interno actualizado: %s\n", cmd_es_simbolo_actual);
}

static void mostrar_ruta_interna(void) {
    inicializar_entorno_interno();
    printf("Ruta interna actual: %s\n", cmd_es_ruta_actual);
}

static void cambiar_ruta_interna(const char *texto) {
    char ruta[CMD_ES_MAX_TEXTO_INTERNO];

    if (!copiar_texto_recortado(texto, ruta, sizeof(ruta)) || ruta[0] == '\0') {
        printf("No se pudo actualizar la ruta interna.\n");
        return;
    }

    if (!guardar_texto_limitado(ruta, cmd_es_ruta_actual, sizeof(cmd_es_ruta_actual))) {
        printf("No se pudo actualizar la ruta interna.\n");
        return;
    }

    cmd_es_ruta_inicializada = 1;
    printf("Ruta interna actualizada: %s\n", cmd_es_ruta_actual);
}

static void manejar_definir(const char *texto) {
    char expresion[CMD_ES_MAX_TEXTO_INTERNO];

    if (!copiar_texto_recortado(texto, expresion, sizeof(expresion)) || expresion[0] == '\0') {
        mostrar_variables_internas();
        return;
    }

    if (strchr(expresion, '=') != NULL) {
        asignar_variable_interna(expresion);
    } else {
        mostrar_variable_interna(expresion);
    }
}

static void mostrar_variables_internas(void) {
    int i;
    int hay_variables;

    hay_variables = 0;

    for (i = 0; i < CMD_ES_MAX_VARIABLES; ++i) {
        if (!cmd_es_variables[i].en_uso) {
            continue;
        }

        if (!hay_variables) {
            printf("Variables internas definidas:\n");
            hay_variables = 1;
        }

        printf("%s = %s\n", cmd_es_variables[i].nombre, cmd_es_variables[i].valor);
    }

    if (!hay_variables) {
        printf("No hay variables internas definidas.\n");
    }
}

static void mostrar_variable_interna(const char *nombre) {
    char nombre_limpio[CMD_ES_MAX_NOMBRE_VARIABLE];
    int indice;

    if (!copiar_texto_recortado(nombre, nombre_limpio, sizeof(nombre_limpio)) || nombre_limpio[0] == '\0') {
        printf("Nombre de variable invalido.\n");
        return;
    }

    if (!nombre_variable_valido(nombre_limpio)) {
        printf("Nombre de variable invalido: %s\n", nombre_limpio);
        return;
    }

    indice = buscar_indice_variable(nombre_limpio);

    if (indice < 0) {
        printf("Variable no definida: %s\n", nombre_limpio);
        return;
    }

    printf("%s = %s\n", cmd_es_variables[indice].nombre, cmd_es_variables[indice].valor);
}

static void asignar_variable_interna(const char *texto) {
    const char *igual;
    char nombre[CMD_ES_MAX_NOMBRE_VARIABLE];
    char valor[CMD_ES_MAX_VALOR_VARIABLE];
    int indice;
    int i;

    igual = strchr(texto, '=');

    if (igual == NULL) {
        printf("Expresion de DEFINIR invalida.\n");
        return;
    }

    if (!copiar_segmento_recortado(texto, igual, nombre, sizeof(nombre)) || nombre[0] == '\0') {
        printf("Nombre de variable invalido.\n");
        return;
    }

    if (!copiar_segmento_recortado(igual + 1, texto + strlen(texto), valor, sizeof(valor))) {
        printf("Valor de variable demasiado largo.\n");
        return;
    }

    if (!nombre_variable_valido(nombre)) {
        printf("Nombre de variable invalido: %s\n", nombre);
        return;
    }

    indice = buscar_indice_variable(nombre);

    if (indice < 0) {
        for (i = 0; i < CMD_ES_MAX_VARIABLES; ++i) {
            if (!cmd_es_variables[i].en_uso) {
                indice = i;
                break;
            }
        }
    }

    if (indice < 0 || indice >= CMD_ES_MAX_VARIABLES) {
        printf("No hay espacio para mas variables internas.\n");
        return;
    }

    if (!guardar_texto_limitado(nombre, cmd_es_variables[indice].nombre, sizeof(cmd_es_variables[indice].nombre))
        || !guardar_texto_limitado(valor, cmd_es_variables[indice].valor, sizeof(cmd_es_variables[indice].valor))) {
        printf("No se pudo guardar la variable interna.\n");
        return;
    }

    cmd_es_variables[indice].en_uso = 1;
    printf("Variable definida: %s = %s\n", cmd_es_variables[indice].nombre, cmd_es_variables[indice].valor);
}

static void buscar_en_archivo(const char *texto, const char *archivo, int ignorar_mayusculas) {
    FILE *manejador;
    char buffer[1024];
    int encontro;
    int numero_linea;

    if (!abrir_archivo_simple(archivo, "r", &manejador)) {
        return;
    }

    encontro = 0;
    numero_linea = 0;

    while (fgets(buffer, sizeof(buffer), manejador) != NULL) {
        size_t longitud;

        ++numero_linea;

        if (!linea_contiene_texto(buffer, texto, ignorar_mayusculas)) {
            continue;
        }

        longitud = strlen(buffer);
        printf("Linea %d: %s", numero_linea, buffer);

        if (longitud == 0 || buffer[longitud - 1] != '\n') {
            putchar('\n');
        }

        encontro = 1;
    }

    if (ferror(manejador)) {
        printf("No se pudo leer completamente el archivo '%s'.\n", archivo);
        fclose(manejador);
        return;
    }

    fclose(manejador);

    if (!encontro) {
        printf("No se encontraron coincidencias para '%s' en '%s'.\n", texto, archivo);
    }
}

static void mostrar_mas_simple(const char *archivo) {
    printf("MAS simple: mostrando contenido completo de '%s'.\n", archivo);
    mostrar_archivo(archivo);
}

static void ordenar_archivo(const char *archivo) {
    FILE *manejador;
    char **lineas;
    char buffer[1024];
    size_t cantidad;
    size_t capacidad;

    if (!abrir_archivo_simple(archivo, "r", &manejador)) {
        return;
    }

    lineas = NULL;
    cantidad = 0;
    capacidad = 0;

    while (fgets(buffer, sizeof(buffer), manejador) != NULL) {
        if (cantidad == capacidad) {
            char **nuevas_lineas;
            size_t nueva_capacidad;

            nueva_capacidad = (capacidad == 0) ? 8 : capacidad * 2;
            nuevas_lineas = (char **)realloc(lineas, nueva_capacidad * sizeof(char *));

            if (nuevas_lineas == NULL) {
                printf("Error: memoria insuficiente.\n");
                liberar_lineas_archivo(lineas, cantidad);
                fclose(manejador);
                return;
            }

            lineas = nuevas_lineas;
            capacidad = nueva_capacidad;
        }

        lineas[cantidad] = duplicar_cadena_simple(buffer);
        ++cantidad;
    }

    if (ferror(manejador)) {
        printf("No se pudo leer completamente el archivo '%s'.\n", archivo);
        liberar_lineas_archivo(lineas, cantidad);
        fclose(manejador);
        return;
    }

    fclose(manejador);

    if (cantidad == 0) {
        printf("Archivo vacio.\n");
        free(lineas);
        return;
    }

    qsort(lineas, cantidad, sizeof(char *), comparar_lineas_alfabetico);
    printf("Contenido ordenado de '%s':\n", archivo);

    {
        size_t i;

        for (i = 0; i < cantidad; ++i) {
            size_t longitud;

            longitud = strlen(lineas[i]);
            printf("%s", lineas[i]);

            if (longitud == 0 || lineas[i][longitud - 1] != '\n') {
                putchar('\n');
            }
        }
    }

    liberar_lineas_archivo(lineas, cantidad);
}

static void comparar_archivos(const char *archivo1, const char *archivo2) {
    FILE *manejador1;
    FILE *manejador2;
    unsigned char buffer1[4096];
    unsigned char buffer2[4096];
    int son_iguales;

    if (!abrir_archivo_simple(archivo1, "rb", &manejador1)) {
        return;
    }

    if (!abrir_archivo_simple(archivo2, "rb", &manejador2)) {
        fclose(manejador1);
        return;
    }

    son_iguales = 1;

    for (;;) {
        size_t leidos1;
        size_t leidos2;

        leidos1 = fread(buffer1, 1, sizeof(buffer1), manejador1);
        leidos2 = fread(buffer2, 1, sizeof(buffer2), manejador2);

        if (leidos1 != leidos2) {
            son_iguales = 0;
            break;
        }

        if (leidos1 == 0) {
            break;
        }

        if (memcmp(buffer1, buffer2, leidos1) != 0) {
            son_iguales = 0;
            break;
        }
    }

    if (ferror(manejador1) || ferror(manejador2)) {
        printf("No se pudieron comparar completamente los archivos '%s' y '%s'.\n", archivo1, archivo2);
        fclose(manejador1);
        fclose(manejador2);
        return;
    }

    fclose(manejador1);
    fclose(manejador2);

    if (son_iguales) {
        printf("Los archivos '%s' y '%s' son iguales.\n", archivo1, archivo2);
    } else {
        printf("Los archivos '%s' y '%s' son diferentes.\n", archivo1, archivo2);
    }
}

static void cambiar_directorio(const char *nombre) {
    if (_chdir(nombre) != 0) {
        printf("No se pudo cambiar al directorio '%s': %s.\n", nombre, descripcion_error_operacion(errno));
        return;
    }

    mostrar_directorio_actual();
}

static void crear_directorio(const char *nombre) {
    if (_mkdir(nombre) != 0) {
        printf("No se pudo crear el directorio '%s': %s.\n", nombre, descripcion_error_operacion(errno));
        return;
    }

    printf("Directorio creado: %s\n", nombre);
}

static void eliminar_directorio(const char *nombre) {
    if (_rmdir(nombre) != 0) {
        printf("No se pudo eliminar el directorio '%s': %s.\n", nombre, descripcion_error_operacion(errno));
        return;
    }

    printf("Directorio eliminado: %s\n", nombre);
}

static void mostrar_archivo(const char *nombre) {
    DWORD atributos;
    FILE *archivo;
    char buffer[512];
    int archivo_vacio;
    int ultimo_fue_salto;

    atributos = GetFileAttributesA(nombre);

    if (atributos == INVALID_FILE_ATTRIBUTES) {
        printf("No se pudo mostrar el archivo '%s': no existe.\n", nombre);
        return;
    }

    if ((atributos & FILE_ATTRIBUTE_DIRECTORY) != 0) {
        printf("No se pudo mostrar '%s': es un directorio.\n", nombre);
        return;
    }

    archivo = fopen(nombre, "r");

    if (archivo == NULL) {
        printf("No se pudo abrir el archivo '%s': %s.\n", nombre, descripcion_error_operacion(errno));
        return;
    }

    archivo_vacio = 1;
    ultimo_fue_salto = 1;

    while (fgets(buffer, sizeof(buffer), archivo) != NULL) {
        size_t longitud;

        printf("%s", buffer);
        archivo_vacio = 0;
        longitud = strlen(buffer);

        if (longitud > 0 && buffer[longitud - 1] == '\n') {
            ultimo_fue_salto = 1;
        } else {
            ultimo_fue_salto = 0;
        }
    }

    if (ferror(archivo)) {
        printf("No se pudo leer completamente el archivo '%s'.\n", nombre);
        fclose(archivo);
        return;
    }

    fclose(archivo);

    if (archivo_vacio) {
        printf("Archivo vacio.\n");
    } else if (!ultimo_fue_salto) {
        putchar('\n');
    }
}

static void eliminar_archivo(const char *nombre) {
    DWORD atributos;

    atributos = GetFileAttributesA(nombre);

    if (atributos == INVALID_FILE_ATTRIBUTES) {
        printf("No se pudo eliminar el archivo '%s': no existe.\n", nombre);
        return;
    }

    if ((atributos & FILE_ATTRIBUTE_DIRECTORY) != 0) {
        printf("No se pudo eliminar '%s': es un directorio. Use ELIMINAR_DIR.\n", nombre);
        return;
    }

    if (remove(nombre) != 0) {
        printf("No se pudo eliminar el archivo '%s': %s.\n", nombre, descripcion_error_operacion(errno));
        return;
    }

    printf("Archivo eliminado: %s\n", nombre);
}

static void renombrar_archivo(const char *origen, const char *destino) {
    DWORD atributos_origen;
    DWORD atributos_destino;

    atributos_origen = GetFileAttributesA(origen);

    if (atributos_origen == INVALID_FILE_ATTRIBUTES) {
        printf("No se pudo renombrar '%s' a '%s': el origen no existe.\n", origen, destino);
        return;
    }

    if ((atributos_origen & FILE_ATTRIBUTE_DIRECTORY) != 0) {
        printf("No se pudo renombrar '%s': es un directorio.\n", origen);
        return;
    }

    atributos_destino = GetFileAttributesA(destino);

    if (atributos_destino != INVALID_FILE_ATTRIBUTES) {
        printf("No se pudo renombrar '%s' a '%s': el destino ya existe.\n", origen, destino);
        return;
    }

    if (rename(origen, destino) != 0) {
        printf("No se pudo renombrar el archivo '%s' a '%s': %s.\n", origen, destino, descripcion_error_operacion(errno));
        return;
    }

    printf("Archivo renombrado: %s -> %s\n", origen, destino);
}

static void copiar_archivo(const char *origen, const char *destino) {
    DWORD atributos_origen;
    DWORD atributos_destino;
    FILE *archivo_origen;
    FILE *archivo_destino;
    unsigned char buffer[4096];
    size_t bytes_leidos;

    atributos_origen = GetFileAttributesA(origen);

    if (atributos_origen == INVALID_FILE_ATTRIBUTES) {
        printf("No se pudo copiar '%s' a '%s': el origen no existe.\n", origen, destino);
        return;
    }

    if ((atributos_origen & FILE_ATTRIBUTE_DIRECTORY) != 0) {
        printf("No se pudo copiar '%s': es un directorio.\n", origen);
        return;
    }

    atributos_destino = GetFileAttributesA(destino);

    if (atributos_destino != INVALID_FILE_ATTRIBUTES) {
        printf("No se pudo copiar '%s' a '%s': el destino ya existe.\n", origen, destino);
        return;
    }

    archivo_origen = fopen(origen, "rb");

    if (archivo_origen == NULL) {
        printf("No se pudo abrir el archivo de origen '%s': %s.\n", origen, descripcion_error_operacion(errno));
        return;
    }

    archivo_destino = fopen(destino, "wb");

    if (archivo_destino == NULL) {
        printf("No se pudo crear el archivo de destino '%s': %s.\n", destino, descripcion_error_operacion(errno));
        fclose(archivo_origen);
        return;
    }

    while ((bytes_leidos = fread(buffer, 1, sizeof(buffer), archivo_origen)) > 0) {
        if (fwrite(buffer, 1, bytes_leidos, archivo_destino) != bytes_leidos) {
            int codigo_error;

            codigo_error = errno;
            printf("No se pudo escribir completamente el archivo '%s': %s.\n", destino, descripcion_error_operacion(codigo_error));
            fclose(archivo_origen);
            fclose(archivo_destino);
            remove(destino);
            return;
        }
    }

    if (ferror(archivo_origen)) {
        int codigo_error;

        codigo_error = errno;
        printf("No se pudo leer completamente el archivo '%s': %s.\n", origen, descripcion_error_operacion(codigo_error));
        fclose(archivo_origen);
        fclose(archivo_destino);
        remove(destino);
        return;
    }

    fclose(archivo_origen);

    if (fclose(archivo_destino) != 0) {
        int codigo_error;

        codigo_error = errno;
        printf("No se pudo finalizar la copia hacia '%s': %s.\n", destino, descripcion_error_operacion(codigo_error));
        remove(destino);
        return;
    }

    printf("Archivo copiado: %s -> %s\n", origen, destino);
}

static void mover_archivo(const char *origen, const char *destino) {
    DWORD atributos_origen;
    DWORD atributos_destino;

    atributos_origen = GetFileAttributesA(origen);

    if (atributos_origen == INVALID_FILE_ATTRIBUTES) {
        printf("No se pudo mover '%s' a '%s': el origen no existe.\n", origen, destino);
        return;
    }

    if ((atributos_origen & FILE_ATTRIBUTE_DIRECTORY) != 0) {
        printf("No se pudo mover '%s': es un directorio.\n", origen);
        return;
    }

    atributos_destino = GetFileAttributesA(destino);

    if (atributos_destino != INVALID_FILE_ATTRIBUTES) {
        printf("No se pudo mover '%s' a '%s': el destino ya existe.\n", origen, destino);
        return;
    }

    if (MoveFileA(origen, destino) == 0) {
        printf("No se pudo mover el archivo '%s' a '%s'.\n", origen, destino);
        return;
    }

    printf("Archivo movido: %s -> %s\n", origen, destino);
}

static void imprimir_arbol_directorio(const char *ruta, int nivel, int *hay_subdirectorios) {
    WIN32_FIND_DATAA datos;
    HANDLE manejador;
    char patron[MAX_PATH];
    size_t longitud_ruta;

    longitud_ruta = strlen(ruta);

    if (longitud_ruta + 3 >= sizeof(patron)) {
        if (nivel == 0) {
            printf("No se pudo generar el arbol: ruta demasiado larga.\n");
        }
        return;
    }

    strcpy(patron, ruta);

    if (longitud_ruta > 0 && ruta[longitud_ruta - 1] != '\\' && ruta[longitud_ruta - 1] != '/') {
        patron[longitud_ruta] = '\\';
        patron[longitud_ruta + 1] = '*';
        patron[longitud_ruta + 2] = '\0';
    } else {
        patron[longitud_ruta] = '*';
        patron[longitud_ruta + 1] = '\0';
    }

    manejador = FindFirstFileA(patron, &datos);

    if (manejador == INVALID_HANDLE_VALUE) {
        return;
    }

    do {
        char ruta_hija[MAX_PATH];
        size_t longitud_nombre;

        if (strcmp(datos.cFileName, ".") == 0 || strcmp(datos.cFileName, "..") == 0) {
            continue;
        }

        if ((datos.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) == 0) {
            continue;
        }

        *hay_subdirectorios = 1;
        imprimir_sangria_arbol(nivel);
        printf("+-- %s\n", datos.cFileName);

        longitud_nombre = strlen(datos.cFileName);

        if (longitud_ruta + longitud_nombre + 2 >= sizeof(ruta_hija)) {
            imprimir_sangria_arbol(nivel + 1);
            printf("+-- [ruta demasiado larga]\n");
            continue;
        }

        strcpy(ruta_hija, ruta);

        if (longitud_ruta > 0 && ruta[longitud_ruta - 1] != '\\' && ruta[longitud_ruta - 1] != '/') {
            ruta_hija[longitud_ruta] = '\\';
            ruta_hija[longitud_ruta + 1] = '\0';
        }

        strcat(ruta_hija, datos.cFileName);
        imprimir_arbol_directorio(ruta_hija, nivel + 1, hay_subdirectorios);
    } while (FindNextFileA(manejador, &datos) != 0);

    FindClose(manejador);
}

static void imprimir_sangria_arbol(int nivel) {
    int i;

    for (i = 0; i < nivel; ++i) {
        printf("|   ");
    }
}

static int copiar_texto_recortado(const char *texto, char *destino, size_t tamanio) {
    const char *inicio;
    const char *fin;
    size_t longitud;

    if (tamanio == 0) {
        return 0;
    }

    inicio = texto;

    while (*inicio == ' ' || *inicio == '\t' || *inicio == '\r') {
        ++inicio;
    }

    fin = inicio + strlen(inicio);

    while (fin > inicio && (fin[-1] == ' ' || fin[-1] == '\t' || fin[-1] == '\r')) {
        --fin;
    }

    longitud = (size_t)(fin - inicio);

    if (longitud >= tamanio) {
        return 0;
    }

    memcpy(destino, inicio, longitud);
    destino[longitud] = '\0';
    return 1;
}

static int es_hexadecimal(char caracter) {
    return (caracter >= '0' && caracter <= '9')
        || (caracter >= 'A' && caracter <= 'F')
        || (caracter >= 'a' && caracter <= 'f');
}

static int valor_hexadecimal(char caracter) {
    if (caracter >= '0' && caracter <= '9') {
        return caracter - '0';
    }

    caracter = (char)toupper((unsigned char)caracter);
    return caracter - 'A' + 10;
}

static int abrir_archivo_simple(const char *nombre, const char *modo, FILE **archivo) {
    DWORD atributos;

    *archivo = NULL;
    atributos = GetFileAttributesA(nombre);

    if (atributos == INVALID_FILE_ATTRIBUTES) {
        printf("No se pudo abrir el archivo '%s': no existe.\n", nombre);
        return 0;
    }

    if ((atributos & FILE_ATTRIBUTE_DIRECTORY) != 0) {
        printf("No se pudo abrir '%s': es un directorio.\n", nombre);
        return 0;
    }

    *archivo = fopen(nombre, modo);

    if (*archivo == NULL) {
        printf("No se pudo abrir el archivo '%s': %s.\n", nombre, descripcion_error_operacion(errno));
        return 0;
    }

    return 1;
}

static int linea_contiene_texto(const char *linea, const char *texto, int ignorar_mayusculas) {
    if (ignorar_mayusculas) {
        return contiene_texto_sin_mayusculas(linea, texto);
    }

    return strstr(linea, texto) != NULL;
}

static int contiene_texto_sin_mayusculas(const char *linea, const char *texto) {
    const char *inicio_linea;
    size_t longitud_texto;

    longitud_texto = strlen(texto);

    if (longitud_texto == 0) {
        return 1;
    }

    for (inicio_linea = linea; *inicio_linea != '\0'; ++inicio_linea) {
        size_t i;

        for (i = 0; i < longitud_texto; ++i) {
            if (inicio_linea[i] == '\0') {
                return 0;
            }

            if (tolower((unsigned char)inicio_linea[i]) != tolower((unsigned char)texto[i])) {
                break;
            }
        }

        if (i == longitud_texto) {
            return 1;
        }
    }

    return 0;
}

static int comparar_lineas_alfabetico(const void *izquierda, const void *derecha) {
    const char *linea_izquierda;
    const char *linea_derecha;

    linea_izquierda = *(const char * const *)izquierda;
    linea_derecha = *(const char * const *)derecha;
    return strcmp(linea_izquierda, linea_derecha);
}

static int copiar_segmento_recortado(const char *inicio, const char *fin, char *destino, size_t tamanio) {
    size_t longitud;

    if (tamanio == 0) {
        return 0;
    }

    while (inicio < fin && (*inicio == ' ' || *inicio == '\t' || *inicio == '\r')) {
        ++inicio;
    }

    while (fin > inicio && (fin[-1] == ' ' || fin[-1] == '\t' || fin[-1] == '\r')) {
        --fin;
    }

    longitud = (size_t)(fin - inicio);

    if (longitud >= tamanio) {
        return 0;
    }

    memcpy(destino, inicio, longitud);
    destino[longitud] = '\0';
    return 1;
}

static int guardar_texto_limitado(const char *origen, char *destino, size_t tamanio) {
    size_t longitud;

    longitud = strlen(origen);

    if (longitud >= tamanio) {
        return 0;
    }

    memcpy(destino, origen, longitud + 1);
    return 1;
}

static int buscar_indice_variable(const char *nombre) {
    int i;

    for (i = 0; i < CMD_ES_MAX_VARIABLES; ++i) {
        if (!cmd_es_variables[i].en_uso) {
            continue;
        }

        if (strcmp(cmd_es_variables[i].nombre, nombre) == 0) {
            return i;
        }
    }

    return -1;
}

static int nombre_variable_valido(const char *nombre) {
    size_t i;

    if (nombre[0] == '\0') {
        return 0;
    }

    if (!(isalpha((unsigned char)nombre[0]) || nombre[0] == '_')) {
        return 0;
    }

    for (i = 1; nombre[i] != '\0'; ++i) {
        if (!(isalnum((unsigned char)nombre[i]) || nombre[i] == '_')) {
            return 0;
        }
    }

    return 1;
}

static char *duplicar_cadena_simple(const char *texto) {
    size_t longitud;
    char *copia;

    longitud = strlen(texto) + 1;
    copia = (char *)malloc(longitud);

    if (copia == NULL) {
        printf("Error: memoria insuficiente.\n");
        exit(1);
    }

    memcpy(copia, texto, longitud);
    return copia;
}

static void liberar_lineas_archivo(char **lineas, size_t cantidad) {
    size_t i;

    for (i = 0; i < cantidad; ++i) {
        free(lineas[i]);
    }

    free(lineas);
}

static void mostrar_directorio_actual(void) {
    char buffer[MAX_PATH];

    if (_getcwd(buffer, sizeof(buffer)) == NULL) {
        printf("Se cambio el directorio, pero no se pudo obtener la ruta actual.\n");
        return;
    }

    printf("Directorio actual: %s\n", buffer);
}

static const char *descripcion_error_operacion(int codigo_error) {
    switch (codigo_error) {
        case EEXIST:
            return "ya existe";
        case ENOENT:
            return "no existe";
        case EACCES:
            return "acceso denegado";
#ifdef ENOTEMPTY
        case ENOTEMPTY:
            return "no esta vacio";
#endif
#ifdef EPERM
        case EPERM:
            return "operacion no permitida";
#endif
        default:
            return strerror(codigo_error);
    }
}

static int numero_linea_comando(void) {
    if (yylineno > 1) {
        return yylineno - 1;
    }

    return 1;
}

static void reiniciar_estado_linea(void) {
    cmd_es_linea_invalida = 0;
}

void yyerror(const char *s) {
    cmd_es_linea_invalida = 1;
    fprintf(stderr, "Error sintactico (linea %d): %s\n", yylineno, s);
}

int main(void) {
    inicializar_entorno_interno();
    return yyparse();
}
