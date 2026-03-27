"""Manejo del estado global del sistema CMD en español."""

from dataclasses import dataclass


VERSION = "CMD Español v0.1"


@dataclass
class Estado:
    """Estado simple del ciclo principal."""

    en_ejecucion: bool = True

    def detener(self) -> None:
        """Detiene la ejecución del bucle principal."""
        self.en_ejecucion = False

