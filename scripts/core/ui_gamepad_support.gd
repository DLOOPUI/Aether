extends Node
## Registra acciones de menú (teclado + mando, device -1 = todos los mandos) y expone estado de conexión.
## Equivale a definir el Input Map en project.godot: al ejecutar el juego, las acciones quedan en InputMap
## (Project Settings → Input Map muestra el mismo resultado tras guardar el proyecto desde el editor).

signal gamepads_changed(count: int)

var connected_joypads: int = 0


func _ready() -> void:
	_ensure_input_actions()
	_refresh_joypads()
	Input.joy_connection_changed.connect(_on_joy_connection_changed)


func _on_joy_connection_changed(_device: int, _connected: bool) -> void:
	_refresh_joypads()


func _refresh_joypads() -> void:
	connected_joypads = Input.get_connected_joypads().size()
	gamepads_changed.emit(connected_joypads)


func has_gamepad() -> bool:
	return connected_joypads > 0


func _ensure_input_actions() -> void:
	_register_ui_core()
	_register_menu_tabs()


func _register_ui_core() -> void:
	# Navegación y confirmación (viewport / foco UI).
	_action_ensure(&"ui_left")
	_merge_key(&"ui_left", KEY_LEFT)
	_merge_joy_btn(&"ui_left", JOY_BUTTON_DPAD_LEFT)
	_merge_axis(&"ui_left", JOY_AXIS_LEFT_X, -1.0)

	_action_ensure(&"ui_right")
	_merge_key(&"ui_right", KEY_RIGHT)
	_merge_joy_btn(&"ui_right", JOY_BUTTON_DPAD_RIGHT)
	_merge_axis(&"ui_right", JOY_AXIS_LEFT_X, 1.0)

	_action_ensure(&"ui_up")
	_merge_key(&"ui_up", KEY_UP)
	_merge_joy_btn(&"ui_up", JOY_BUTTON_DPAD_UP)
	_merge_axis(&"ui_up", JOY_AXIS_LEFT_Y, -1.0)

	_action_ensure(&"ui_down")
	_merge_key(&"ui_down", KEY_DOWN)
	_merge_joy_btn(&"ui_down", JOY_BUTTON_DPAD_DOWN)
	_merge_axis(&"ui_down", JOY_AXIS_LEFT_Y, 1.0)

	_action_ensure(&"ui_accept")
	_merge_key(&"ui_accept", KEY_ENTER)
	_merge_key(&"ui_accept", KEY_KP_ENTER)
	_merge_key(&"ui_accept", KEY_SPACE)
	_merge_joy_btn(&"ui_accept", JOY_BUTTON_A)

	_action_ensure(&"ui_cancel")
	_merge_key(&"ui_cancel", KEY_ESCAPE)
	_merge_joy_btn(&"ui_cancel", JOY_BUTTON_B)

	_action_ensure(&"ui_focus_next")
	_merge_key_raw(&"ui_focus_next", KEY_TAB, false)

	_action_ensure(&"ui_focus_prev")
	_merge_key_raw(&"ui_focus_prev", KEY_TAB, true)


func _register_menu_tabs() -> void:
	_action_ensure(&"menu_tab_prev")
	_merge_key(&"menu_tab_prev", KEY_Q)
	_merge_joy_btn(&"menu_tab_prev", JOY_BUTTON_LEFT_SHOULDER)

	_action_ensure(&"menu_tab_next")
	_merge_key(&"menu_tab_next", KEY_E)
	_merge_joy_btn(&"menu_tab_next", JOY_BUTTON_RIGHT_SHOULDER)


func _action_ensure(action: StringName) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.5)


func _merge_key(action: StringName, keycode: Key) -> void:
	_merge_key_raw(action, keycode, false)


func _merge_key_raw(action: StringName, keycode: Key, shift: bool) -> void:
	var ev := InputEventKey.new()
	ev.device = -1
	ev.physical_keycode = keycode
	ev.keycode = keycode
	ev.shift_pressed = shift
	if _action_has_equivalent_key(action, ev):
		return
	InputMap.action_add_event(action, ev)


func _action_has_equivalent_key(action: StringName, candidate: InputEventKey) -> bool:
	for ev in InputMap.action_get_events(action):
		if ev is InputEventKey:
			var k := ev as InputEventKey
			if (
				k.physical_keycode == candidate.physical_keycode
				and k.shift_pressed == candidate.shift_pressed
			):
				return true
	return false


func _merge_joy_btn(action: StringName, button: int) -> void:
	var ev := InputEventJoypadButton.new()
	ev.device = -1
	ev.button_index = button
	if _action_has_joy_btn(action, button):
		return
	InputMap.action_add_event(action, ev)


func _action_has_joy_btn(action: StringName, button: int) -> bool:
	for ev in InputMap.action_get_events(action):
		if ev is InputEventJoypadButton:
			var j := ev as InputEventJoypadButton
			if j.button_index == button and j.device == -1:
				return true
	return false


func _merge_axis(action: StringName, axis: int, sign: float) -> void:
	var ev := InputEventJoypadMotion.new()
	ev.device = -1
	ev.axis = axis
	ev.axis_value = sign
	if _action_has_axis(action, axis, sign):
		return
	InputMap.action_add_event(action, ev)


func _action_has_axis(action: StringName, axis: int, sign: float) -> bool:
	for ev in InputMap.action_get_events(action):
		if ev is InputEventJoypadMotion:
			var m := ev as InputEventJoypadMotion
			if m.axis == axis and is_equal_approx(m.axis_value, sign) and m.device == -1:
				return true
	return false
