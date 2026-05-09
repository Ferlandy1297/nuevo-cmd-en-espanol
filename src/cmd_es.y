%{
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

static void mostrar_ayuda(void);
static void limpiar_pantalla_simple(void);
static void mostrar_fecha_actual(void);
static void mostrar_hora_actual(void);
static void listar_directorios(void);
static void cambiar_directorio(const char *nombre);
static void crear_directorio(const char *nombre);
static void eliminar_directorio(const char *nombre);
static void mostrar_archivo(const char *nombre);
static void eliminar_archivo(const char *nombre);
static void renombrar_archivo(const char *origen, const char *destino);
static void mostrar_directorio_actual(void);
static const char *descripcion_error_operacion(int codigo_error);
static int numero_linea_comando(void);
static void reiniciar_estado_linea(void);
%}

%union {
    char *texto;
}

%token AYUDA VERSION SALIR LIMPIAR FECHA HORA
%token LISTAR CAMBIAR_DIR CREAR_DIR ELIMINAR_DIR MOSTRAR ELIMINAR RENOMBRAR
%token PUNTO PUNTO_PUNTO
%token NEWLINE
%token <texto> NOMBRE

%destructor { free($$); } NOMBRE

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
    | LISTAR NEWLINE              { if (!cmd_es_linea_invalida) { listar_directorios(); } reiniciar_estado_linea(); }
    | CAMBIAR_DIR NOMBRE NEWLINE  { if (!cmd_es_linea_invalida) { cambiar_directorio($2); } free($2); reiniciar_estado_linea(); }
    | CAMBIAR_DIR PUNTO NEWLINE   { if (!cmd_es_linea_invalida) { cambiar_directorio("."); } reiniciar_estado_linea(); }
    | CAMBIAR_DIR PUNTO_PUNTO NEWLINE { if (!cmd_es_linea_invalida) { cambiar_directorio(".."); } reiniciar_estado_linea(); }
    | CREAR_DIR NOMBRE NEWLINE    { if (!cmd_es_linea_invalida) { crear_directorio($2); } free($2); reiniciar_estado_linea(); }
    | ELIMINAR_DIR NOMBRE NEWLINE { if (!cmd_es_linea_invalida) { eliminar_directorio($2); } free($2); reiniciar_estado_linea(); }
    | MOSTRAR NOMBRE NEWLINE      { if (!cmd_es_linea_invalida) { mostrar_archivo($2); } free($2); reiniciar_estado_linea(); }
    | ELIMINAR NOMBRE NEWLINE     { if (!cmd_es_linea_invalida) { eliminar_archivo($2); } free($2); reiniciar_estado_linea(); }
    | RENOMBRAR NOMBRE NOMBRE NEWLINE { if (!cmd_es_linea_invalida) { renombrar_archivo($2, $3); } free($2); free($3); reiniciar_estado_linea(); }
    | CAMBIAR_DIR NEWLINE         { if (!cmd_es_linea_invalida) { fprintf(stderr, "Error sintactico (linea %d): CAMBIAR_DIR requiere un nombre.\n", numero_linea_comando()); } reiniciar_estado_linea(); }
    | CREAR_DIR NEWLINE           { if (!cmd_es_linea_invalida) { fprintf(stderr, "Error sintactico (linea %d): CREAR_DIR requiere un nombre.\n", numero_linea_comando()); } reiniciar_estado_linea(); }
    | ELIMINAR_DIR NEWLINE        { if (!cmd_es_linea_invalida) { fprintf(stderr, "Error sintactico (linea %d): ELIMINAR_DIR requiere un nombre.\n", numero_linea_comando()); } reiniciar_estado_linea(); }
    | MOSTRAR NEWLINE             { if (!cmd_es_linea_invalida) { fprintf(stderr, "Error sintactico (linea %d): MOSTRAR requiere un nombre de archivo.\n", numero_linea_comando()); } reiniciar_estado_linea(); }
    | ELIMINAR NEWLINE            { if (!cmd_es_linea_invalida) { fprintf(stderr, "Error sintactico (linea %d): ELIMINAR requiere un nombre de archivo.\n", numero_linea_comando()); } reiniciar_estado_linea(); }
    | RENOMBRAR NEWLINE           { if (!cmd_es_linea_invalida) { fprintf(stderr, "Error sintactico (linea %d): RENOMBRAR requiere un nombre de origen y otro de destino.\n", numero_linea_comando()); } reiniciar_estado_linea(); }
    | RENOMBRAR NOMBRE NEWLINE    { if (!cmd_es_linea_invalida) { fprintf(stderr, "Error sintactico (linea %d): RENOMBRAR requiere un nombre de origen y otro de destino.\n", numero_linea_comando()); } free($2); reiniciar_estado_linea(); }
    | NEWLINE                     { reiniciar_estado_linea(); }
    | error NEWLINE               { reiniciar_estado_linea(); yyerrok; }   /* recuperacion por linea */
    ;
%%

static void mostrar_ayuda(void) {
    printf("AYUDA: Comandos disponibles: AYUDA, VERSION, FECHA, HORA, LIMPIAR, LISTAR, CAMBIAR_DIR <nombre | . | ..>, CREAR_DIR <nombre>, ELIMINAR_DIR <nombre>, MOSTRAR <archivo>, ELIMINAR <archivo>, RENOMBRAR <origen> <destino>, SALIR\n");
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

static void listar_directorios(void) {
    WIN32_FIND_DATAA datos;
    HANDLE manejador;
    int encontrado;

    encontrado = 0;
    manejador = FindFirstFileA("*", &datos);

    if (manejador == INVALID_HANDLE_VALUE) {
        if (GetLastError() == ERROR_FILE_NOT_FOUND) {
            printf("No hay directorios en el directorio actual.\n");
        } else {
            printf("No se pudo listar el directorio actual.\n");
        }
        return;
    }

    do {
        if ((datos.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) != 0) {
            if (strcmp(datos.cFileName, ".") != 0 && strcmp(datos.cFileName, "..") != 0) {
                printf("%s/\n", datos.cFileName);
                encontrado = 1;
            }
        }
    } while (FindNextFileA(manejador, &datos) != 0);

    FindClose(manejador);

    if (!encontrado) {
        printf("No hay directorios en el directorio actual.\n");
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
    return yyparse();
}
