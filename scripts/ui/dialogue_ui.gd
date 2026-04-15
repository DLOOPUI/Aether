extends CanvasLayer
## Muestra texto y opciones; avanza con Aceptar / clic; Esc cierra sin completar misión.

@onready var _speaker: Label = $Panel/Margin/VBox/Header/SpeakerLabel
@onready var _body: RichTextLabel = $Panel/Margin/VBox/Body
@onready var _choices: VBoxContainer = $Panel/Margin/VBox/Choices
@onready var _hint: Label = $Panel/Margin/VBox/Hint


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 55
	visible = false
	_hint.text = "Aceptar / clic: continuar · Esc / B: salir sin completar objetivo"
	DialogueManager.dialogue_started.connect(_on_dialogue_started)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)
	DialogueManager.dialogue_ui_refresh.connect(_refresh)


func _on_dialogue_started(_d: Dialogue) -> void:
	visible = true
	_refresh()


func _on_dialogue_ended(_d: Dialogue) -> void:
	call_deferred(&"_sync_visibility")


func _sync_visibility() -> void:
	visible = DialogueManager.is_dialogue_active()
	if not visible:
		for c in _choices.get_children():
			c.queue_free()


func _refresh() -> void:
	if not DialogueManager.is_dialogue_active():
		return
	_speaker.text = DialogueManager.get_speaker_name()
	if DialogueManager.is_showing_choices():
		_body.text = "[center]—[/center]"
		for c in _choices.get_children():
			c.queue_free()
		var idx := 0
		for label_text in DialogueManager.get_current_choices():
			var btn := Button.new()
			btn.text = label_text
			var i := idx
			btn.pressed.connect(func() -> void: DialogueManager.select_choice(i))
			_choices.add_child(btn)
			idx += 1
		SaoUi.apply_to_buttons(_choices)
	else:
		for c in _choices.get_children():
			c.queue_free()
		_body.text = DialogueManager.get_display_text()


func _input(event: InputEvent) -> void:
	if not visible or not DialogueManager.is_dialogue_active():
		return
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		DialogueManager.skip_dialogue()
		return
	if DialogueManager.is_showing_choices():
		return
	if event.is_action_pressed(&"ui_accept"):
		get_viewport().set_input_as_handled()
		DialogueManager.advance_line()
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var rect: Rect2 = _body.get_global_rect()
		if rect.has_point(event.position):
			get_viewport().set_input_as_handled()
			DialogueManager.advance_line()
