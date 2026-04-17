extends Node
## Configura las acciones de entrada necesarias para el juego al iniciar.

func _ready() -> void:
	_setup_combat_inputs()
	print("Inputs configurados: attack, block, special")


func _setup_combat_inputs() -> void:
	# Acción: attack (ataque básico)
	_add_input_action(&"attack", [
		_create_mouse_button_event(MOUSE_BUTTON_LEFT),
		_create_key_event(KEY_F),
		_create_joypad_button_event(JOY_BUTTON_RIGHT_SHOULDER)
	])
	
	# Acción: block (bloqueo/defensa)
	_add_input_action(&"block", [
		_create_mouse_button_event(MOUSE_BUTTON_RIGHT),
		_create_key_event(KEY_E),
		_create_joypad_button_event(JOY_BUTTON_LEFT_SHOULDER)
	])
	
	# Acción: special (ataque especial)
	_add_input_action(&"special", [
		_create_key_event(KEY_R),
		_create_joypad_button_event(JOY_BUTTON_Y)
	])


func _add_input_action(action: StringName, events: Array[InputEvent]) -> void:
	# Si la acción ya existe, no hacer nada
	if InputMap.has_action(action):
		return
	
	InputMap.add_action(action)
	
	for event in events:
		if not _action_has_event(action, event):
			InputMap.action_add_event(action, event)


func _action_has_event(action: StringName, event: InputEvent) -> bool:
	for existing in InputMap.action_get_events(action):
		if _events_equal(existing, event):
			return true
	return false


func _events_equal(a: InputEvent, b: InputEvent) -> bool:
	if a.get_class() != b.get_class():
		return false
	
	if a is InputEventKey and b is InputEventKey:
		return a.physical_keycode == b.physical_keycode
	elif a is InputEventMouseButton and b is InputEventMouseButton:
		return a.button_index == b.button_index
	elif a is InputEventJoypadButton and b is InputEventJoypadButton:
		return a.button_index == b.button_index
	
	return false


func _create_key_event(keycode: int) -> InputEventKey:
	var event = InputEventKey.new()
	event.physical_keycode = keycode
	return event


func _create_mouse_button_event(button: int) -> InputEventMouseButton:
	var event = InputEventMouseButton.new()
	event.button_index = button
	return event


func _create_joypad_button_event(button: int) -> InputEventJoypadButton:
	var event = InputEventJoypadButton.new()
	event.button_index = JoyButton(button)
	event.device = -1  # Todos los dispositivos
	return event