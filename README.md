# Nuevo CMD en Español

Proyecto académico para construir una nueva consola en español, inspirada en CMD de Windows. El objetivo es ofrecer comandos nativos en español y una experiencia clara para el curso de Compiladores.

Estado actual: Migración a base Flex/Bison con ejecutable mínimo.

## Estructura del proyecto (Flex/Bison)
- `src/cmd_es.l` - lexer con Flex/WinFlex (tokens: AYUDA, VERSION, SALIR, LIMPIAR, FECHA, HORA, NEWLINE; espacios/tabulaciones ignorados; otros se reportan como error léxico). El lexer es no sensible a mayúsculas/minúsculas.
- `src/cmd_es.y` - parser con Bison/WinBison (una instrucción por línea; acciones visibles; salida con SALIR; fecha y hora del sistema). Incluye recuperación por línea para errores sintácticos.
- `ejemplos/` - archivos de prueba (por ej. `comandos.txt`).
- `build/` - artefactos generados y ejecutable (`cmd-es.exe`).
- `legacy/` - intento previo en Python preservado (no se usa ahora).

Documentación adicional en `docs/` (alcance y tabla de comandos iniciales).

## Compilación y ejecución (Windows)
Requisitos (elige una opción):
- Opción A: `win_flex_bison3` + `gcc` (MinGW/MSYS2) en PATH.
- Opción B: WSL con `flex`/`bison` y `gcc`.

Comandos con win_flex/win_bison (PowerShell o CMD):
Nota: Ejecuta estos comandos desde la raiz del proyecto.

Nota: `build\\build.bat` ya configura el PATH para el entorno antiguo del curso (GnuWin32 y Dev-Cpp/MinGW64).

```
win_bison -d -o build\cmd_es.tab.c src\cmd_es.y
win_flex  -o build\lex.yy.c      src\cmd_es.l
gcc -I build -o build\cmd-es.exe build\cmd_es.tab.c build\lex.yy.c
```

También puedes usar el script:

```
build\build.bat
```

Ejecución interactiva desde consola:

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
- `SALIR` termina la ejecución.
- Los comandos se aceptan sin diferenciar mayúsculas/minúsculas (por ejemplo, `ayuda`, `AyUdA`).

### Errores
- Error léxico: reportado por el lexer (caracteres o secuencias no válidas). Se imprime el mensaje y se continúa con el resto de la línea.
- Error sintáctico: reportado por el parser cuando la secuencia de tokens válidos de una línea no forma una instrucción permitida. La gramática recupera en `NEWLINE` para continuar leyendo líneas siguientes.
