"""Roles de la oficina: cada agente es un empleado con un rol.

Solo datos (dataclasses) — sin lógica. El "quién trabaja" lo decide CrewAI;
este módulo define el catálogo de roles que la oficina puede contratar.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from enum import Enum


class RoleKind(str, Enum):
    PRODUCTO = "producto"
    ARQUITECTO = "arquitecto"
    DEV = "dev"
    QA = "qa"
    DEVOPS = "devops"
    REVISOR = "revisor"
    PM = "pm"


class OfficeState(str, Enum):
    """Estados visibles en la oficina animada (espejo del grafo)."""

    IDLE = "idle"          # 💤 inactivo, listo
    WORKING = "working"    # ⚡ trabajando
    BLOCKED = "blocked"    # 🚧 bloqueado
    WAITING_APPROVAL = "waiting_approval"  # ⏳ espera aprobación humana
    DONE = "done"          # ✅ terminó su parte


@dataclass
class AgentRole:
    """Un rol contratable de la oficina (empleado abstracto)."""

    kind: RoleKind
    title: str
    icon: str
    runtime: str = "opencode"  # runtime del agente que ocupa este rol
    skills: list[str] = field(default_factory=list)

    def to_canva(self) -> dict:
        """Estado mínimo que la app Flutter renderiza como personaje."""
        return {
            "kind": self.kind.value,
            "title": self.title,
            "icon": self.icon,
            "runtime": self.runtime,
        }


# Catálogo base de roles de la oficina.
DEFAULT_ROLES: list[AgentRole] = [
    AgentRole(RoleKind.PRODUCTO, "Producto", "🎯", skills=["producto", "historias"]),
    AgentRole(RoleKind.ARQUITECTO, "Arquitecto", "🏛️", skills=["arquitectura", "sdd"]),
    AgentRole(RoleKind.DEV, "Dev", "👨‍💻", skills=["implementar", "tdd"]),
    AgentRole(RoleKind.QA, "QA", "🧪", skills=["pruebas", "regresiones"]),
    AgentRole(RoleKind.DEVOPS, "Devops", "⚙️", skills=["build", "deploy", "infra"]),
    AgentRole(RoleKind.REVISOR, "Revisor", "🔍", skills=["code-review"]),
    AgentRole(RoleKind.PM, "PM", "📋", skills=["coordinar", "reportar"]),
]
