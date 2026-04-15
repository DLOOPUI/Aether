class_name Dialogue
extends Resource

@export var id: String = ""
@export var speaker_name: String = ""
@export var lines: Array[String] = []
@export var choices: Array[String] = [] ## Respuestas del jugador (tras leer todas las líneas).
@export var next_dialogue_ids: Array[String] = [] ## Siguiente `Dialogue.id` por cada opción; vacío = terminar tras elegir.
@export var quest_start_id: String = "" ## Añade misión desde plantilla (`QuestManager.add_quest_by_template_id`).
@export var quest_complete_id: String = "" ## Al cerrar este diálogo (sin ramificar a otro), avanza un objetivo de esta misión.


func get_current_line(index: int) -> String:
	if index >= 0 and index < lines.size():
		return lines[index]
	return ""
