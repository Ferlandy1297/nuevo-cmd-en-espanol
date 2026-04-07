"""Funciones de utilidad para la consola CMD en español."""

from estado import VERSION


def mostrar_encabezado() -> None:
    """Imprime el encabezado del sistema al iniciar."""
    print("=" * 50)
    print("  Nuevo CMD en Español")
    print(f"  {VERSION}")
    print("=" * 50)


def normalizar_entrada(texto: str) -> str:
    """Normaliza la entrada quitando espacios extra.

    Nota: No se implementa lexer formal en este segmento.
    """
    return texto.strip()
