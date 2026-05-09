# Nuevo CMD en Espanol

Proyecto academico para construir una nueva consola en espanol, inspirada en CMD de Windows. El objetivo es ofrecer comandos nativos en espanol y una experiencia clara para el curso de Compiladores.

Estado actual: Migracion a base Flex/Bison con ejecutable minimo, navegacion basica de directorios y manejo basico de archivos, copia y movimiento simples.

## Estructura del proyecto (Flex/Bison)
- `src/cmd_es.l` - lexer con Flex/WinFlex (tokens: AYUDA, VERSION, SALIR, LIMPIAR, FECHA, HORA, LISTAR, CAMBIAR_DIR, CREAR_DIR, ELIMINAR_DIR, MOSTRAR, ELIMINAR, RENOMBRAR, COPIAR, MOVER, PUNTO, PUNTO_PUNTO, NOMBRE y NEWLINE; espacios/tabulaciones ignorados; otros se reportan como error lexico). El lexer es no sensible a mayusculas/minusculas.
- `src/cmd_es.y` - parser con Bison/WinBison (una instruccion por linea; acciones visibles; salida con SALIR; fecha y hora del sistema; navegacion basica de directorios y manejo basico de archivos, incluyendo copia y movimiento simples). Incluye recuperacion por linea para errores sintacticos.
- `ejemplos/` - archivos de prueba (por ej. `comandos.txt`).
- `build/` - artefactos generados y ejecutable (`cmd-es.exe`).
- `legacy/` - intento previo en Python preservado (no se usa ahora).

Documentacion adicional en `docs/` (alcance y tabla de comandos iniciales).

## Compilacion y ejecucion (Windows)
Requisitos (elige una opcion):
- Opcion A: `win_flex_bison3` + `gcc` (MinGW/MSYS2) en PATH.
- Opcion B: WSL con `flex`/`bison` y `gcc`.

Comandos con win_flex/win_bison (PowerShell o CMD):
Nota: Ejecuta estos comandos desde la raiz del proyecto.

Nota: `build\\build.bat` ya configura el PATH para el entorno antiguo del curso (GnuWin32 y Dev-Cpp/MinGW64).

```
win_bison -d -o build\cmd_es.tab.c src\cmd_es.y
win_flex  -o build\lex.yy.c      src\cmd_es.l
gcc -I build -o build\cmd-es.exe build\cmd_es.tab.c build\lex.yy.c
```

Tambien puedes usar el script:

```
build\build.bat
```

Ejecucion interactiva desde consola:

```
build\cmd-es.exe
```

Ejemplo con archivo de entrada:

```
type ejemplos\comandos.txt | build\cmd-es.exe
```

## Comportamiento
- `AYUDA` muestra mensaje de ayuda.
- `VERSION` imprime `CMD Espanol v0.1`.
- `FECHA` muestra la fecha actual del sistema.
- `HORA` muestra la hora actual del sistema.
- `LIMPIAR` imprime varias lineas en blanco como limpieza simple compatible.
- `LISTAR` muestra los directorios y archivos del directorio actual usando el formato `[DIR] nombre` y `[ARC] nombre`.
- `CAMBIAR_DIR <nombre>`, `CAMBIAR_DIR .` y `CAMBIAR_DIR ..` cambian al directorio indicado y luego muestran la ruta actual.
- `CREAR_DIR <nombre>` crea un directorio en la ubicacion actual.
- `ELIMINAR_DIR <nombre>` elimina un directorio vacio.
- `MOSTRAR <archivo>` muestra el contenido de un archivo de texto simple si existe.
- `ELIMINAR <archivo>` elimina un archivo simple si existe.
- `RENOMBRAR <origen> <destino>` cambia el nombre de un archivo simple si el origen existe y el destino no existe.
- `COPIAR <origen> <destino>` copia un archivo simple si el origen existe, no es directorio y el destino no existe.
- `MOVER <origen> <destino>` mueve un archivo simple si el origen existe, no es directorio y el destino no existe.
- `SALIR` termina la ejecucion.
- Los comandos se aceptan sin diferenciar mayusculas/minusculas (por ejemplo, `ayuda`, `AyUdA`).

### Errores
- Error lexico: reportado por el lexer (caracteres o secuencias no validas). Se imprime el mensaje y se continua con el resto de la linea.
- Error sintactico: reportado por el parser cuando la secuencia de tokens validos de una linea no forma una instruccion permitida. La gramatica recupera en `NEWLINE` para continuar leyendo lineas siguientes.
