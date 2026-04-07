"""Definición de comandos iniciales para el CMD en español."""

from typing import Callable, Dict, List

from estado import VERSION, Estado


Handler = Callable[[List[str], Estado], None]


def cmd_ayuda(_args: List[str], _estado: Estado) -> None:
    """Muestra la lista de comandos disponibles en esta fase."""
    print("Comandos disponibles:")
    print("  - AYUDA   : muestra esta ayuda")
    print("  - VERSION : muestra la versión del sistema")
    print("  - SALIR   : termina el programa")


def cmd_version(_args: List[str], _estado: Estado) -> None:
    """Muestra la versión del sistema."""
    print(VERSION)


def cmd_salir(_args: List[str], estado: Estado) -> None:
    """Termina el programa limpiamente."""
    estado.detener()


def obtener_comandos() -> Dict[str, Handler]:
    """Retorna el mapeo de comandos disponibles a sus manejadores."""
    return {
        "AYUDA": cmd_ayuda,
        "VERSION": cmd_version,
        "SALIR": cmd_salir,
    }
