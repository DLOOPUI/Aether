extends Control
class_name HudMmo
## HUD estilo MMO: unidad (vida / estamina / XP), minimapa, oleadas, habilidades (bloqueadas) y barra rápida 9 slots.

const HEALTH_BAR_SCENE := preload("res://scenes/ui/health_bar.tscn")
const EXPERIENCE_BAR_SCENE := preload("res://scenes/ui/experience_bar.tscn")

var wave_label: Label
var stats_label: Label

var _top_right: Control
var _bottom_center: Control
var _stamina_bar: ProgressBar
var _stamina_caption: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_top_left()
	_build_top_right()
	_build_bottom()
	get_viewport().size_changed.connect(_reflow_corners)
	call_deferred("_reflow_corners")


func _build_top_left() -> void:
	var col := VBoxContainer.new()
	col.name = "TopLeftColumn"
	col.position = Vector2(16, 16)
	col.add_theme_constant_override("separation", 6)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var title := Label.new()
	title.text = "Aventurero"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.95, 0.97, 1.0))
	col.add_child(title)

	var hb: Control = HEALTH_BAR_SCENE.instantiate()
	hb.custom_minimum_size = Vector2(260, 36)
	hb.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	col.add_child(hb)

	_stamina_caption = Label.new()
	_stamina_caption.text = "Estamina"
	_stamina_caption.add_theme_font_size_override("font_size", 11)
	_stamina_caption.add_theme_color_override("font_color", Color(0.75, 0.82, 0.95))
	col.add_child(_stamina_caption)

	_stamina_bar = ProgressBar.new()
	_stamina_bar.custom_minimum_size = Vector2(260, 14)
	_stamina_bar.max_value = 100.0
	_stamina_bar.value = 100.0
	_stamina_bar.show_percentage = false
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.12, 0.14, 0.2, 0.9)
	_stamina_bar.add_theme_stylebox_override("background", st)
	var sf := StyleBoxFlat.new()
	sf.bg_color = Color(0.25, 0.75, 0.95, 1.0)
	_stamina_bar.add_theme_stylebox_override("fill", sf)
	col.add_child(_stamina_bar)

	var xb: Control = EXPERIENCE_BAR_SCENE.instantiate()
	xb.custom_minimum_size = Vector2(260, 36)
	xb.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	col.add_child(xb)

	add_child(col)


func _build_top_right() -> void:
	_top_right = Control.new()
	_top_right.name = "TopRightColumn"
	_top_right.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	v.set_anchors_preset(Control.PRESET_TOP_LEFT)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var map_panel := PanelContainer.new()
	map_panel.custom_minimum_size = Vector2(168, 168)
	var map_bg := StyleBoxFlat.new()
	map_bg.bg_color = Color(0.08, 0.1, 0.14, 0.92)
	map_bg.border_color = Color(0.35, 0.45, 0.6, 0.8)
	map_bg.set_border_width_all(2)
	map_bg.set_corner_radius_all(6)
	map_panel.add_theme_stylebox_override("panel", map_bg)
	var map_lbl := Label.new()
	map_lbl.text = "Minimapa\n(próximamente)"
	map_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	map_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	map_lbl.add_theme_font_size_override("font_size", 13)
	map_lbl.add_theme_color_override("font_color", Color(0.65, 0.72, 0.85))
	map_panel.add_child(map_lbl)
	v.add_child(map_panel)

	wave_label = Label.new()
	wave_label.text = "Oleada 1"
	wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	wave_label.add_theme_font_size_override("font_size", 18)
	wave_label.add_theme_color_override("font_color", Color(0.92, 0.96, 1.0))
	wave_label.custom_minimum_size = Vector2(260, 0)
	v.add_child(wave_label)

	stats_label = Label.new()
	stats_label.visible = false
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stats_label.add_theme_font_size_override("font_size", 14)
	stats_label.add_theme_color_override("font_color", Color(0.82, 0.88, 0.95))
	stats_label.custom_minimum_size = Vector2(260, 0)
	v.add_child(stats_label)

	_top_right.add_child(v)
	add_child(_top_right)


func _build_bottom() -> void:
	_bottom_center = Control.new()
	_bottom_center.name = "BottomCenter"
	_bottom_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bottom_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	root.mouse_filter = Control.MOUSE_FILTER_STOP

	var ab_hint := Label.new()
	ab_hint.text = "Habilidades (bloqueadas)"
	ab_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ab_hint.add_theme_font_size_override("font_size", 11)
	ab_hint.add_theme_color_override("font_color", Color(0.55, 0.62, 0.72))
	root.add_child(ab_hint)

	var ab_row := HBoxContainer.new()
	ab_row.alignment = BoxContainer.ALIGNMENT_CENTER
	ab_row.add_theme_constant_override("separation", 6)
	for i in 6:
		var b := Button.new()
		b.custom_minimum_size = Vector2(44, 44)
		b.disabled = true
		b.text = "?"
		b.tooltip_text = "Bloqueado"
		var stb := StyleBoxFlat.new()
		stb.bg_color = Color(0.15, 0.16, 0.22, 0.95)
		stb.border_color = Color(0.35, 0.38, 0.48)
		stb.set_border_width_all(1)
		stb.set_corner_radius_all(4)
		b.add_theme_stylebox_override("disabled", stb)
		ab_row.add_child(b)
	root.add_child(ab_row)

	var hb_hint := Label.new()
	hb_hint.text = "Barra rápida"
	hb_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hb_hint.add_theme_font_size_override("font_size", 11)
	hb_hint.add_theme_color_override("font_color", Color(0.55, 0.62, 0.72))
	root.add_child(hb_hint)

	var hot_row := HBoxContainer.new()
	hot_row.alignment = BoxContainer.ALIGNMENT_CENTER
	hot_row.add_theme_constant_override("separation", 4)
	for slot in 9:
		var wrap := VBoxContainer.new()
		var key := Label.new()
		key.text = str(slot + 1)
		key.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		key.add_theme_font_size_override("font_size", 9)
		key.add_theme_color_override("font_color", Color(0.5, 0.55, 0.65))
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(40, 40)
		btn.disabled = true
		btn.text = ""
		var s2 := StyleBoxFlat.new()
		s2.bg_color = Color(0.12, 0.14, 0.2, 0.92)
		s2.border_color = Color(0.3, 0.35, 0.45)
		s2.set_border_width_all(1)
		s2.set_corner_radius_all(3)
		btn.add_theme_stylebox_override("disabled", s2)
		wrap.add_child(key)
		wrap.add_child(btn)
		hot_row.add_child(wrap)
	root.add_child(hot_row)

	_bottom_center.add_child(root)
	add_child(_bottom_center)


func _place_bottom_center() -> void:
	var sz := get_viewport().get_visible_rect().size
	var root := _bottom_center.get_child(0) as Control
	if root:
		root.position = Vector2(sz.x * 0.5 - root.get_combined_minimum_size().x * 0.5, sz.y - root.get_combined_minimum_size().y - 16)


func _reflow_corners() -> void:
	if not is_instance_valid(_top_right):
		return
	var sz := get_viewport().get_visible_rect().size
	var v := _top_right.get_child(0) as Control
	if v:
		_top_right.position = Vector2(sz.x - 16.0 - v.get_combined_minimum_size().x, 16.0)
	_place_bottom_center()


## Estamina / maná futuro: 0–100 por ahora.
func set_stamina_ratio(ratio: float) -> void:
	if _stamina_bar:
		_stamina_bar.value = clampf(ratio, 0.0, 1.0) * 100.0


func set_resource_bar_mana_mode(_is_mage: bool) -> void:
	if _stamina_caption:
		_stamina_caption.text = "Maná" if _is_mage else "Estamina"
