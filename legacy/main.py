"""Entrada principal del nuevo CMD en español (Segmento 2)."""

from typing import List

import comandos
from estado import Estado
from utilidades import mostrar_encabezado, normalizar_entrada


PROMPT = ":   CMD-ES:/>"


def parsear(entrada: str) -> List[str]:
    """Parseo mínimo: divide por espacios.

    Mantiene el diseño simple; sin lexer formal en este segmento.
    """
    texto = normalizar_entrada(entrada)
    if not texto:
        return []
    return texto.split()


def bucle_principal() -> None:
    estado = Estado()
    mostrar_encabezado()

    mapa = comandos.obtener_comandos()

    while estado.en_ejecucion:
        try:
            entrada = input(PROMPT)
        except (EOFError, KeyboardInterrupt):
            # Salida limpia en caso de Ctrl+D / Ctrl+C
            print()
            break

        partes = parsear(entrada)
        if not partes:
            continue

        nombre = partes[0].upper()
        args = partes[1:]

        handler = mapa.get(nombre)
        if handler is None:
            print("Error: comando no reconocido.")
            continue

        handler(args, estado)


if __name__ == "__main__":
    bucle_principal()
