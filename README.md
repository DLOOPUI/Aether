# Aether

Proyecto en **Godot 4.6** (Forward Plus): acción en **tercera persona**, mundo **abierto**, tono **anime** y referencia de loop tipo **sandbox urbano / RPG** (sin comprometer aún sistemas online masivos).

## Cómo abrir el proyecto

1. Clona el repositorio.
2. Abre la carpeta del proyecto en **Godot 4.6** (importar si hace falta).
3. Escena principal: `scenes/ui/main_menu.tscn`. Ejecución: **F5**.

## Árbol de carpetas

```
Aether/
├── project.godot
├── icon.svg
├── scenes/
│   ├── ui/                    # Menús, HUD, pantallas
│   └── gameplay/              # Niveles y escenas jugables 3D
├── scripts/
│   ├── core/                  # Datos compartidos, constantes, recursos
│   ├── ui/                    # Lógica de interfaz
│   ├── gameplay/              # Jugador, control de cámara, prototipos
│   └── systems/               # Reglas globales (cuando existan)
├── assets/
│   ├── ui/                    # Fondos del menú, elementos 2D de UI
│   ├── art/                   # Modelos, texturas, materiales
│   ├── audio/                 # Música y SFX
│   └── fonts/                 # Tipografías
├── docs/                      # GDD, arquitectura, diagramas, empaquetado
├── tools/                     # Scripts fuera del runtime (export, utilidades)
└── .github/workflows/         # CI (placeholder hasta definir pipeline)
```

## Controles (prototipo de play)

En la escena de prueba `prototype_playground.tscn`: **WASD**, **Espacio**, ratón; **Esc** vuelve al menú.

## Fondo del menú

Opcional: coloca `menu_background.png` o `menu_background.jpg` en `assets/ui/` (ver `assets/ui/README.md`).

## Documentación adicional

| Archivo | Contenido |
|---------|-----------|
| [`docs/gdd-one-pager.md`](docs/gdd-one-pager.md) | Diseño en una página |
| [`docs/architecture.md`](docs/architecture.md) | Convenciones de código y escenas |
| [`docs/diagrams/`](docs/diagrams/) | Diagramas (estados, loop) |
| [`docs/packaging.md`](docs/packaging.md) | Export e instaladores |
| [`docs/roadmap.md`](docs/roadmap.md) | Líneas de trabajo y mejoras previstas |

## Licencia

Por definir.
