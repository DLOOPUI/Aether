extends Resource
## Datos de personaje: ropa (menú) + proporciones y tonos (vista previa ARK / procedural).
class_name CharacterDraft

@export var gender_id: int = 0
@export var race_id: int = 0
@export var top_id: int = 0
@export var pants_id: int = 0
@export var shoes_id: int = 0
@export var hair_id: int = 0

# --- Procedural (0.0 = mínimo, 1.0 = máximo; por defecto ~medio) ---
@export var height_01: float = 0.5
@export var build_01: float = 0.5
@export var head_size_01: float = 0.5
@export var arm_length_01: float = 0.5
@export var leg_length_01: float = 0.5
@export var skin_tone_01: float = 0.35
@export var hair_tone_01: float = 0.25
