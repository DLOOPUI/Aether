# Aether

Juego de **mundo abierto** en **tercera persona**, inspiración tipo **GTA**, estética **anime**. Motor: **Godot 4**.

## Requisitos

- [Godot 4.3+](https://godotengine.org/download) (Forward Plus recomendado para 3D).

## Cómo abrir

1. Clona el repo.
2. En Godot: **Import** → selecciona la carpeta que contiene `project.godot`.
3. Pulsa **Run** (F5): arranca en el **menú principal**.

## Estructura del repo

| Ruta | Uso |
|------|-----|
| `scenes/` | Escenas `.tscn` (UI, gameplay, niveles). |
| `scripts/` | Código GDScript por dominio (`core`, `ui`, `systems`). |
| `assets/` | Arte, audio, fuentes (considera **Git LFS** para binarios pesados). |
| `docs/` | GDD breve, arquitectura, diagramas. |
| `tools/` | Scripts de automatización o helpers. |

## Próximos pasos sugeridos

- Sustituir el menú placeholder por tema visual anime + navegación con mando/teclado.
- Añadir escena **gameplay** mínima: personaje 3rd person + suelo + cámara (prototipo, no ciudad completa).

## Licencia

Por definir (añade `LICENSE` cuando el equipo elija una).
