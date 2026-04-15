extends Node3D
## Escena aparte: vista previa 3D + sliders estilo ARK. No modifica el menú principal.
## Ejecutar esta escena (F6) o cargarla desde código.

const MAIN_MENU := &"res://scenes/ui/main_menu.tscn"

@onready var _humanoid: ProceduralHumanoid = $ProceduralHumanoid
@onready var _pivot: Node3D = $CameraPivot

var _draft: CharacterDraft
var _sliders: Dictionary = {}

var _orbit_yaw: float = 0.0
var _orbit_pitch: float = 14.0


func _ready() -> void:
	_draft = CharacterStorage.load_draft()
	_setup_ui()
	_sync_sliders_from_draft()
	_humanoid.apply_draft(_draft)
	_apply_pivot()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		_orbit_yaw -= event.relative.x * 0.004
		_orbit_pitch -= event.relative.y * 0.004
		_orbit_pitch = clampf(_orbit_pitch, -12.0, 55.0)
		_apply_pivot()
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_ESCAPE:
		get_tree().change_scene_to_file(MAIN_MENU)


func _apply_pivot() -> void:
	_pivot.rotation_degrees = Vector3(_orbit_pitch, _orbit_yaw, 0.0)


func _setup_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(root)

	var panel := PanelContainer.new()
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.anchor_top = 0.0
	panel.anchor_bottom = 1.0
	panel.offset_left = -400.0
	panel.offset_right = -20.0
	panel.offset_top = 28.0
	panel.offset_bottom = -28.0
	root.add_child(panel)

	var flat := StyleBoxFlat.new()
	flat.bg_color = Color(0.04, 0.06, 0.1, 0.72)
	flat.border_color = Color(0.35, 0.78, 0.95, 0.45)
	flat.set_border_width_all(1)
	flat.set_corner_radius_all(10)
	flat.content_margin_left = 14
	flat.content_margin_top = 14
	flat.content_margin_right = 14
	flat.content_margin_bottom = 14
	panel.add_theme_stylebox_override(&"panel", flat)

	var margin := MarginContainer.new()
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override(&"separation", 10)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "Personaje procedural (ARK)"
	title.add_theme_font_size_override(&"font_size", 20)
	title.add_theme_color_override(&"font_color", Color(0.9, 0.95, 1.0))
	vbox.add_child(title)

	var hint := Label.new()
	hint.text = "Click derecho: girar cámara · Esc: menú"
	hint.add_theme_font_size_override(&"font_size", 11)
	hint.add_theme_color_override(&"font_color", Color(0.55, 0.65, 0.78))
	vbox.add_child(hint)

	_add_slider(vbox, "Altura", &"height_01")
	_add_slider(vbox, "Complexión", &"build_01")
	_add_slider(vbox, "Cabeza", &"head_size_01")
	_add_slider(vbox, "Brazos", &"arm_length_01")
	_add_slider(vbox, "Piernas", &"leg_length_01")
	_add_slider(vbox, "Tono piel", &"skin_tone_01")
	_add_slider(vbox, "Tono pelo", &"hair_tone_01")

	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 12)
	vbox.add_child(row)

	var btn_save := Button.new()
	btn_save.text = "Guardar borrador"
	btn_save.pressed.connect(_on_save_pressed)
	row.add_child(btn_save)

	var btn_menu := Button.new()
	btn_menu.text = "Menú"
	btn_menu.pressed.connect(func() -> void: get_tree().change_scene_to_file(MAIN_MENU))
	row.add_child(btn_menu)

	SaoUi.apply_to_buttons(vbox)


func _add_slider(vbox: VBoxContainer, label: String, prop: StringName) -> void:
	var l := Label.new()
	l.text = label
	l.add_theme_color_override(&"font_color", Color(0.75, 0.88, 1.0))
	vbox.add_child(l)
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.01
	s.custom_minimum_size.y = 22
	s.value_changed.connect(func(v: float) -> void: _on_slider_changed(prop, v))
	vbox.add_child(s)
	_sliders[prop] = s


func _on_slider_changed(prop: StringName, v: float) -> void:
	match String(prop):
		"height_01":
			_draft.height_01 = v
		"build_01":
			_draft.build_01 = v
		"head_size_01":
			_draft.head_size_01 = v
		"arm_length_01":
			_draft.arm_length_01 = v
		"leg_length_01":
			_draft.leg_length_01 = v
		"skin_tone_01":
			_draft.skin_tone_01 = v
		"hair_tone_01":
			_draft.hair_tone_01 = v
	_humanoid.apply_draft(_draft)


func _sync_sliders_from_draft() -> void:
	_set_slider(&"height_01", _draft.height_01)
	_set_slider(&"build_01", _draft.build_01)
	_set_slider(&"head_size_01", _draft.head_size_01)
	_set_slider(&"arm_length_01", _draft.arm_length_01)
	_set_slider(&"leg_length_01", _draft.leg_length_01)
	_set_slider(&"skin_tone_01", _draft.skin_tone_01)
	_set_slider(&"hair_tone_01", _draft.hair_tone_01)


func _set_slider(prop: StringName, v: float) -> void:
	var s: HSlider = _sliders[prop] as HSlider
	if s:
		s.set_value_no_signal(v)


func _on_save_pressed() -> void:
	var err: Error = CharacterStorage.save_draft(_draft)
	if err != OK:
		push_error("No se pudo guardar: %s" % error_string(err))
	else:
		print("Borrador guardado (incluye sliders procedurales).")
