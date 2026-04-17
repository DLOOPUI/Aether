extends CanvasLayer
## UI de pausa: corre con el árbol en pausa (`PROCESS_MODE_ALWAYS`). Esc / ui_cancel reanudan.

signal resume_pressed
signal main_menu_pressed
signal settings_pressed
signal save_slot_pressed(slot_index: int)

var _gamepad_hint: Label
var _save_popup: PopupMenu
var _overwrite_confirm: ConfirmationDialog
var _pending_overwrite_slot: int = -1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_save_popup = PopupMenu.new()
	add_child(_save_popup)
	_save_popup.id_pressed.connect(_on_save_popup_id)
	_overwrite_confirm = ConfirmationDialog.new()
	_overwrite_confirm.title = "Sobrescribir"
	_overwrite_confirm.ok_button_text = "Sobrescribir"
	_overwrite_confirm.cancel_button_text = "Cancelar"
	_overwrite_confirm.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_overwrite_confirm)
	_overwrite_confirm.confirmed.connect(_on_overwrite_confirmed)
	_overwrite_confirm.canceled.connect(_on_overwrite_canceled)
	var b_save: Button = get_node_or_null("Center/Panel/VBox/BtnSave") as Button
	if b_save:
		b_save.pressed.connect(_on_save_button_pressed)
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


func _on_save_button_pressed() -> void:
	if _save_popup == null:
		return
	_save_popup.clear()
	for i in range(SaveSlots.SLOT_COUNT):
		_save_popup.add_item(SaveSlots.get_slot_summary(i), i)
	var b: Button = get_node_or_null("Center/Panel/VBox/BtnSave") as Button
	if b:
		var rect := b.get_global_rect()
		_save_popup.position = rect.position + Vector2(0.0, rect.size.y + 4.0)
	else:
		_save_popup.position = get_viewport().get_mouse_position()
	_save_popup.reset_size()
	_save_popup.popup()


func _on_save_popup_id(id: int) -> void:
	var slot: int = int(id)
	if SaveSlots.slot_has_data(slot):
		_pending_overwrite_slot = slot
		_overwrite_confirm.dialog_text = (
			"La ranura %d ya tiene una partida guardada. ¿Sobrescribir?" % (slot + 1)
		)
		_overwrite_confirm.popup_centered()
	else:
		save_slot_pressed.emit(slot)


func _on_overwrite_confirmed() -> void:
	var s: int = _pending_overwrite_slot
	_pending_overwrite_slot = -1
	if s >= 0:
		save_slot_pressed.emit(s)


func _on_overwrite_canceled() -> void:
	_pending_overwrite_slot = -1
