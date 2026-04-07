@echo off
setlocal

REM Configurar PATH para entornos antiguos (GnuWin32 y Dev-Cpp / MinGW64)
set "PATH=C:\PROGRA~2\GnuWin32\bin;C:\PROGRA~2\Dev-Cpp\MinGW64\bin;%PATH%"

REM Crear carpeta build si no existe
if not exist build mkdir build

echo [1/3] Generando parser (bison)
bison -d -o build/cmd_es.tab.c src/cmd_es.y
if errorlevel 1 goto error

echo [2/3] Generando lexer (flex)
flex -t src\cmd_es.l > build\lex.yy.c
if errorlevel 1 goto error

echo [3/3] Compilando ejecutable (gcc)
gcc -I build -o build\cmd-es.exe build\cmd_es.tab.c build\lex.yy.c
if errorlevel 1 goto error

echo.
echo Compilacion completada correctamente.
goto end

:error
echo.
echo ERROR en el proceso de compilacion.
exit /b 1

:end
endlocal