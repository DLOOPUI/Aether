extends Node
## Autoload: conversaciones, pausa del juego mientras hay texto, ramas y enganche con misiones.

signal dialogue_started(dialogue: Dialogue)
signal dialogue_ended(dialogue: Dialogue)
signal choice_selected(choice_index: int)
signal dialogue_ui_refresh

var current_dialogue: Dialogue = null
var current_line: int = 0
var _showing_choices: bool = false

var _dialogue_by_id: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var ui: CanvasLayer = preload("res://scenes/ui/dialogue_ui.tscn").instantiate()
	call_deferred("add_child", ui)
	_register_dialogues()


func is_dialogue_active() -> bool:
	return current_dialogue != null


func is_showing_choices() -> bool:
	return _showing_choices


func get_display_text() -> String:
	if current_dialogue == null:
		return ""
	if _showing_choices:
		return ""
	return current_dialogue.get_current_line(current_line)


func get_speaker_name() -> String:
	if current_dialogue:
		return current_dialogue.speaker_name
	return ""


func get_current_choices() -> Array[String]:
	if current_dialogue != null and _showing_choices:
		return current_dialogue.choices.duplicate()
	return []


func register_dialogue(dialogue: Dialogue) -> void:
	if dialogue.id.is_empty():
		push_warning("Diálogo sin id; no registrado.")
		return
	_dialogue_by_id[dialogue.id] = dialogue


func get_dialogue(dialogue_id: String) -> Dialogue:
	return _dialogue_by_id.get(dialogue_id) as Dialogue


func start_dialogue(dialogue: Dialogue) -> void:
	if dialogue == null:
		return
	if is_dialogue_active():
		push_warning("Ya hay un diálogo activo.")
		return
	current_dialogue = dialogue
	current_line = 0
	_showing_choices = false
	if not dialogue.quest_start_id.is_empty():
		QuestManager.add_quest_by_template_id(dialogue.quest_start_id)
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	dialogue_started.emit(dialogue)
	dialogue_ui_refresh.emit()


func advance_line() -> void:
	if current_dialogue == null or _showing_choices:
		return
	current_line += 1
	if current_line >= current_dialogue.lines.size():
		if not current_dialogue.choices.is_empty():
			_showing_choices = true
			dialogue_ui_refresh.emit()
			return
		_close_dialogue_session()
		return
	dialogue_ui_refresh.emit()


func select_choice(choice_index: int) -> void:
	if current_dialogue == null or not _showing_choices:
		return
	choice_selected.emit(choice_index)
	var ended: Dialogue = current_dialogue
	var ids: Array = ended.next_dialogue_ids
	_showing_choices = false
	current_dialogue = null
	current_line = 0
	_apply_quest_complete(ended)
	if choice_index >= 0 and choice_index < ids.size():
		var nid: String = str(ids[choice_index])
		if not nid.is_empty():
			var next_d: Dialogue = get_dialogue(nid)
			if next_d:
				dialogue_ended.emit(ended)
				start_dialogue(next_d)
				return
	dialogue_ended.emit(ended)
	_unpause_game()
	dialogue_ui_refresh.emit()


func end_dialogue() -> void:
	_close_dialogue_session()


## Cierra sin aplicar `quest_complete_id` (Esc / B).
func skip_dialogue() -> void:
	if not is_dialogue_active():
		return
	var ended: Dialogue = current_dialogue
	current_dialogue = null
	current_line = 0
	_showing_choices = false
	if ended:
		dialogue_ended.emit(ended)
	_unpause_game()
	dialogue_ui_refresh.emit()


func _close_dialogue_session() -> void:
	var ended: Dialogue = current_dialogue
	current_dialogue = null
	current_line = 0
	_showing_choices = false
	if ended:
		_apply_quest_complete(ended)
		dialogue_ended.emit(ended)
	_unpause_game()
	dialogue_ui_refresh.emit()


func _apply_quest_complete(d: Dialogue) -> void:
	if d == null:
		return
	if not d.quest_complete_id.is_empty():
		QuestManager.update_quest_progress(d.quest_complete_id)


func _unpause_game() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _register_dialogues() -> void:
	var plaza := Dialogue.new()
	plaza.id = "plaza_npc_intro"
	plaza.speaker_name = "Viajero"
	plaza.lines = [
		"¡Hola! Soy un NPC de prueba en el prototipo.",
		"Cuando terminemos de leer, se puede registrar progreso en la misión «Bienvenida».",
		"Elige una respuesta para continuar.",
	]
	plaza.choices = ["Gracias.", "¿Y las manzanas?"]
	plaza.next_dialogue_ids = ["", "plaza_more_quests"]
	plaza.quest_start_id = ""
	plaza.quest_complete_id = "tutorial_plaza"
	register_dialogue(plaza)

	var more := Dialogue.new()
	more.id = "plaza_more_quests"
	more.speaker_name = "Viajero"
	more.lines = [
		"La recolección aún no está en escena; por ahora esta línea inicia la misión de manzanas en el registro.",
	]
	more.choices = []
	more.next_dialogue_ids = []
	more.quest_start_id = "collect_apples"
	more.quest_complete_id = ""
	register_dialogue(more)
