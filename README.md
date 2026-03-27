# Nuevo CMD en Español

Proyecto académico para construir una nueva consola en español, inspirada en CMD de Windows. El objetivo es ofrecer comandos nativos en español y una experiencia clara para el curso de Compiladores.

Estado actual: Segmento 2 — estructura base del proyecto y shell mínimo funcional.

## Estructura del proyecto (Segmento 2)
- `src/main.py` — punto de entrada con bucle interactivo.
- `src/estado.py` — estado global mínimo y versión del sistema.
- `src/comandos.py` — implementación de AYUDA, VERSION y SALIR.
- `src/utilidades.py` — utilidades (encabezado, normalización simple).
- `tests/` — carpeta preparada para pruebas futuras.

Documentación adicional en `docs/` (alcance y tabla de comandos iniciales).

## Ejecución
Requisitos: Python 3.10+.

Para ejecutar el shell mínimo:

```
python src/main.py
```

Al iniciar, se muestra un encabezado y el prompt:

```
:   CMD-ES:/>
```

