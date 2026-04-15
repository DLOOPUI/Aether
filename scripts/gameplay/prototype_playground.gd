extends Node3D

const MAIN_MENU := &"res://scenes/ui/main_menu.tscn"
const SETTINGS_SCENE := preload("res://scenes/ui/settings.tscn")

@onready var _pause: CanvasLayer = $PauseOverlay


func _ready() -> void:
	_pause.hide_pause()
	_pause.resume_pressed.connect(_on_pause_resume)
	_pause.main_menu_pressed.connect(_on_pause_main_menu)
	_pause.settings_pressed.connect(_on_pause_settings)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_ESCAPE:
		if get_tree().paused:
			return
		_open_pause()


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
