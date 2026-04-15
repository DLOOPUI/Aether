extends CanvasLayer
## UI de pausa: corre con el árbol en pausa (`PROCESS_MODE_ALWAYS`). Esc / ui_cancel reanudan.

signal resume_pressed
signal main_menu_pressed
signal settings_pressed

var _gamepad_hint: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_setup_gamepad_hint()
	UiGamepadSupport.gamepads_changed.connect(_on_gamepads_changed)
	_on_gamepads_changed(UiGamepadSupport.connected_joypads)


func _setup_gamepad_hint() -> void:
	_gamepad_hint = Label.new()
	_gamepad_hint.text = "Mando: B reanudar · ↑↓ navegar"
	_gamepad_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_gamepad_hint.add_theme_color_override(&"font_color", Color(0.55, 0.82, 0.98, 0.9))
	_gamepad_hint.add_theme_font_size_override(&"font_size", 10)
	_gamepad_hint.visible = false
	_gamepad_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Center/Panel/VBox.add_child(_gamepad_hint)
	$Center/Panel/VBox.move_child(_gamepad_hint, 2)


func _on_gamepads_changed(count: int) -> void:
	if _gamepad_hint:
		_gamepad_hint.visible = count > 0


func _input(event: InputEvent) -> void:
	if event == null:
		return
	if not visible:
		return
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		resume_pressed.emit()


func show_pause() -> void:
	visible = true
	var b: Button = %BtnResume
	if b:
		b.grab_focus()
	if _gamepad_hint:
		_gamepad_hint.visible = UiGamepadSupport.has_gamepad()


func focus_resume_button() -> void:
	var b: Button = %BtnResume
	if b:
		b.grab_focus()


func hide_pause() -> void:
	visible = false


func _on_resume_button_pressed() -> void:
	resume_pressed.emit()


func _on_menu_button_pressed() -> void:
	main_menu_pressed.emit()


func _on_settings_button_pressed() -> void:
	settings_pressed.emit()
