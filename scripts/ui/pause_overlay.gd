extends CanvasLayer
## UI de pausa: corre con el árbol en pausa (`PROCESS_MODE_ALWAYS`). Esc cierra pausa.

signal resume_pressed
signal main_menu_pressed
signal settings_pressed


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		resume_pressed.emit()


func show_pause() -> void:
	visible = true
	var b: Button = %BtnResume
	if b:
		b.grab_focus()


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
