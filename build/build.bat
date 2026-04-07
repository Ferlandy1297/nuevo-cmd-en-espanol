@echo off
setlocal ENABLEDELAYEDEXPANSION

REM Construcción del CMD en español con win_flex/win_bison + gcc (MinGW)
REM Requisitos: win_flex_bison3 y gcc en PATH

if not exist build mkdir build >nul 2>&1

echo [1/3] Generando parser (Bison)
win_bison -d -o build\cmd_es.tab.c src\cmd_es.y || goto :error

echo [2/3] Generando lexer (Flex)
win_flex -o build\lex.yy.c src\cmd_es.l || goto :error

echo [3/3] Compilando y enlazando (gcc)
gcc -I build -o build\cmd-es.exe build\cmd_es.tab.c build\lex.yy.c || goto :error

echo.
echo Listo: build\cmd-es.exe
exit /b 0

:error
echo.
echo ERROR en el proceso de compilacion. Asegura tener win_flex, win_bison y gcc en PATH.
exit /b 1

