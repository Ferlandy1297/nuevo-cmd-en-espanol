# Tabla de Comandos

Tabla de referencia basada en el conjunto típico de comandos mostrados por `HELP` en CMD que ya tenemos como base. Se unifican alias cuando aplica. Nombres en español en MAYÚSCULAS con guiones bajos para consistencia.

| Comando original | Comando en español | Función |
|---|---|---|
| DIR | LISTAR | Lista archivos y directorios del directorio actual o uno especificado. |
| CD/CHDIR | CAMBIAR_DIR | Cambia el directorio actual; sin argumentos, muestra el directorio actual. |
| MD/MKDIR | CREAR_DIR | Crea uno o varios directorios. |
| DEL/ERASE | ELIMINAR | Elimina uno o varios archivos. |
| RD/RMDIR | ELIMINAR_DIR | Elimina directorios vacíos o con conmutadores para contenido. |
| REN/RENAME | RENOMBRAR | Cambia el nombre de archivo(s) o directorio(s). |
| ASSOC | ASOCIAR | Muestra o cambia asociaciones entre extensiones y tipos de archivo. |
| ATTRIB | ATRIBUTOS | Muestra o cambia los atributos de archivos/directorios. |
| BCDEDIT | EDITAR_BCD | Muestra o establece propiedades en la base de datos de arranque (BCD). |
| BREAK | CONTROL_INTERRUPCION | Establece o borra la comprobación de Ctrl+C durante la ejecución. |
| CACLS | PERMISOS_ACL | Muestra o modifica listas de control de acceso (ACL) de archivos. |
| COPY | COPIAR | Copia archivos a otra ubicación. |
| XCOPY | COPIA_EXTENDIDA | Copia archivos y directorios con opciones avanzadas (recursión, filtros). |
| MOVE | MOVER | Mueve archivos o directorios a otra ubicación. |
| CHCP | PAGINA_CODIGOS | Muestra o establece la página de códigos activa. |
| CHKDSK | VERIFICAR_DISCO | Verifica un disco y muestra un informe de estado. |
| CHKNTFS | VERIFICAR_NTFS | Muestra o modifica la comprobación de disco al inicio para volúmenes NTFS. |
| CMD | INTERPRETE_CMD | Inicia una nueva instancia del intérprete de comandos. |
| COMP | COMPARAR_BINARIO | Compara el contenido de dos archivos o conjuntos de archivos (binario). |
| COMPACT | COMPACTAR | Muestra o cambia la compresión de archivos en particiones NTFS. |
| CONVERT | CONVERTIR | Convierte unidades FAT a NTFS sin perder datos. |
| TYPE | MOSTRAR | Muestra el contenido de uno o varios archivos de texto. |
| MORE | MAS | Muestra la salida por páginas (paginación). |
| FIND | BUSCAR | Busca texto simple en archivos o entrada estándar. |
| FINDSTR | BUSCAR_TEXTO | Busca texto con patrones/expresiones en archivos o entrada. |
| TREE | ARBOL | Muestra la estructura de directorios en forma de árbol. |
| CLS | LIMPIAR | Limpia la pantalla de la consola. |
| HELP | AYUDA | Muestra ayuda general o específica de un comando. |
| ECHO | ECO | Muestra mensajes o controla el eco de comandos. |
| PAUSE | PAUSA | Suspende la ejecución hasta que se presione una tecla. |
| EXIT | SALIR | Cierra la consola actual (finaliza la sesión). |
| VER | VERSION | Muestra la versión del intérprete/sistema. |
| DATE | FECHA | Muestra o establece la fecha del sistema. |
| TIME | HORA | Muestra o establece la hora del sistema. |
| FC | COMPARAR | Compara el contenido de dos archivos y muestra diferencias. |
| FORMAT | FORMATEAR | Da formato a un disco para usarlo con Windows. |
| FSUTIL | UTILIDADES_FS | Ejecuta operaciones avanzadas del sistema de archivos. |
| SORT | ORDENAR | Ordena líneas de texto de la entrada. |
| TITLE | TITULO | Cambia el título de la ventana de la consola. |
| COLOR | COLOR | Cambia los colores del texto y del fondo en la consola. |
| PATH | RUTA | Muestra o establece la ruta de búsqueda de ejecutables. |
| PROMPT | SIMBOLO | Personaliza el indicador (prompt) de la consola. |
| SET | DEFINIR | Muestra, crea o modifica variables de entorno. |
| SETLOCAL | ENTORNO_LOCAL | Inicia el aislamiento de cambios en variables de entorno. |
| ENDLOCAL | FIN_ENTORNO_LOCAL | Finaliza el aislamiento y restaura el entorno previo. |
| CALL | LLAMAR | Llama a otro comando o script y retorna al actual. |
| SHIFT | DESPLAZAR_ARGUMENTOS | Ajusta los parámetros posicionales en scripts por lotes. |
| START | INICIAR | Inicia un programa o abre una nueva ventana de consola. |
| FTYPE | TIPO_ARCHIVO | Muestra o modifica el comando asociado a un tipo de archivo. |
| PUSHD | APILAR_DIR | Guarda el directorio actual y cambia al especificado. |
| POPD | DESAPILAR_DIR | Restaura el directorio guardado por `PUSHD`. |
| VOL | VOLUMEN | Muestra la etiqueta y número de serie del volumen. |
| LABEL | ETIQUETA | Crea o cambia la etiqueta del volumen. |
| MKLINK | CREAR_ENLACE | Crea enlaces simbólicos o enlaces físicos. |
| FOR | PARA | Ejecuta un comando para cada elemento de un conjunto. |
| IF | SI | Ejecuta condicionalmente comandos según una expresión. |
| GOTO | IR_A | Salta a una etiqueta en un script por lotes. |
| REM | COMENTARIO | Inserta comentarios en scripts por lotes. |
| DISKPART | ADMIN_DISCOS | Administra discos, particiones y volúmenes. |
| DOSKEY | MACROS_CONSOLA | Edita líneas de comando, recuerda comandos y crea macros. |
| DRIVERQUERY | LISTAR_CONTROLADORES | Muestra una lista de controladores de dispositivo instalados. |
| GPRESULT | RESULTADOS_DIRECTIVAS | Muestra el conjunto resultante de directivas para un usuario/equipo. |
| ICACLS | PERMISOS_ICACLS | Muestra o modifica listas de control de acceso (ACL) con capacidades extendidas. |
| MODE | MODO | Configura dispositivos del sistema o la consola. |
| OPENFILES | ARCHIVOS_ABIERTOS | Muestra archivos abiertos por sesiones de red. |
| PRINT | IMPRIMIR | Imprime un archivo de texto. |
| RECOVER | RECUPERAR | Recupera información legible de un disco defectuoso. |
| REPLACE | REEMPLAZAR | Reemplaza archivos con versiones actualizadas. |
| ROBOCOPY | COPIAR_ROBUSTO | Copia archivos y directorios con tolerancia a fallos y opciones avanzadas. |
| SC | SERVICIO_CONTROL | Consulta o configura servicios (Service Control). |
| SCHTASKS | TAREAS_PROGRAMADAS | Crea, elimina, consulta o ejecuta tareas programadas. |
| SHUTDOWN | APAGAR | Apaga o reinicia el equipo local o remoto. |
| SUBST | UNIDAD_VIRTUAL | Asigna una letra de unidad a una ruta de carpeta. |
| SYSTEMINFO | INFO_SISTEMA | Muestra información detallada de la configuración del sistema. |
| TASKLIST | LISTAR_TAREAS | Muestra procesos en ejecución. |
| TASKKILL | TERMINAR_TAREA | Finaliza tareas o procesos por Id o nombre. |
| VERIFY | VERIFICAR_ESCRITURA | Indica si las operaciones de escritura se verifican correctamente. |
| WMIC | WMIC | Interfaz de línea de comandos para WMI (instrumental de administración de Windows). |

Notas:
- Alias unificados (convención obligatoria): `CD/CHDIR -> CAMBIAR_DIR`, `MD/MKDIR -> CREAR_DIR`, `DEL/ERASE -> ELIMINAR`, `RD/RMDIR -> ELIMINAR_DIR`, `REN/RENAME -> RENOMBRAR`, `MORE -> MAS`, `PROMPT -> SIMBOLO`, `SET -> DEFINIR`, `XCOPY -> COPIA_EXTENDIDA`.
- La tabla cubre el conjunto de comandos base del HELP de CMD utilizado en este proyecto y no añade elementos fuera de esa referencia.
