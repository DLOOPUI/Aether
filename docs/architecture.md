# Arquitectura — Aether (Godot)

## Principios

- **Escenas como composición**: pantallas y sistemas encapsulados en nodos reutilizables.
- **Autoloads con moderación**: solo para servicios transversales (audio, partida guardada, flags globales) cuando haga falta; no abusar el primer día.
- **Separación UI / gameplay**: menús en `scenes/ui/`, mundo y personaje en `scenes/gameplay/`.

## Carpetas de scripts

| Módulo | Responsabilidad |
|--------|-----------------|
| `scripts/core/` | Constantes, utilidades, tipos compartidos. |
| `scripts/ui/` | Lógica de menús y HUD. |
| `scripts/systems/` | Reglas que orquestan varias entidades (misiones, día/noche, etc.) cuando crezcan. |

## Game loop (Godot)

Godot ya ejecuta `_process` / `_physics_process` por nodo. Convención del proyecto:

1. **Input** en el jugador o en un `Input`-wrapper ligero.
2. **Simulación** en `_physics_process` (movimiento, colisiones).
3. **Presentación** en `_process` o señales (animaciones, UI).

Ver diagramas en `docs/diagrams/`.

## Próximas decisiones (ADRs)

Crear archivos cortos `docs/decisions/NNN-titulo.md` cuando elijáis cosas difíciles de revertir (ECS vs nodos, sistema de misiones, formato de datos).
