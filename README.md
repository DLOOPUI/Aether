# Aether

Visión a largo plazo: **mundo abierto**, **RPG**, referencia de sandbox tipo **GTA** en tercera persona, estética **anime**. Motor: **Godot 4**. *(MMO u otros sistemas masivos: fuera del MVP hasta tener núcleo sólido.)*

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

## Jugar (prototipo)

Desde el menú, **Jugar** abre `scenes/gameplay/prototype_playground.tscn`: suelo, cápsula jugador, cámara en tercera persona (**WASD**, **Espacio**, ratón; **Esc** → menú).

## Export / instalador

Resumen en [`docs/packaging.md`](docs/packaging.md): primero **export** de Godot; un instalador tipo Setup es un paso posterior.

## Próximos pasos sugeridos

- Tema UI más “anime” (fuentes, ilustración de fondo, sonido al foco).
- Mando (input map de Godot) y opciones en **Ajustes**.

## Licencia

Por definir (añade `LICENSE` cuando el equipo elija una).
