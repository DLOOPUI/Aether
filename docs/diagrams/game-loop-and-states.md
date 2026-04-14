# Diagramas — loop y estados

## Game loop (alto nivel)

```mermaid
flowchart LR
  subgraph frame [Cada frame]
    I[Input] --> U[Update / physics]
    U --> R[Render + audio]
  end
  R --> I
```

## Estados del juego (propuesta)

```mermaid
stateDiagram-v2
  [*] --> Boot
  Boot --> MainMenu
  MainMenu --> Loading : Nueva partida / Continuar
  Loading --> Gameplay
  Gameplay --> Pause : Pausa
  Pause --> Gameplay : Reanudar
  Pause --> MainMenu : Salir al menú
  Gameplay --> MainMenu : Salir seguro
  MainMenu --> [*] : Salir del juego
```

Godot suele implementarse con **cambio de escena** (`change_scene_to_packed`) o un **árbol** bajo un `GameRoot` que muestra/oculta capas. Documentad la opción elegida en `architecture.md` cuando la implementéis.
