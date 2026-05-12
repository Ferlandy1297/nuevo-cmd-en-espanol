# Nuevo CMD en Espanol

Proyecto academico del curso de Compiladores para construir una consola inspirada en CMD de Windows, pero con comandos en espanol y un pequeno bloque de lenguaje integrado.

## Estado actual
- Shell tipo CMD en espanol con ayuda, version, fecha, hora, limpiar, listar, arbol, entorno interno y comandos basicos de directorios y archivos.
- Bloque de lenguaje con variables tipadas (`entero`, `decimal`, `cadena`, `booleano`), expresiones, operadores aritmeticos, logicos y de comparacion.
- Control de flujo con `si`, `sino`, `mientras`, `para`, `romper` y `continuar`.
- Funciones simples con parametros tipados, `retornar` y llamadas.
- Scopes por bloque para el lenguaje y validaciones semanticas basicas.

## Archivos principales
- `src/cmd_es.l`: lexer con Flex, no sensible a mayusculas/minusculas.
- `src/cmd_es.y`: parser y runtime principal con Bison.
- `ejemplos/comandos.txt`: demo integral del shell y del lenguaje.
- `build/build.bat`: forma recomendada de compilacion en el entorno viejo del curso.

## Compilar
Desde la raiz del proyecto:

```powershell
cmd /c build\build.bat
```

## Probar
Ejecucion interactiva:

```powershell
build\cmd-es.exe
```

Ejemplo principal:

```powershell
cmd /c "type ejemplos\comandos.txt | build\cmd-es.exe"
```

## Notas
- La gramatica mantiene una instruccion por linea fisica.
- Los bloques del lenguaje usan llaves `{ ... }` dentro de esa misma linea.
- `AYUDA` refleja la sintaxis soportada actualmente.
