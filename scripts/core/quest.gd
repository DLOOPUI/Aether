class_name Quest
extends Resource

enum QuestState { NOT_STARTED, IN_PROGRESS, COMPLETED, FAILED }

@export var id: String = ""
@export var title: String = ""
@export var description: String = ""
@export var objectives: Array[String] = []
@export var rewards: Dictionary = {} ## p.ej. {"gold": 100, "items": ["item_id"]}

var state: QuestState = QuestState.NOT_STARTED
var current_objective: int = 0


func start() -> void:
	state = QuestState.IN_PROGRESS
	current_objective = 0


func fail() -> void:
	state = QuestState.FAILED


func complete_objective() -> bool:
	current_objective += 1
	if current_objective >= objectives.size():
		state = QuestState.COMPLETED
		return true
	return false


func is_complete() -> bool:
	return state == QuestState.COMPLETED


## Objetivo actual (pendiente) según el contador interno.
func current_objective_label() -> String:
	if objectives.is_empty():
		return ""
	if current_objective >= objectives.size():
		return objectives[objectives.size() - 1]
	return objectives[current_objective]


func progress_text() -> String:
	if objectives.is_empty():
		return ""
	return "%d / %d" % [mini(current_objective, objectives.size()), objectives.size()]
