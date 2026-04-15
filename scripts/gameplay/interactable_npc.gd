class_name InteractableNpc
extends Node3D
## NPC de prueba: pulsa E cerca para abrir el diálogo registrado en DialogueManager.

@export var dialogue_id: String = "plaza_npc_intro"
@export var interact_distance: float = 4.0


func try_interact(player_pos: Vector3) -> bool:
	var d: Dialogue = DialogueManager.get_dialogue(dialogue_id)
	if d == null:
		return false
	if DialogueManager.is_dialogue_active():
		return false
	if global_position.distance_to(player_pos) > interact_distance:
		return false
	DialogueManager.start_dialogue(d)
	return true
