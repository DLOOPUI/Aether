extends Node3D

const MAIN_MENU := &"res://scenes/ui/main_menu.tscn"
const SETTINGS_SCENE := preload("res://scenes/ui/settings.tscn")

@onready var _pause: CanvasLayer = $PauseOverlay
@onready var _npc: Node3D = $NpcPlaza
@onready var _player: Node3D = $Player


func _ready() -> void:
	_pause.hide_pause()
	_pause.resume_pressed.connect(_on_pause_resume)
	_pause.main_menu_pressed.connect(_on_pause_main_menu)
	_pause.settings_pressed.connect(_on_pause_settings)


func _unhandled_input(event: InputEvent) -> void:
	if event == null:
		return
	if DialogueManager.is_dialogue_active():
		return
	if get_tree().paused:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_E:
		if _npc is InteractableNpc and (_npc as InteractableNpc).try_interact(_player.global_position):
			get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_J:
		QuestManager.toggle_quest_log()
		if QuestManager.is_quest_log_open():
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		get_viewport().set_input_as_handled()
		return
	if OS.is_debug_build() and event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_F1:
				QuestManager.update_quest_progress("tutorial_plaza")
				get_viewport().set_input_as_handled()
				return
			KEY_F2:
				QuestManager.update_quest_progress("collect_apples")
				get_viewport().set_input_as_handled()
				return
			KEY_F3:
				QuestManager.update_quest_progress("slime_hunt")
				get_viewport().set_input_as_handled()
				return
	if event.is_action_pressed(&"ui_cancel"):
		if QuestManager.is_quest_log_open():
			QuestManager.toggle_quest_log()
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			get_viewport().set_input_as_handled()
			return
		_open_pause()
		get_viewport().set_input_as_handled()
		return


func _open_pause() -> void:
	get_tree().paused = true
	_pause.show_pause()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _on_pause_resume() -> void:
	get_tree().paused = false
	_pause.hide_pause()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _on_pause_main_menu() -> void:
	get_tree().paused = false
	_pause.hide_pause()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file(MAIN_MENU)


func _on_pause_settings() -> void:
	var layer := CanvasLayer.new()
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	layer.layer = 60
	var panel: Control = SETTINGS_SCENE.instantiate()
	panel.exit_to_parent = true
	panel.close_requested.connect(_on_settings_overlay_closed.bind(layer))
	layer.add_child(panel)
	add_child(layer)


func _on_settings_overlay_closed(layer: CanvasLayer) -> void:
	layer.queue_free()
	_pause.focus_resume_button()
