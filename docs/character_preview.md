# Vista previa procedural (estilo ARK)

Escena **aislada**: `scenes/character/character_preview_ark.tscn`

- Modelo **solo con primitivas** (cápsulas + esferas) generado en `scripts/character/procedural_humanoid.gd`.
- **Sliders** (altura, complexión, cabeza, brazos, piernas, tono de piel y pelo) modifican `CharacterDraft` y se pueden **guardar** en `user://character_draft.tres` igual que en el menú.
- **Click derecho** arrastra la cámara alrededor del personaje. **Esc** vuelve al menú principal.

## Cómo probar

En Godot: abre la escena → **Escena actual como principal** temporalmente, o **Ejecutar escena actual** (F6).

## Integración opcional (cuando quieras)

Desde tu menú, un botón puede hacer `get_tree().change_scene_to_file("res://scenes/character/character_preview_ark.tscn")` sin tocar esta escena.
