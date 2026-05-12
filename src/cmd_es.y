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
#define CMD_ES_MAX_VARIABLES_LENGUAJE 64
#define CMD_ES_MAX_NOMBRE_VARIABLE 64
#define CMD_ES_MAX_VALOR_VARIABLE 256
#define CMD_ES_MAX_TEXTO_INTERNO MAX_PATH

typedef enum {
    CMD_ES_TIPO_INVALIDO = 0,
    CMD_ES_TIPO_ENTERO,
    CMD_ES_TIPO_DECIMAL,
    CMD_ES_TIPO_CADENA,
    CMD_ES_TIPO_BOOLEANO
} CmdEsTipoDato;

typedef struct CmdEsValor {
    CmdEsTipoDato tipo;
    long entero;
    double decimal;
    int booleano;
    char *cadena;
} CmdEsValor;

typedef enum {
    CMD_ES_OPERADOR_SUMA = 1,
    CMD_ES_OPERADOR_RESTA,
    CMD_ES_OPERADOR_MULTIPLICACION,
    CMD_ES_OPERADOR_DIVISION,
    CMD_ES_OPERADOR_MODULO,
    CMD_ES_OPERADOR_IGUALDAD,
    CMD_ES_OPERADOR_DIFERENTE,
    CMD_ES_OPERADOR_MENOR,
    CMD_ES_OPERADOR_MAYOR,
    CMD_ES_OPERADOR_MENOR_IGUAL,
    CMD_ES_OPERADOR_MAYOR_IGUAL,
    CMD_ES_OPERADOR_Y,
    CMD_ES_OPERADOR_O,
    CMD_ES_OPERADOR_NO,
    CMD_ES_OPERADOR_NEGATIVO
} CmdEsOperador;

typedef enum {
    CMD_ES_EXPRESION_LITERAL = 1,
    CMD_ES_EXPRESION_IDENTIFICADOR,
    CMD_ES_EXPRESION_UNARIA,
    CMD_ES_EXPRESION_BINARIA
} CmdEsTipoExpresion;

typedef struct CmdEsExpresion {
    CmdEsTipoExpresion tipo_expresion;
    CmdEsTipoDato tipo_dato;
    CmdEsOperador operador;
    long entero;
    double decimal;
    int booleano;
    char *texto;
    struct CmdEsExpresion *izquierda;
    struct CmdEsExpresion *derecha;
} CmdEsExpresion;

typedef enum {
    CMD_ES_SENTENCIA_DECLARACION = 1,
    CMD_ES_SENTENCIA_ASIGNACION,
    CMD_ES_SENTENCIA_IMPRESION,
    CMD_ES_SENTENCIA_SI,
    CMD_ES_SENTENCIA_MIENTRAS,
    CMD_ES_SENTENCIA_PARA,
    CMD_ES_SENTENCIA_ROMPER,
    CMD_ES_SENTENCIA_CONTINUAR
} CmdEsTipoSentenciaLenguaje;

typedef struct CmdEsSentenciaLenguaje {
    CmdEsTipoSentenciaLenguaje tipo_sentencia;
    struct CmdEsSentenciaLenguaje *siguiente;
    CmdEsTipoDato tipo_dato;
    char *identificador;
    CmdEsExpresion *expresion_principal;
    CmdEsExpresion *expresion_secundaria;
    struct CmdEsSentenciaLenguaje *bloque_principal;
    struct CmdEsSentenciaLenguaje *bloque_secundario;
} CmdEsSentenciaLenguaje;

typedef enum {
    CMD_ES_RESULTADO_NORMAL = 0,
    CMD_ES_RESULTADO_ROMPER,
    CMD_ES_RESULTADO_CONTINUAR,
    CMD_ES_RESULTADO_ERROR
} CmdEsResultadoEjecucion;

typedef struct {
    int en_uso;
    char nombre[CMD_ES_MAX_NOMBRE_VARIABLE];
    char valor[CMD_ES_MAX_VALOR_VARIABLE];
} CmdEsVariableInterna;

typedef struct {
    int en_uso;
    char nombre[CMD_ES_MAX_NOMBRE_VARIABLE];
    CmdEsTipoDato tipo;
    CmdEsValor *valor;
} CmdEsVariableLenguaje;

static char cmd_es_simbolo_actual[CMD_ES_MAX_TEXTO_INTERNO] = "CMD-ES>";
static char cmd_es_ruta_actual[CMD_ES_MAX_TEXTO_INTERNO];
static int cmd_es_ruta_inicializada;
static CmdEsVariableInterna cmd_es_variables[CMD_ES_MAX_VARIABLES];
static CmdEsVariableLenguaje cmd_es_variables_lenguaje[CMD_ES_MAX_VARIABLES_LENGUAJE];

static void mostrar_ayuda(void);
static void inicializar_entorno_interno(void);
static CmdEsExpresion *crear_expresion_literal_entero(long numero);
static CmdEsExpresion *crear_expresion_literal_decimal(double numero);
static CmdEsExpresion *crear_expresion_literal_cadena(char *texto);
static CmdEsExpresion *crear_expresion_literal_booleana(int valor);
static CmdEsExpresion *crear_expresion_identificador(char *identificador);
static CmdEsExpresion *crear_expresion_unaria(CmdEsOperador operador, CmdEsExpresion *expresion);
static CmdEsExpresion *crear_expresion_binaria(CmdEsOperador operador, CmdEsExpresion *izquierda, CmdEsExpresion *derecha);
static void liberar_expresion(CmdEsExpresion *expresion);
static CmdEsValor *evaluar_expresion(const CmdEsExpresion *expresion);
static CmdEsSentenciaLenguaje *crear_sentencia_declaracion(int tipo_dato, char *identificador, CmdEsExpresion *expresion);
static CmdEsSentenciaLenguaje *crear_sentencia_asignacion(char *identificador, CmdEsExpresion *expresion);
static CmdEsSentenciaLenguaje *crear_sentencia_impresion(CmdEsExpresion *expresion);
static CmdEsSentenciaLenguaje *crear_sentencia_si(CmdEsExpresion *condicion, CmdEsSentenciaLenguaje *bloque_principal, CmdEsSentenciaLenguaje *bloque_secundario);
static CmdEsSentenciaLenguaje *crear_sentencia_mientras(CmdEsExpresion *condicion, CmdEsSentenciaLenguaje *bloque_principal);
static CmdEsSentenciaLenguaje *crear_sentencia_para(char *identificador, CmdEsExpresion *inicio, CmdEsExpresion *limite, CmdEsSentenciaLenguaje *bloque_principal);
static CmdEsSentenciaLenguaje *crear_sentencia_romper(void);
static CmdEsSentenciaLenguaje *crear_sentencia_continuar(void);
static CmdEsSentenciaLenguaje *anexar_sentencia(CmdEsSentenciaLenguaje *lista, CmdEsSentenciaLenguaje *sentencia);
static void liberar_sentencia_lenguaje(CmdEsSentenciaLenguaje *sentencia);
static int validar_sentencia_lenguaje(const CmdEsSentenciaLenguaje *sentencia, int profundidad_ciclo);
static CmdEsResultadoEjecucion ejecutar_sentencia_lenguaje(CmdEsSentenciaLenguaje *sentencia);
static CmdEsResultadoEjecucion ejecutar_sentencia_individual(CmdEsSentenciaLenguaje *sentencia);
static CmdEsValor *crear_valor_invalido(void);
static CmdEsValor *crear_valor_entero(long numero);
static CmdEsValor *crear_valor_decimal(double numero);
static CmdEsValor *crear_valor_cadena(const char *texto);
static CmdEsValor *crear_valor_booleano(int valor);
static CmdEsValor *crear_valor_por_defecto(CmdEsTipoDato tipo_dato);
static CmdEsValor *copiar_valor_lenguaje(const CmdEsValor *valor);
static void liberar_valor(CmdEsValor *valor);
static CmdEsValor *obtener_valor_identificador(const char *identificador);
static CmdEsValor *operar_suma(CmdEsValor *izquierda, CmdEsValor *derecha);
static CmdEsValor *operar_resta(CmdEsValor *izquierda, CmdEsValor *derecha);
static CmdEsValor *operar_multiplicacion(CmdEsValor *izquierda, CmdEsValor *derecha);
static CmdEsValor *operar_division(CmdEsValor *izquierda, CmdEsValor *derecha);
static CmdEsValor *operar_modulo(CmdEsValor *izquierda, CmdEsValor *derecha);
static CmdEsValor *operar_igualdad(CmdEsValor *izquierda, CmdEsValor *derecha, int es_igualdad);
static CmdEsValor *operar_comparacion(CmdEsValor *izquierda, CmdEsValor *derecha, const char *operador);
static CmdEsValor *operar_logico(CmdEsValor *izquierda, CmdEsValor *derecha, const char *operador);
static CmdEsValor *operar_negacion(CmdEsValor *valor);
static CmdEsValor *operar_negativo(CmdEsValor *valor);
static int buscar_indice_variable_lenguaje(const char *nombre);
static int guardar_variable_lenguaje(const char *nombre, CmdEsTipoDato tipo_dato, const CmdEsValor *valor);
static int asignar_variable_lenguaje(const char *nombre, const CmdEsValor *valor);
static int asignar_variable_control_para(const char *nombre, const CmdEsValor *valor);
static CmdEsValor *convertir_valor_a_tipo(CmdEsTipoDato tipo_dato, const CmdEsValor *valor, const char *identificador);
static const char *nombre_tipo_dato(CmdEsTipoDato tipo_dato);
static void imprimir_valor_lenguaje(const CmdEsValor *valor);
static int valor_es_numerico(const CmdEsValor *valor);
static double valor_a_decimal(const CmdEsValor *valor);
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
    long entero;
    double decimal;
    int tipo_dato;
    CmdEsExpresion *expresion;
    CmdEsSentenciaLenguaje *sentencia;
}

%token AYUDA VERSION SALIR LIMPIAR FECHA HORA
%token LISTAR ECO PAUSA TITULO COLOR ARBOL BUSCAR BUSCAR_TEXTO MAS ORDENAR COMPARAR SIMBOLO RUTA DEFINIR CAMBIAR_DIR CREAR_DIR ELIMINAR_DIR MOSTRAR ELIMINAR RENOMBRAR COPIAR MOVER
%token VAR TIPO_ENTERO TIPO_DECIMAL TIPO_CADENA TIPO_BOOLEANO IMPRIMIR SI SINO MIENTRAS PARA HASTA ROMPER CONTINUAR VERDADERO FALSO
%token IGUAL_IGUAL DIFERENTE MENOR_IGUAL MAYOR_IGUAL Y O NO
%token PUNTO PUNTO_PUNTO
%token NEWLINE
%token <texto> NOMBRE TEXTO IDENTIFICADOR LITERAL_CADENA
%token <entero> LITERAL_ENTERO
%token <decimal> LITERAL_DECIMAL

%type <tipo_dato> tipo_lenguaje
%type <expresion> expresion
%type <sentencia> sentencia_lenguaje sentencia_simple sentencia_control bloque lista_sentencias

%destructor { free($$); } NOMBRE TEXTO IDENTIFICADOR LITERAL_CADENA
%destructor { liberar_expresion($$); } expresion
%destructor { liberar_sentencia_lenguaje($$); } sentencia_lenguaje sentencia_simple sentencia_control bloque lista_sentencias

/* Nota: Los comandos se reconocen sin diferenciar mayusculas/minusculas
   (ver reglas del lexer). */

%left O
%left Y
%nonassoc SIN_SINO
%nonassoc SINO
%nonassoc IGUAL_IGUAL DIFERENTE '<' '>' MENOR_IGUAL MAYOR_IGUAL
%left '+' '-'
%left '*' '/' '%'
%right NO
%right UMINUS

%start input

%%

input
    : /* vacio */
    | input linea
    ;

linea
    : linea_shell
    | linea_lenguaje
    | NEWLINE                     { reiniciar_estado_linea(); }
    | error NEWLINE               { reiniciar_estado_linea(); yyerrok; }
    ;

linea_shell
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
    ;

linea_lenguaje
    : sentencia_lenguaje NEWLINE {
            if (!cmd_es_linea_invalida) {
                if (validar_sentencia_lenguaje($1, 0)) {
                    ejecutar_sentencia_lenguaje($1);
                }
            }
            liberar_sentencia_lenguaje($1);
            reiniciar_estado_linea();
        }
    | sentencia_simple NEWLINE {
            if (!cmd_es_linea_invalida) {
                fprintf(stderr, "Error sintactico (linea %d): falta ';' al final de la sentencia.\n", numero_linea_comando());
            }
            liberar_sentencia_lenguaje($1);
            reiniciar_estado_linea();
        }
    ;

sentencia_lenguaje
    : sentencia_simple ';'                       { $$ = $1; }
    | sentencia_control                          { $$ = $1; }
    ;

sentencia_simple
    : VAR tipo_lenguaje IDENTIFICADOR            { $$ = crear_sentencia_declaracion($2, $3, NULL); }
    | VAR tipo_lenguaje IDENTIFICADOR '=' expresion { $$ = crear_sentencia_declaracion($2, $3, $5); }
    | IDENTIFICADOR '=' expresion                { $$ = crear_sentencia_asignacion($1, $3); }
    | IMPRIMIR '(' expresion ')'                 { $$ = crear_sentencia_impresion($3); }
    | ROMPER                                     { $$ = crear_sentencia_romper(); }
    | CONTINUAR                                  { $$ = crear_sentencia_continuar(); }
    ;

sentencia_control
    : SI '(' expresion ')' bloque %prec SIN_SINO { $$ = crear_sentencia_si($3, $5, NULL); }
    | SI '(' expresion ')' bloque SINO bloque    { $$ = crear_sentencia_si($3, $5, $7); }
    | MIENTRAS '(' expresion ')' bloque          { $$ = crear_sentencia_mientras($3, $5); }
    | PARA IDENTIFICADOR '=' expresion HASTA expresion bloque { $$ = crear_sentencia_para($2, $4, $6, $7); }
    ;

bloque
    : '{' lista_sentencias '}'                   { $$ = $2; }
    ;

lista_sentencias
    : /* vacio */                                { $$ = NULL; }
    | lista_sentencias sentencia_lenguaje        { $$ = anexar_sentencia($1, $2); }
    ;

tipo_lenguaje
    : TIPO_ENTERO     { $$ = CMD_ES_TIPO_ENTERO; }
    | TIPO_DECIMAL    { $$ = CMD_ES_TIPO_DECIMAL; }
    | TIPO_CADENA     { $$ = CMD_ES_TIPO_CADENA; }
    | TIPO_BOOLEANO   { $$ = CMD_ES_TIPO_BOOLEANO; }
    ;

expresion
    : LITERAL_ENTERO               { $$ = crear_expresion_literal_entero($1); }
    | LITERAL_DECIMAL              { $$ = crear_expresion_literal_decimal($1); }
    | LITERAL_CADENA               { $$ = crear_expresion_literal_cadena($1); }
    | VERDADERO                    { $$ = crear_expresion_literal_booleana(1); }
    | FALSO                        { $$ = crear_expresion_literal_booleana(0); }
    | IDENTIFICADOR                { $$ = crear_expresion_identificador($1); }
    | '(' expresion ')'            { $$ = $2; }
    | '-' expresion %prec UMINUS   { $$ = crear_expresion_unaria(CMD_ES_OPERADOR_NEGATIVO, $2); }
    | NO expresion                 { $$ = crear_expresion_unaria(CMD_ES_OPERADOR_NO, $2); }
    | expresion '+' expresion      { $$ = crear_expresion_binaria(CMD_ES_OPERADOR_SUMA, $1, $3); }
    | expresion '-' expresion      { $$ = crear_expresion_binaria(CMD_ES_OPERADOR_RESTA, $1, $3); }
    | expresion '*' expresion      { $$ = crear_expresion_binaria(CMD_ES_OPERADOR_MULTIPLICACION, $1, $3); }
    | expresion '/' expresion      { $$ = crear_expresion_binaria(CMD_ES_OPERADOR_DIVISION, $1, $3); }
    | expresion '%' expresion      { $$ = crear_expresion_binaria(CMD_ES_OPERADOR_MODULO, $1, $3); }
    | expresion IGUAL_IGUAL expresion { $$ = crear_expresion_binaria(CMD_ES_OPERADOR_IGUALDAD, $1, $3); }
    | expresion DIFERENTE expresion { $$ = crear_expresion_binaria(CMD_ES_OPERADOR_DIFERENTE, $1, $3); }
    | expresion '<' expresion      { $$ = crear_expresion_binaria(CMD_ES_OPERADOR_MENOR, $1, $3); }
    | expresion '>' expresion      { $$ = crear_expresion_binaria(CMD_ES_OPERADOR_MAYOR, $1, $3); }
    | expresion MENOR_IGUAL expresion { $$ = crear_expresion_binaria(CMD_ES_OPERADOR_MENOR_IGUAL, $1, $3); }
    | expresion MAYOR_IGUAL expresion { $$ = crear_expresion_binaria(CMD_ES_OPERADOR_MAYOR_IGUAL, $1, $3); }
    | expresion Y expresion        { $$ = crear_expresion_binaria(CMD_ES_OPERADOR_Y, $1, $3); }
    | expresion O expresion        { $$ = crear_expresion_binaria(CMD_ES_OPERADOR_O, $1, $3); }
    ;
%%

static CmdEsValor *crear_valor_simple(CmdEsTipoDato tipo_dato) {
    CmdEsValor *valor;

    valor = (CmdEsValor *)malloc(sizeof(CmdEsValor));

    if (valor == NULL) {
        fprintf(stderr, "Error: memoria insuficiente.\n");
        exit(1);
    }

    valor->tipo = tipo_dato;
    valor->entero = 0;
    valor->decimal = 0.0;
    valor->booleano = 0;
    valor->cadena = NULL;
    return valor;
}

static CmdEsExpresion *crear_expresion_simple(CmdEsTipoExpresion tipo_expresion) {
    CmdEsExpresion *expresion;

    expresion = (CmdEsExpresion *)malloc(sizeof(CmdEsExpresion));

    if (expresion == NULL) {
        fprintf(stderr, "Error: memoria insuficiente.\n");
        exit(1);
    }

    expresion->tipo_expresion = tipo_expresion;
    expresion->tipo_dato = CMD_ES_TIPO_INVALIDO;
    expresion->operador = CMD_ES_OPERADOR_SUMA;
    expresion->entero = 0;
    expresion->decimal = 0.0;
    expresion->booleano = 0;
    expresion->texto = NULL;
    expresion->izquierda = NULL;
    expresion->derecha = NULL;
    return expresion;
}

static CmdEsExpresion *crear_expresion_literal_entero(long numero) {
    CmdEsExpresion *expresion;

    expresion = crear_expresion_simple(CMD_ES_EXPRESION_LITERAL);
    expresion->tipo_dato = CMD_ES_TIPO_ENTERO;
    expresion->entero = numero;
    return expresion;
}

static CmdEsExpresion *crear_expresion_literal_decimal(double numero) {
    CmdEsExpresion *expresion;

    expresion = crear_expresion_simple(CMD_ES_EXPRESION_LITERAL);
    expresion->tipo_dato = CMD_ES_TIPO_DECIMAL;
    expresion->decimal = numero;
    return expresion;
}

static CmdEsExpresion *crear_expresion_literal_cadena(char *texto) {
    CmdEsExpresion *expresion;

    expresion = crear_expresion_simple(CMD_ES_EXPRESION_LITERAL);
    expresion->tipo_dato = CMD_ES_TIPO_CADENA;
    expresion->texto = texto != NULL ? texto : duplicar_cadena_simple("");
    return expresion;
}

static CmdEsExpresion *crear_expresion_literal_booleana(int valor) {
    CmdEsExpresion *expresion;

    expresion = crear_expresion_simple(CMD_ES_EXPRESION_LITERAL);
    expresion->tipo_dato = CMD_ES_TIPO_BOOLEANO;
    expresion->booleano = valor ? 1 : 0;
    return expresion;
}

static CmdEsExpresion *crear_expresion_identificador(char *identificador) {
    CmdEsExpresion *expresion;

    expresion = crear_expresion_simple(CMD_ES_EXPRESION_IDENTIFICADOR);
    expresion->texto = identificador;
    return expresion;
}

static CmdEsExpresion *crear_expresion_unaria(CmdEsOperador operador, CmdEsExpresion *expresion_hija) {
    CmdEsExpresion *expresion;

    expresion = crear_expresion_simple(CMD_ES_EXPRESION_UNARIA);
    expresion->operador = operador;
    expresion->izquierda = expresion_hija;
    return expresion;
}

static CmdEsExpresion *crear_expresion_binaria(CmdEsOperador operador, CmdEsExpresion *izquierda, CmdEsExpresion *derecha) {
    CmdEsExpresion *expresion;

    expresion = crear_expresion_simple(CMD_ES_EXPRESION_BINARIA);
    expresion->operador = operador;
    expresion->izquierda = izquierda;
    expresion->derecha = derecha;
    return expresion;
}

static void liberar_expresion(CmdEsExpresion *expresion) {
    if (expresion == NULL) {
        return;
    }

    liberar_expresion(expresion->izquierda);
    liberar_expresion(expresion->derecha);
    free(expresion->texto);
    free(expresion);
}

static CmdEsValor *evaluar_expresion(const CmdEsExpresion *expresion) {
    CmdEsValor *izquierda;
    CmdEsValor *derecha;

    if (expresion == NULL) {
        return crear_valor_invalido();
    }

    switch (expresion->tipo_expresion) {
        case CMD_ES_EXPRESION_LITERAL:
            switch (expresion->tipo_dato) {
                case CMD_ES_TIPO_ENTERO:
                    return crear_valor_entero(expresion->entero);
                case CMD_ES_TIPO_DECIMAL:
                    return crear_valor_decimal(expresion->decimal);
                case CMD_ES_TIPO_CADENA:
                    return crear_valor_cadena(expresion->texto != NULL ? expresion->texto : "");
                case CMD_ES_TIPO_BOOLEANO:
                    return crear_valor_booleano(expresion->booleano);
                default:
                    return crear_valor_invalido();
            }
        case CMD_ES_EXPRESION_IDENTIFICADOR:
            return obtener_valor_identificador(expresion->texto != NULL ? expresion->texto : "");
        case CMD_ES_EXPRESION_UNARIA:
            izquierda = evaluar_expresion(expresion->izquierda);

            if (expresion->operador == CMD_ES_OPERADOR_NO) {
                return operar_negacion(izquierda);
            }

            if (expresion->operador == CMD_ES_OPERADOR_NEGATIVO) {
                return operar_negativo(izquierda);
            }

            liberar_valor(izquierda);
            return crear_valor_invalido();
        case CMD_ES_EXPRESION_BINARIA:
            izquierda = evaluar_expresion(expresion->izquierda);
            derecha = evaluar_expresion(expresion->derecha);

            switch (expresion->operador) {
                case CMD_ES_OPERADOR_SUMA:
                    return operar_suma(izquierda, derecha);
                case CMD_ES_OPERADOR_RESTA:
                    return operar_resta(izquierda, derecha);
                case CMD_ES_OPERADOR_MULTIPLICACION:
                    return operar_multiplicacion(izquierda, derecha);
                case CMD_ES_OPERADOR_DIVISION:
                    return operar_division(izquierda, derecha);
                case CMD_ES_OPERADOR_MODULO:
                    return operar_modulo(izquierda, derecha);
                case CMD_ES_OPERADOR_IGUALDAD:
                    return operar_igualdad(izquierda, derecha, 1);
                case CMD_ES_OPERADOR_DIFERENTE:
                    return operar_igualdad(izquierda, derecha, 0);
                case CMD_ES_OPERADOR_MENOR:
                    return operar_comparacion(izquierda, derecha, "<");
                case CMD_ES_OPERADOR_MAYOR:
                    return operar_comparacion(izquierda, derecha, ">");
                case CMD_ES_OPERADOR_MENOR_IGUAL:
                    return operar_comparacion(izquierda, derecha, "<=");
                case CMD_ES_OPERADOR_MAYOR_IGUAL:
                    return operar_comparacion(izquierda, derecha, ">=");
                case CMD_ES_OPERADOR_Y:
                    return operar_logico(izquierda, derecha, "Y");
                case CMD_ES_OPERADOR_O:
                    return operar_logico(izquierda, derecha, "O");
                default:
                    liberar_valor(izquierda);
                    liberar_valor(derecha);
                    return crear_valor_invalido();
            }
        default:
            return crear_valor_invalido();
    }
}

static CmdEsSentenciaLenguaje *crear_sentencia_simple(CmdEsTipoSentenciaLenguaje tipo_sentencia) {
    CmdEsSentenciaLenguaje *sentencia;

    sentencia = (CmdEsSentenciaLenguaje *)malloc(sizeof(CmdEsSentenciaLenguaje));

    if (sentencia == NULL) {
        fprintf(stderr, "Error: memoria insuficiente.\n");
        exit(1);
    }

    sentencia->tipo_sentencia = tipo_sentencia;
    sentencia->siguiente = NULL;
    sentencia->tipo_dato = CMD_ES_TIPO_INVALIDO;
    sentencia->identificador = NULL;
    sentencia->expresion_principal = NULL;
    sentencia->expresion_secundaria = NULL;
    sentencia->bloque_principal = NULL;
    sentencia->bloque_secundario = NULL;
    return sentencia;
}

static CmdEsSentenciaLenguaje *crear_sentencia_declaracion(int tipo_dato, char *identificador, CmdEsExpresion *expresion) {
    CmdEsSentenciaLenguaje *sentencia;

    sentencia = crear_sentencia_simple(CMD_ES_SENTENCIA_DECLARACION);
    sentencia->tipo_dato = (CmdEsTipoDato)tipo_dato;
    sentencia->identificador = identificador;
    sentencia->expresion_principal = expresion;
    return sentencia;
}

static CmdEsSentenciaLenguaje *crear_sentencia_asignacion(char *identificador, CmdEsExpresion *expresion) {
    CmdEsSentenciaLenguaje *sentencia;

    sentencia = crear_sentencia_simple(CMD_ES_SENTENCIA_ASIGNACION);
    sentencia->identificador = identificador;
    sentencia->expresion_principal = expresion;
    return sentencia;
}

static CmdEsSentenciaLenguaje *crear_sentencia_impresion(CmdEsExpresion *expresion) {
    CmdEsSentenciaLenguaje *sentencia;

    sentencia = crear_sentencia_simple(CMD_ES_SENTENCIA_IMPRESION);
    sentencia->expresion_principal = expresion;
    return sentencia;
}

static CmdEsSentenciaLenguaje *crear_sentencia_si(CmdEsExpresion *condicion, CmdEsSentenciaLenguaje *bloque_principal, CmdEsSentenciaLenguaje *bloque_secundario) {
    CmdEsSentenciaLenguaje *sentencia;

    sentencia = crear_sentencia_simple(CMD_ES_SENTENCIA_SI);
    sentencia->expresion_principal = condicion;
    sentencia->bloque_principal = bloque_principal;
    sentencia->bloque_secundario = bloque_secundario;
    return sentencia;
}

static CmdEsSentenciaLenguaje *crear_sentencia_mientras(CmdEsExpresion *condicion, CmdEsSentenciaLenguaje *bloque_principal) {
    CmdEsSentenciaLenguaje *sentencia;

    sentencia = crear_sentencia_simple(CMD_ES_SENTENCIA_MIENTRAS);
    sentencia->expresion_principal = condicion;
    sentencia->bloque_principal = bloque_principal;
    return sentencia;
}

static CmdEsSentenciaLenguaje *crear_sentencia_para(char *identificador, CmdEsExpresion *inicio, CmdEsExpresion *limite, CmdEsSentenciaLenguaje *bloque_principal) {
    CmdEsSentenciaLenguaje *sentencia;

    sentencia = crear_sentencia_simple(CMD_ES_SENTENCIA_PARA);
    sentencia->identificador = identificador;
    sentencia->expresion_principal = inicio;
    sentencia->expresion_secundaria = limite;
    sentencia->bloque_principal = bloque_principal;
    return sentencia;
}

static CmdEsSentenciaLenguaje *crear_sentencia_romper(void) {
    return crear_sentencia_simple(CMD_ES_SENTENCIA_ROMPER);
}

static CmdEsSentenciaLenguaje *crear_sentencia_continuar(void) {
    return crear_sentencia_simple(CMD_ES_SENTENCIA_CONTINUAR);
}

static CmdEsSentenciaLenguaje *anexar_sentencia(CmdEsSentenciaLenguaje *lista, CmdEsSentenciaLenguaje *sentencia) {
    CmdEsSentenciaLenguaje *actual;

    if (lista == NULL) {
        return sentencia;
    }

    actual = lista;

    while (actual->siguiente != NULL) {
        actual = actual->siguiente;
    }

    actual->siguiente = sentencia;
    return lista;
}

static void liberar_sentencia_lenguaje(CmdEsSentenciaLenguaje *sentencia) {
    while (sentencia != NULL) {
        CmdEsSentenciaLenguaje *siguiente;

        siguiente = sentencia->siguiente;
        free(sentencia->identificador);
        liberar_expresion(sentencia->expresion_principal);
        liberar_expresion(sentencia->expresion_secundaria);
        liberar_sentencia_lenguaje(sentencia->bloque_principal);
        liberar_sentencia_lenguaje(sentencia->bloque_secundario);
        free(sentencia);
        sentencia = siguiente;
    }
}

static int validar_sentencia_lenguaje(const CmdEsSentenciaLenguaje *sentencia, int profundidad_ciclo) {
    const CmdEsSentenciaLenguaje *actual;

    for (actual = sentencia; actual != NULL; actual = actual->siguiente) {
        switch (actual->tipo_sentencia) {
            case CMD_ES_SENTENCIA_SI:
                if (!validar_sentencia_lenguaje(actual->bloque_principal, profundidad_ciclo)) {
                    return 0;
                }

                if (!validar_sentencia_lenguaje(actual->bloque_secundario, profundidad_ciclo)) {
                    return 0;
                }
                break;
            case CMD_ES_SENTENCIA_MIENTRAS:
            case CMD_ES_SENTENCIA_PARA:
                if (!validar_sentencia_lenguaje(actual->bloque_principal, profundidad_ciclo + 1)) {
                    return 0;
                }
                break;
            case CMD_ES_SENTENCIA_ROMPER:
                if (profundidad_ciclo <= 0) {
                    cmd_es_linea_invalida = 1;
                    fprintf(stderr, "Error semantico (linea %d): ROMPER solo puede usarse dentro de un ciclo.\n", numero_linea_comando());
                    return 0;
                }
                break;
            case CMD_ES_SENTENCIA_CONTINUAR:
                if (profundidad_ciclo <= 0) {
                    cmd_es_linea_invalida = 1;
                    fprintf(stderr, "Error semantico (linea %d): CONTINUAR solo puede usarse dentro de un ciclo.\n", numero_linea_comando());
                    return 0;
                }
                break;
            default:
                break;
        }
    }

    return 1;
}

static CmdEsResultadoEjecucion ejecutar_sentencia_lenguaje(CmdEsSentenciaLenguaje *sentencia) {
    CmdEsSentenciaLenguaje *actual;

    for (actual = sentencia; actual != NULL; actual = actual->siguiente) {
        CmdEsResultadoEjecucion resultado;

        resultado = ejecutar_sentencia_individual(actual);

        if (resultado != CMD_ES_RESULTADO_NORMAL) {
            return resultado;
        }
    }

    return CMD_ES_RESULTADO_NORMAL;
}

static CmdEsResultadoEjecucion ejecutar_sentencia_individual(CmdEsSentenciaLenguaje *sentencia) {
    CmdEsValor *valor;
    CmdEsResultadoEjecucion resultado;

    if (sentencia == NULL) {
        return CMD_ES_RESULTADO_NORMAL;
    }

    switch (sentencia->tipo_sentencia) {
        case CMD_ES_SENTENCIA_DECLARACION:
            valor = NULL;

            if (sentencia->expresion_principal != NULL) {
                valor = evaluar_expresion(sentencia->expresion_principal);

                if (valor == NULL || valor->tipo == CMD_ES_TIPO_INVALIDO) {
                    liberar_valor(valor);
                    return CMD_ES_RESULTADO_ERROR;
                }
            }

            if (!guardar_variable_lenguaje(sentencia->identificador, sentencia->tipo_dato, valor)) {
                liberar_valor(valor);
                return CMD_ES_RESULTADO_ERROR;
            }

            liberar_valor(valor);
            return CMD_ES_RESULTADO_NORMAL;
        case CMD_ES_SENTENCIA_ASIGNACION:
            valor = evaluar_expresion(sentencia->expresion_principal);

            if (valor == NULL || valor->tipo == CMD_ES_TIPO_INVALIDO) {
                liberar_valor(valor);
                return CMD_ES_RESULTADO_ERROR;
            }

            if (!asignar_variable_lenguaje(sentencia->identificador, valor)) {
                liberar_valor(valor);
                return CMD_ES_RESULTADO_ERROR;
            }

            liberar_valor(valor);
            return CMD_ES_RESULTADO_NORMAL;
        case CMD_ES_SENTENCIA_IMPRESION:
            valor = evaluar_expresion(sentencia->expresion_principal);

            if (valor == NULL || valor->tipo == CMD_ES_TIPO_INVALIDO) {
                liberar_valor(valor);
                return CMD_ES_RESULTADO_ERROR;
            }

            imprimir_valor_lenguaje(valor);
            liberar_valor(valor);
            return CMD_ES_RESULTADO_NORMAL;
        case CMD_ES_SENTENCIA_SI:
            valor = evaluar_expresion(sentencia->expresion_principal);

            if (valor == NULL || valor->tipo == CMD_ES_TIPO_INVALIDO) {
                liberar_valor(valor);
                return CMD_ES_RESULTADO_ERROR;
            }

            if (valor->tipo != CMD_ES_TIPO_BOOLEANO) {
                cmd_es_linea_invalida = 1;
                fprintf(stderr, "Error semantico (linea %d): la condicion de SI debe ser booleana.\n", numero_linea_comando());
                liberar_valor(valor);
                return CMD_ES_RESULTADO_ERROR;
            }

            resultado = valor->booleano
                ? ejecutar_sentencia_lenguaje(sentencia->bloque_principal)
                : ejecutar_sentencia_lenguaje(sentencia->bloque_secundario);
            liberar_valor(valor);
            return resultado;
        case CMD_ES_SENTENCIA_MIENTRAS:
            while (1) {
                valor = evaluar_expresion(sentencia->expresion_principal);

                if (valor == NULL || valor->tipo == CMD_ES_TIPO_INVALIDO) {
                    liberar_valor(valor);
                    return CMD_ES_RESULTADO_ERROR;
                }

                if (valor->tipo != CMD_ES_TIPO_BOOLEANO) {
                    cmd_es_linea_invalida = 1;
                    fprintf(stderr, "Error semantico (linea %d): la condicion de MIENTRAS debe ser booleana.\n", numero_linea_comando());
                    liberar_valor(valor);
                    return CMD_ES_RESULTADO_ERROR;
                }

                if (!valor->booleano) {
                    liberar_valor(valor);
                    break;
                }

                liberar_valor(valor);
                resultado = ejecutar_sentencia_lenguaje(sentencia->bloque_principal);

                if (resultado == CMD_ES_RESULTADO_ERROR) {
                    return CMD_ES_RESULTADO_ERROR;
                }

                if (resultado == CMD_ES_RESULTADO_ROMPER) {
                    break;
                }
            }

            return CMD_ES_RESULTADO_NORMAL;
        case CMD_ES_SENTENCIA_PARA: {
            CmdEsValor *inicio;
            CmdEsValor *limite;

            inicio = evaluar_expresion(sentencia->expresion_principal);
            limite = evaluar_expresion(sentencia->expresion_secundaria);

            if (inicio == NULL || limite == NULL || inicio->tipo == CMD_ES_TIPO_INVALIDO || limite->tipo == CMD_ES_TIPO_INVALIDO) {
                liberar_valor(inicio);
                liberar_valor(limite);
                return CMD_ES_RESULTADO_ERROR;
            }

            if (!valor_es_numerico(inicio) || !valor_es_numerico(limite)) {
                cmd_es_linea_invalida = 1;
                fprintf(stderr, "Error semantico (linea %d): PARA requiere valores numericos de inicio y limite.\n", numero_linea_comando());
                liberar_valor(inicio);
                liberar_valor(limite);
                return CMD_ES_RESULTADO_ERROR;
            }

            if (inicio->tipo == CMD_ES_TIPO_DECIMAL || limite->tipo == CMD_ES_TIPO_DECIMAL) {
                double actual;
                double ultimo;
                double paso;

                actual = valor_a_decimal(inicio);
                ultimo = valor_a_decimal(limite);
                paso = actual <= ultimo ? 1.0 : -1.0;

                while ((paso > 0.0 && actual <= ultimo) || (paso < 0.0 && actual >= ultimo)) {
                    CmdEsValor *iteracion;

                    iteracion = crear_valor_decimal(actual);

                    if (!asignar_variable_control_para(sentencia->identificador, iteracion)) {
                        liberar_valor(iteracion);
                        liberar_valor(inicio);
                        liberar_valor(limite);
                        return CMD_ES_RESULTADO_ERROR;
                    }

                    liberar_valor(iteracion);
                    resultado = ejecutar_sentencia_lenguaje(sentencia->bloque_principal);

                    if (resultado == CMD_ES_RESULTADO_ERROR) {
                        liberar_valor(inicio);
                        liberar_valor(limite);
                        return CMD_ES_RESULTADO_ERROR;
                    }

                    if (resultado == CMD_ES_RESULTADO_ROMPER) {
                        break;
                    }

                    actual += paso;
                }
            } else {
                long actual;
                long ultimo;
                long paso;

                actual = inicio->entero;
                ultimo = limite->entero;
                paso = actual <= ultimo ? 1L : -1L;

                while ((paso > 0 && actual <= ultimo) || (paso < 0 && actual >= ultimo)) {
                    CmdEsValor *iteracion;

                    iteracion = crear_valor_entero(actual);

                    if (!asignar_variable_control_para(sentencia->identificador, iteracion)) {
                        liberar_valor(iteracion);
                        liberar_valor(inicio);
                        liberar_valor(limite);
                        return CMD_ES_RESULTADO_ERROR;
                    }

                    liberar_valor(iteracion);
                    resultado = ejecutar_sentencia_lenguaje(sentencia->bloque_principal);

                    if (resultado == CMD_ES_RESULTADO_ERROR) {
                        liberar_valor(inicio);
                        liberar_valor(limite);
                        return CMD_ES_RESULTADO_ERROR;
                    }

                    if (resultado == CMD_ES_RESULTADO_ROMPER) {
                        break;
                    }

                    actual += paso;
                }
            }

            liberar_valor(inicio);
            liberar_valor(limite);
            return CMD_ES_RESULTADO_NORMAL;
        }
        case CMD_ES_SENTENCIA_ROMPER:
            return CMD_ES_RESULTADO_ROMPER;
        case CMD_ES_SENTENCIA_CONTINUAR:
            return CMD_ES_RESULTADO_CONTINUAR;
        default:
            fprintf(stderr, "Error interno: sentencia de lenguaje desconocida.\n");
            cmd_es_linea_invalida = 1;
            return CMD_ES_RESULTADO_ERROR;
    }
}

static CmdEsValor *crear_valor_invalido(void) {
    return crear_valor_simple(CMD_ES_TIPO_INVALIDO);
}

static CmdEsValor *crear_valor_entero(long numero) {
    CmdEsValor *valor;

    valor = crear_valor_simple(CMD_ES_TIPO_ENTERO);
    valor->entero = numero;
    return valor;
}

static CmdEsValor *crear_valor_decimal(double numero) {
    CmdEsValor *valor;

    valor = crear_valor_simple(CMD_ES_TIPO_DECIMAL);
    valor->decimal = numero;
    return valor;
}

static CmdEsValor *crear_valor_cadena(const char *texto) {
    CmdEsValor *valor;

    valor = crear_valor_simple(CMD_ES_TIPO_CADENA);
    valor->cadena = duplicar_cadena_simple(texto != NULL ? texto : "");
    return valor;
}

static CmdEsValor *crear_valor_booleano(int valor_booleano) {
    CmdEsValor *valor;

    valor = crear_valor_simple(CMD_ES_TIPO_BOOLEANO);
    valor->booleano = valor_booleano ? 1 : 0;
    return valor;
}

static CmdEsValor *crear_valor_por_defecto(CmdEsTipoDato tipo_dato) {
    switch (tipo_dato) {
        case CMD_ES_TIPO_ENTERO:
            return crear_valor_entero(0);
        case CMD_ES_TIPO_DECIMAL:
            return crear_valor_decimal(0.0);
        case CMD_ES_TIPO_CADENA:
            return crear_valor_cadena("");
        case CMD_ES_TIPO_BOOLEANO:
            return crear_valor_booleano(0);
        default:
            return crear_valor_invalido();
    }
}

static CmdEsValor *copiar_valor_lenguaje(const CmdEsValor *valor) {
    if (valor == NULL) {
        return crear_valor_invalido();
    }

    switch (valor->tipo) {
        case CMD_ES_TIPO_ENTERO:
            return crear_valor_entero(valor->entero);
        case CMD_ES_TIPO_DECIMAL:
            return crear_valor_decimal(valor->decimal);
        case CMD_ES_TIPO_CADENA:
            return crear_valor_cadena(valor->cadena != NULL ? valor->cadena : "");
        case CMD_ES_TIPO_BOOLEANO:
            return crear_valor_booleano(valor->booleano);
        default:
            return crear_valor_invalido();
    }
}

static void liberar_valor(CmdEsValor *valor) {
    if (valor == NULL) {
        return;
    }

    if (valor->cadena != NULL) {
        free(valor->cadena);
    }

    free(valor);
}

static CmdEsValor *obtener_valor_identificador(const char *identificador) {
    int indice;

    indice = buscar_indice_variable_lenguaje(identificador);

    if (indice < 0 || cmd_es_variables_lenguaje[indice].valor == NULL) {
        cmd_es_linea_invalida = 1;
        fprintf(stderr, "Error semantico (linea %d): variable no definida: %s.\n", numero_linea_comando(), identificador);
        return crear_valor_invalido();
    }

    return copiar_valor_lenguaje(cmd_es_variables_lenguaje[indice].valor);
}

static CmdEsValor *operar_suma(CmdEsValor *izquierda, CmdEsValor *derecha) {
    CmdEsValor *resultado;
    char *texto_concatenado;
    size_t longitud_izquierda;
    size_t longitud_derecha;

    if (izquierda == NULL || derecha == NULL) {
        liberar_valor(izquierda);
        liberar_valor(derecha);
        return crear_valor_invalido();
    }

    if (izquierda->tipo == CMD_ES_TIPO_INVALIDO || derecha->tipo == CMD_ES_TIPO_INVALIDO) {
        liberar_valor(izquierda);
        liberar_valor(derecha);
        return crear_valor_invalido();
    }

    if (valor_es_numerico(izquierda) && valor_es_numerico(derecha)) {
        if (izquierda->tipo == CMD_ES_TIPO_ENTERO && derecha->tipo == CMD_ES_TIPO_ENTERO) {
            resultado = crear_valor_entero(izquierda->entero + derecha->entero);
        } else {
            resultado = crear_valor_decimal(valor_a_decimal(izquierda) + valor_a_decimal(derecha));
        }

        liberar_valor(izquierda);
        liberar_valor(derecha);
        return resultado;
    }

    if (izquierda->tipo == CMD_ES_TIPO_CADENA && derecha->tipo == CMD_ES_TIPO_CADENA) {
        resultado = crear_valor_simple(CMD_ES_TIPO_CADENA);
        longitud_izquierda = strlen(izquierda->cadena != NULL ? izquierda->cadena : "");
        longitud_derecha = strlen(derecha->cadena != NULL ? derecha->cadena : "");
        texto_concatenado = (char *)malloc(longitud_izquierda + longitud_derecha + 1);

        if (texto_concatenado == NULL) {
            fprintf(stderr, "Error: memoria insuficiente.\n");
            exit(1);
        }

        memcpy(texto_concatenado, izquierda->cadena != NULL ? izquierda->cadena : "", longitud_izquierda);
        memcpy(texto_concatenado + longitud_izquierda, derecha->cadena != NULL ? derecha->cadena : "", longitud_derecha);
        texto_concatenado[longitud_izquierda + longitud_derecha] = '\0';

        resultado->cadena = texto_concatenado;
        liberar_valor(izquierda);
        liberar_valor(derecha);
        return resultado;
    }

    cmd_es_linea_invalida = 1;
    fprintf(stderr, "Error semantico (linea %d): '+' solo admite numeros o cadenas del mismo tipo.\n", numero_linea_comando());
    liberar_valor(izquierda);
    liberar_valor(derecha);
    return crear_valor_invalido();
}

static CmdEsValor *operar_resta(CmdEsValor *izquierda, CmdEsValor *derecha) {
    CmdEsValor *resultado;

    if (izquierda == NULL || derecha == NULL) {
        liberar_valor(izquierda);
        liberar_valor(derecha);
        return crear_valor_invalido();
    }

    if (izquierda->tipo == CMD_ES_TIPO_INVALIDO || derecha->tipo == CMD_ES_TIPO_INVALIDO) {
        liberar_valor(izquierda);
        liberar_valor(derecha);
        return crear_valor_invalido();
    }

    if (!valor_es_numerico(izquierda) || !valor_es_numerico(derecha)) {
        cmd_es_linea_invalida = 1;
        fprintf(stderr, "Error semantico (linea %d): '-' solo admite numeros.\n", numero_linea_comando());
        liberar_valor(izquierda);
        liberar_valor(derecha);
        return crear_valor_invalido();
    }

    if (izquierda->tipo == CMD_ES_TIPO_ENTERO && derecha->tipo == CMD_ES_TIPO_ENTERO) {
        resultado = crear_valor_entero(izquierda->entero - derecha->entero);
    } else {
        resultado = crear_valor_decimal(valor_a_decimal(izquierda) - valor_a_decimal(derecha));
    }

    liberar_valor(izquierda);
    liberar_valor(derecha);
    return resultado;
}

static CmdEsValor *operar_multiplicacion(CmdEsValor *izquierda, CmdEsValor *derecha) {
    CmdEsValor *resultado;

    if (izquierda == NULL || derecha == NULL) {
        liberar_valor(izquierda);
        liberar_valor(derecha);
        return crear_valor_invalido();
    }

    if (izquierda->tipo == CMD_ES_TIPO_INVALIDO || derecha->tipo == CMD_ES_TIPO_INVALIDO) {
        liberar_valor(izquierda);
        liberar_valor(derecha);
        return crear_valor_invalido();
    }

    if (!valor_es_numerico(izquierda) || !valor_es_numerico(derecha)) {
        cmd_es_linea_invalida = 1;
        fprintf(stderr, "Error semantico (linea %d): '*' solo admite numeros.\n", numero_linea_comando());
        liberar_valor(izquierda);
        liberar_valor(derecha);
        return crear_valor_invalido();
    }

    if (izquierda->tipo == CMD_ES_TIPO_ENTERO && derecha->tipo == CMD_ES_TIPO_ENTERO) {
        resultado = crear_valor_entero(izquierda->entero * derecha->entero);
    } else {
        resultado = crear_valor_decimal(valor_a_decimal(izquierda) * valor_a_decimal(derecha));
    }

    liberar_valor(izquierda);
    liberar_valor(derecha);
    return resultado;
}

static CmdEsValor *operar_division(CmdEsValor *izquierda, CmdEsValor *derecha) {
    CmdEsValor *resultado;

    if (izquierda == NULL || derecha == NULL) {
        liberar_valor(izquierda);
        liberar_valor(derecha);
        return crear_valor_invalido();
    }

    if (izquierda->tipo == CMD_ES_TIPO_INVALIDO || derecha->tipo == CMD_ES_TIPO_INVALIDO) {
        liberar_valor(izquierda);
        liberar_valor(derecha);
        return crear_valor_invalido();
    }

    if (!valor_es_numerico(izquierda) || !valor_es_numerico(derecha)) {
        cmd_es_linea_invalida = 1;
        fprintf(stderr, "Error semantico (linea %d): '/' solo admite numeros.\n", numero_linea_comando());
        liberar_valor(izquierda);
        liberar_valor(derecha);
        return crear_valor_invalido();
    }

    if ((derecha->tipo == CMD_ES_TIPO_ENTERO && derecha->entero == 0)
        || (derecha->tipo == CMD_ES_TIPO_DECIMAL && derecha->decimal == 0.0)) {
        cmd_es_linea_invalida = 1;
        fprintf(stderr, "Error semantico (linea %d): division entre cero.\n", numero_linea_comando());
        liberar_valor(izquierda);
        liberar_valor(derecha);
        return crear_valor_invalido();
    }

    if (izquierda->tipo == CMD_ES_TIPO_ENTERO && derecha->tipo == CMD_ES_TIPO_ENTERO) {
        resultado = crear_valor_entero(izquierda->entero / derecha->entero);
    } else {
        resultado = crear_valor_decimal(valor_a_decimal(izquierda) / valor_a_decimal(derecha));
    }

    liberar_valor(izquierda);
    liberar_valor(derecha);
    return resultado;
}

static CmdEsValor *operar_modulo(CmdEsValor *izquierda, CmdEsValor *derecha) {
    CmdEsValor *resultado;

    if (izquierda == NULL || derecha == NULL) {
        liberar_valor(izquierda);
        liberar_valor(derecha);
        return crear_valor_invalido();
    }

    if (izquierda->tipo == CMD_ES_TIPO_INVALIDO || derecha->tipo == CMD_ES_TIPO_INVALIDO) {
        liberar_valor(izquierda);
        liberar_valor(derecha);
        return crear_valor_invalido();
    }

    if (izquierda->tipo != CMD_ES_TIPO_ENTERO || derecha->tipo != CMD_ES_TIPO_ENTERO) {
        cmd_es_linea_invalida = 1;
        fprintf(stderr, "Error semantico (linea %d): '%%' solo admite enteros.\n", numero_linea_comando());
        liberar_valor(izquierda);
        liberar_valor(derecha);
        return crear_valor_invalido();
    }

    if (derecha->entero == 0) {
        cmd_es_linea_invalida = 1;
        fprintf(stderr, "Error semantico (linea %d): modulo entre cero.\n", numero_linea_comando());
        liberar_valor(izquierda);
        liberar_valor(derecha);
        return crear_valor_invalido();
    }

    resultado = crear_valor_entero(izquierda->entero % derecha->entero);
    liberar_valor(izquierda);
    liberar_valor(derecha);
    return resultado;
}

static CmdEsValor *operar_igualdad(CmdEsValor *izquierda, CmdEsValor *derecha, int es_igualdad) {
    int comparacion;

    if (izquierda == NULL || derecha == NULL) {
        liberar_valor(izquierda);
        liberar_valor(derecha);
        return crear_valor_invalido();
    }

    if (izquierda->tipo == CMD_ES_TIPO_INVALIDO || derecha->tipo == CMD_ES_TIPO_INVALIDO) {
        liberar_valor(izquierda);
        liberar_valor(derecha);
        return crear_valor_invalido();
    }

    if (valor_es_numerico(izquierda) && valor_es_numerico(derecha)) {
        comparacion = (valor_a_decimal(izquierda) == valor_a_decimal(derecha));
    } else if (izquierda->tipo == CMD_ES_TIPO_CADENA && derecha->tipo == CMD_ES_TIPO_CADENA) {
        comparacion = strcmp(izquierda->cadena != NULL ? izquierda->cadena : "",
                             derecha->cadena != NULL ? derecha->cadena : "") == 0;
    } else if (izquierda->tipo == CMD_ES_TIPO_BOOLEANO && derecha->tipo == CMD_ES_TIPO_BOOLEANO) {
        comparacion = izquierda->booleano == derecha->booleano;
    } else {
        cmd_es_linea_invalida = 1;
        fprintf(stderr, "Error semantico (linea %d): no se pueden comparar '%s' y '%s' con igualdad.\n",
                numero_linea_comando(), nombre_tipo_dato(izquierda->tipo), nombre_tipo_dato(derecha->tipo));
        liberar_valor(izquierda);
        liberar_valor(derecha);
        return crear_valor_invalido();
    }

    liberar_valor(izquierda);
    liberar_valor(derecha);
    return crear_valor_booleano(es_igualdad ? comparacion : !comparacion);
}

static CmdEsValor *operar_comparacion(CmdEsValor *izquierda, CmdEsValor *derecha, const char *operador) {
    double valor_izquierda;
    double valor_derecha;
    int comparacion;

    if (izquierda == NULL || derecha == NULL) {
        liberar_valor(izquierda);
        liberar_valor(derecha);
        return crear_valor_invalido();
    }

    if (izquierda->tipo == CMD_ES_TIPO_INVALIDO || derecha->tipo == CMD_ES_TIPO_INVALIDO) {
        liberar_valor(izquierda);
        liberar_valor(derecha);
        return crear_valor_invalido();
    }

    if (!valor_es_numerico(izquierda) || !valor_es_numerico(derecha)) {
        cmd_es_linea_invalida = 1;
        fprintf(stderr, "Error semantico (linea %d): '%s' solo admite numeros.\n", numero_linea_comando(), operador);
        liberar_valor(izquierda);
        liberar_valor(derecha);
        return crear_valor_invalido();
    }

    valor_izquierda = valor_a_decimal(izquierda);
    valor_derecha = valor_a_decimal(derecha);
    comparacion = 0;

    if (strcmp(operador, "<") == 0) {
        comparacion = valor_izquierda < valor_derecha;
    } else if (strcmp(operador, ">") == 0) {
        comparacion = valor_izquierda > valor_derecha;
    } else if (strcmp(operador, "<=") == 0) {
        comparacion = valor_izquierda <= valor_derecha;
    } else if (strcmp(operador, ">=") == 0) {
        comparacion = valor_izquierda >= valor_derecha;
    }

    liberar_valor(izquierda);
    liberar_valor(derecha);
    return crear_valor_booleano(comparacion);
}

static CmdEsValor *operar_logico(CmdEsValor *izquierda, CmdEsValor *derecha, const char *operador) {
    int resultado_booleano;

    if (izquierda == NULL || derecha == NULL) {
        liberar_valor(izquierda);
        liberar_valor(derecha);
        return crear_valor_invalido();
    }

    if (izquierda->tipo == CMD_ES_TIPO_INVALIDO || derecha->tipo == CMD_ES_TIPO_INVALIDO) {
        liberar_valor(izquierda);
        liberar_valor(derecha);
        return crear_valor_invalido();
    }

    if (izquierda->tipo != CMD_ES_TIPO_BOOLEANO || derecha->tipo != CMD_ES_TIPO_BOOLEANO) {
        cmd_es_linea_invalida = 1;
        fprintf(stderr, "Error semantico (linea %d): '%s' solo admite booleanos.\n", numero_linea_comando(), operador);
        liberar_valor(izquierda);
        liberar_valor(derecha);
        return crear_valor_invalido();
    }

    if (strcmp(operador, "Y") == 0) {
        resultado_booleano = izquierda->booleano && derecha->booleano;
    } else {
        resultado_booleano = izquierda->booleano || derecha->booleano;
    }

    liberar_valor(izquierda);
    liberar_valor(derecha);
    return crear_valor_booleano(resultado_booleano);
}

static CmdEsValor *operar_negacion(CmdEsValor *valor) {
    CmdEsValor *resultado;

    if (valor == NULL) {
        return crear_valor_invalido();
    }

    if (valor->tipo == CMD_ES_TIPO_INVALIDO) {
        liberar_valor(valor);
        return crear_valor_invalido();
    }

    if (valor->tipo != CMD_ES_TIPO_BOOLEANO) {
        cmd_es_linea_invalida = 1;
        fprintf(stderr, "Error semantico (linea %d): 'NO' solo admite booleanos.\n", numero_linea_comando());
        liberar_valor(valor);
        return crear_valor_invalido();
    }

    resultado = crear_valor_booleano(!valor->booleano);
    liberar_valor(valor);
    return resultado;
}

static CmdEsValor *operar_negativo(CmdEsValor *valor) {
    CmdEsValor *resultado;

    if (valor == NULL) {
        return crear_valor_invalido();
    }

    if (valor->tipo == CMD_ES_TIPO_INVALIDO) {
        liberar_valor(valor);
        return crear_valor_invalido();
    }

    if (!valor_es_numerico(valor)) {
        cmd_es_linea_invalida = 1;
        fprintf(stderr, "Error semantico (linea %d): el signo negativo solo admite numeros.\n", numero_linea_comando());
        liberar_valor(valor);
        return crear_valor_invalido();
    }

    if (valor->tipo == CMD_ES_TIPO_ENTERO) {
        resultado = crear_valor_entero(-valor->entero);
    } else {
        resultado = crear_valor_decimal(-valor->decimal);
    }

    liberar_valor(valor);
    return resultado;
}

static int buscar_indice_variable_lenguaje(const char *nombre) {
    int i;

    for (i = 0; i < CMD_ES_MAX_VARIABLES_LENGUAJE; ++i) {
        if (!cmd_es_variables_lenguaje[i].en_uso) {
            continue;
        }

        if (strcmp(cmd_es_variables_lenguaje[i].nombre, nombre) == 0) {
            return i;
        }
    }

    return -1;
}

static int guardar_variable_lenguaje(const char *nombre, CmdEsTipoDato tipo_dato, const CmdEsValor *valor) {
    int indice;
    int i;
    CmdEsValor *valor_guardado;

    if (!nombre_variable_valido(nombre)) {
        cmd_es_linea_invalida = 1;
        fprintf(stderr, "Error semantico (linea %d): identificador invalido: %s.\n", numero_linea_comando(), nombre);
        return 0;
    }

    if (buscar_indice_variable_lenguaje(nombre) >= 0) {
        cmd_es_linea_invalida = 1;
        fprintf(stderr, "Error semantico (linea %d): la variable '%s' ya fue declarada.\n", numero_linea_comando(), nombre);
        return 0;
    }

    indice = -1;

    for (i = 0; i < CMD_ES_MAX_VARIABLES_LENGUAJE; ++i) {
        if (!cmd_es_variables_lenguaje[i].en_uso) {
            indice = i;
            break;
        }
    }

    if (indice < 0) {
        cmd_es_linea_invalida = 1;
        fprintf(stderr, "Error semantico (linea %d): no hay espacio para mas variables del lenguaje.\n", numero_linea_comando());
        return 0;
    }

    if (valor == NULL) {
        valor_guardado = crear_valor_por_defecto(tipo_dato);
    } else {
        valor_guardado = convertir_valor_a_tipo(tipo_dato, valor, nombre);
    }

    if (valor_guardado == NULL || valor_guardado->tipo == CMD_ES_TIPO_INVALIDO) {
        liberar_valor(valor_guardado);
        return 0;
    }

    if (!guardar_texto_limitado(nombre, cmd_es_variables_lenguaje[indice].nombre, sizeof(cmd_es_variables_lenguaje[indice].nombre))) {
        cmd_es_linea_invalida = 1;
        fprintf(stderr, "Error semantico (linea %d): identificador demasiado largo: %s.\n", numero_linea_comando(), nombre);
        liberar_valor(valor_guardado);
        return 0;
    }

    cmd_es_variables_lenguaje[indice].en_uso = 1;
    cmd_es_variables_lenguaje[indice].tipo = tipo_dato;
    cmd_es_variables_lenguaje[indice].valor = valor_guardado;
    return 1;
}

static int asignar_variable_lenguaje(const char *nombre, const CmdEsValor *valor) {
    int indice;
    CmdEsValor *valor_guardado;

    indice = buscar_indice_variable_lenguaje(nombre);

    if (indice < 0) {
        cmd_es_linea_invalida = 1;
        fprintf(stderr, "Error semantico (linea %d): la variable '%s' no ha sido declarada.\n", numero_linea_comando(), nombre);
        return 0;
    }

    valor_guardado = convertir_valor_a_tipo(cmd_es_variables_lenguaje[indice].tipo, valor, nombre);

    if (valor_guardado == NULL || valor_guardado->tipo == CMD_ES_TIPO_INVALIDO) {
        liberar_valor(valor_guardado);
        return 0;
    }

    liberar_valor(cmd_es_variables_lenguaje[indice].valor);
    cmd_es_variables_lenguaje[indice].valor = valor_guardado;
    return 1;
}

static int asignar_variable_control_para(const char *nombre, const CmdEsValor *valor) {
    int indice;
    CmdEsTipoDato tipo_dato;

    if (valor == NULL || valor->tipo == CMD_ES_TIPO_INVALIDO) {
        return 0;
    }

    if (!valor_es_numerico(valor)) {
        cmd_es_linea_invalida = 1;
        fprintf(stderr, "Error semantico (linea %d): la variable de control de PARA debe ser numerica.\n", numero_linea_comando());
        return 0;
    }

    indice = buscar_indice_variable_lenguaje(nombre);

    if (indice < 0) {
        tipo_dato = valor->tipo == CMD_ES_TIPO_DECIMAL ? CMD_ES_TIPO_DECIMAL : CMD_ES_TIPO_ENTERO;
        return guardar_variable_lenguaje(nombre, tipo_dato, valor);
    }

    if (!valor_es_numerico(cmd_es_variables_lenguaje[indice].valor)) {
        cmd_es_linea_invalida = 1;
        fprintf(stderr, "Error semantico (linea %d): la variable '%s' ya existe y no es numerica para usarla en PARA.\n", numero_linea_comando(), nombre);
        return 0;
    }

    return asignar_variable_lenguaje(nombre, valor);
}

static CmdEsValor *convertir_valor_a_tipo(CmdEsTipoDato tipo_dato, const CmdEsValor *valor, const char *identificador) {
    if (valor == NULL) {
        return crear_valor_invalido();
    }

    if (valor->tipo == CMD_ES_TIPO_INVALIDO) {
        return crear_valor_invalido();
    }

    switch (tipo_dato) {
        case CMD_ES_TIPO_ENTERO:
            if (valor->tipo == CMD_ES_TIPO_ENTERO) {
                return copiar_valor_lenguaje(valor);
            }
            break;
        case CMD_ES_TIPO_DECIMAL:
            if (valor->tipo == CMD_ES_TIPO_DECIMAL) {
                return copiar_valor_lenguaje(valor);
            }
            if (valor->tipo == CMD_ES_TIPO_ENTERO) {
                return crear_valor_decimal((double)valor->entero);
            }
            break;
        case CMD_ES_TIPO_CADENA:
            if (valor->tipo == CMD_ES_TIPO_CADENA) {
                return copiar_valor_lenguaje(valor);
            }
            break;
        case CMD_ES_TIPO_BOOLEANO:
            if (valor->tipo == CMD_ES_TIPO_BOOLEANO) {
                return copiar_valor_lenguaje(valor);
            }
            break;
        default:
            break;
    }

    cmd_es_linea_invalida = 1;
    fprintf(stderr, "Error semantico (linea %d): no se puede asignar un valor de tipo %s a '%s' de tipo %s.\n",
            numero_linea_comando(), nombre_tipo_dato(valor->tipo), identificador, nombre_tipo_dato(tipo_dato));
    return crear_valor_invalido();
}

static const char *nombre_tipo_dato(CmdEsTipoDato tipo_dato) {
    switch (tipo_dato) {
        case CMD_ES_TIPO_ENTERO:
            return "entero";
        case CMD_ES_TIPO_DECIMAL:
            return "decimal";
        case CMD_ES_TIPO_CADENA:
            return "cadena";
        case CMD_ES_TIPO_BOOLEANO:
            return "booleano";
        default:
            return "invalido";
    }
}

static void imprimir_valor_lenguaje(const CmdEsValor *valor) {
    if (valor == NULL) {
        return;
    }

    switch (valor->tipo) {
        case CMD_ES_TIPO_ENTERO:
            printf("%ld\n", valor->entero);
            break;
        case CMD_ES_TIPO_DECIMAL:
            printf("%.15g\n", valor->decimal);
            break;
        case CMD_ES_TIPO_CADENA:
            printf("%s\n", valor->cadena != NULL ? valor->cadena : "");
            break;
        case CMD_ES_TIPO_BOOLEANO:
            printf("%s\n", valor->booleano ? "verdadero" : "falso");
            break;
        default:
            printf("[valor invalido]\n");
            break;
    }
}

static int valor_es_numerico(const CmdEsValor *valor) {
    return valor != NULL && (valor->tipo == CMD_ES_TIPO_ENTERO || valor->tipo == CMD_ES_TIPO_DECIMAL);
}

static double valor_a_decimal(const CmdEsValor *valor) {
    if (valor->tipo == CMD_ES_TIPO_DECIMAL) {
        return valor->decimal;
    }

    return (double)valor->entero;
}

static void mostrar_ayuda(void) {
    printf("AYUDA: Comandos disponibles: AYUDA, VERSION, FECHA, HORA, LIMPIAR, LISTAR, ECO <texto>, PAUSA, TITULO <texto>, COLOR <codigo>, ARBOL, BUSCAR <texto> <archivo>, BUSCAR_TEXTO <texto> <archivo>, MAS <archivo>, ORDENAR <archivo>, COMPARAR <archivo1> <archivo2>, SIMBOLO <texto>, RUTA [texto], DEFINIR [nombre | nombre=valor], CAMBIAR_DIR <nombre | . | ..>, CREAR_DIR <nombre>, ELIMINAR_DIR <nombre>, MOSTRAR <archivo>, ELIMINAR <archivo>, RENOMBRAR <origen> <destino>, COPIAR <origen> <destino>, MOVER <origen> <destino>, lenguaje: var <tipo> <id> [= expresion];, <id> = expresion;, imprimir(expresion);, si (condicion) { ... } [sino { ... }], mientras (condicion) { ... }, para id = inicio hasta limite { ... }, romper;, continuar;, SALIR\n");
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
