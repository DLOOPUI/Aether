extends Control

const PROTOTYPE_SCENE := &"res://scenes/gameplay/prototype_playground.tscn"
const SETTINGS_SCENE := &"res://scenes/ui/settings.tscn"

const _FORM_PREFIX := "SafeArea/MainLayout/LeftPanel/Margin/MainColumn/CharacterPage/LeftColumn/TabRoot/Identidad/MarginId/Form/"
const _BODY_SLIDERS_PATH := "SafeArea/MainLayout/LeftPanel/Margin/MainColumn/CharacterPage/LeftColumn/TabRoot/Cuerpo/MarginBody/BodySliders"

var _draft: CharacterDraft = CharacterDraft.new()
var _body_sliders: Dictionary = {}

@onready var _main_page: Control = $SafeArea/MainLayout/LeftPanel/Margin/MainColumn/MainPage
@onready var _char_page: Control = $SafeArea/MainLayout/LeftPanel/Margin/MainColumn/CharacterPage
@onready var _left_panel: PanelContainer = $SafeArea/MainLayout/LeftPanel
@onready var _spacer: Control = $SafeArea/MainLayout/Spacer
@onready var _left_column: VBoxContainer = $SafeArea/MainLayout/LeftPanel/Margin/MainColumn/CharacterPage/LeftColumn

@onready var _btn_play: Button = $SafeArea/MainLayout/LeftPanel/Margin/MainColumn/MainPage/BtnPlay
@onready var _btn_customize: Button = $SafeArea/MainLayout/LeftPanel/Margin/MainColumn/MainPage/BtnCustomize
@onready var _btn_settings: Button = $SafeArea/MainLayout/LeftPanel/Margin/MainColumn/MainPage/BtnSettings
@onready var _btn_quit: Button = $SafeArea/MainLayout/LeftPanel/Margin/MainColumn/MainPage/BtnQuit
@onready var _btn_inventory: Button = $SafeArea/MainLayout/LeftPanel/Margin/MainColumn/MainPage/BtnInventory

@onready var _opt_gender: OptionButton = get_node(_FORM_PREFIX + "OptGender")
@onready var _opt_race: OptionButton = get_node(_FORM_PREFIX + "OptRace")
@onready var _opt_top: OptionButton = get_node(_FORM_PREFIX + "OptTop")
@onready var _opt_pants: OptionButton = get_node(_FORM_PREFIX + "OptPants")
@onready var _opt_shoes: OptionButton = get_node(_FORM_PREFIX + "OptShoes")
@onready var _opt_hair: OptionButton = get_node(_FORM_PREFIX + "OptHair")
@onready var _btn_back: Button = $SafeArea/MainLayout/LeftPanel/Margin/MainColumn/CharacterPage/LeftColumn/FooterRow/BtnBack
@onready var _btn_apply: Button = $SafeArea/MainLayout/LeftPanel/Margin/MainColumn/CharacterPage/LeftColumn/FooterRow/BtnApply
@onready var _body_sliders_root: VBoxContainer = get_node(_BODY_SLIDERS_PATH)
@onready var _tab_root: TabContainer = $SafeArea/MainLayout/LeftPanel/Margin/MainColumn/CharacterPage/LeftColumn/TabRoot

var _gamepad_hint: Label


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	_wire_main_buttons()
	_wire_character_page()
	_fill_character_options()
	_build_body_sliders()
	_draft = CharacterStorage.load_draft()
	_apply_draft_to_options()
	SaoUi.apply_to_buttons(_main_page)
	SaoUi.apply_to_buttons(_left_column)
	_setup_gamepad_hint()
	UiGamepadSupport.gamepads_changed.connect(_on_gamepads_changed)
	_on_gamepads_changed(UiGamepadSupport.connected_joypads)
	_show_main_page()
	_btn_play.grab_focus()


func _setup_gamepad_hint() -> void:
	_gamepad_hint = Label.new()
	_gamepad_hint.text = "Mando: ↑↓←→ · A · B · LB/RB pestañas"
	_gamepad_hint.add_theme_color_override(&"font_color", Color(0.55, 0.82, 0.98, 0.92))
	_gamepad_hint.add_theme_font_size_override(&"font_size", 11)
	_gamepad_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_gamepad_hint.visible = false
	_gamepad_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_gamepad_hint.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_gamepad_hint.offset_left = -420.0
	_gamepad_hint.offset_top = 8.0
	_gamepad_hint.offset_right = -16.0
	_gamepad_hint.offset_bottom = 48.0
	$SafeArea.add_child(_gamepad_hint)


func _on_gamepads_changed(count: int) -> void:
	if _gamepad_hint:
		_gamepad_hint.visible = count > 0


func _unhandled_input(event: InputEvent) -> void:
	if not _char_page.visible:
		return
	if event.is_action_pressed(&"menu_tab_prev"):
		var n: int = _tab_root.get_tab_count()
		if n > 1:
			_tab_root.current_tab = (_tab_root.current_tab - 1 + n) % n
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"menu_tab_next"):
		var n2: int = _tab_root.get_tab_count()
		if n2 > 1:
			_tab_root.current_tab = (_tab_root.current_tab + 1) % n2
			get_viewport().set_input_as_handled()


func _build_body_sliders() -> void:
	var labels: PackedStringArray = [
		"Altura",
		"Complexión",
		"Cabeza",
		"Brazos",
		"Piernas",
		"Tono piel",
		"Tono pelo",
	]
	var props: Array[StringName] = [
		&"height_01",
		&"build_01",
		&"head_size_01",
		&"arm_length_01",
		&"leg_length_01",
		&"skin_tone_01",
		&"hair_tone_01",
	]
	for i in labels.size():
		var lb := Label.new()
		lb.text = labels[i]
		lb.add_theme_color_override(&"font_color", Color(0.7, 0.88, 1.0))
		lb.add_theme_font_size_override(&"font_size", 12)
		_body_sliders_root.add_child(lb)
		var s := HSlider.new()
		s.min_value = 0.0
		s.max_value = 1.0
		s.step = 0.01
		s.custom_minimum_size.y = 22
		var prop: StringName = props[i]
		s.value_changed.connect(func(v: float) -> void: _on_body_slider(prop, v))
		_body_sliders_root.add_child(s)
		_body_sliders[prop] = s


func _on_body_slider(prop: StringName, v: float) -> void:
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


func _apply_draft_to_options() -> void:
	_safe_select(_opt_gender, _draft.gender_id)
	_safe_select(_opt_race, _draft.race_id)
	_safe_select(_opt_top, _draft.top_id)
	_safe_select(_opt_pants, _draft.pants_id)
	_safe_select(_opt_shoes, _draft.shoes_id)
	_safe_select(_opt_hair, _draft.hair_id)
	_set_body_slider(&"height_01", _draft.height_01)
	_set_body_slider(&"build_01", _draft.build_01)
	_set_body_slider(&"head_size_01", _draft.head_size_01)
	_set_body_slider(&"arm_length_01", _draft.arm_length_01)
	_set_body_slider(&"leg_length_01", _draft.leg_length_01)
	_set_body_slider(&"skin_tone_01", _draft.skin_tone_01)
	_set_body_slider(&"hair_tone_01", _draft.hair_tone_01)


func _set_body_slider(prop: StringName, v: float) -> void:
	var s: HSlider = _body_sliders.get(prop) as HSlider
	if s:
		s.set_value_no_signal(v)


func _safe_select(ob: OptionButton, idx: int) -> void:
	var max_i: int = ob.item_count - 1
	if max_i < 0:
		return
	ob.select(clampi(idx, 0, max_i))


func _wire_main_buttons() -> void:
	_btn_play.pressed.connect(_on_play_pressed)
	_btn_customize.pressed.connect(_on_customize_pressed)
	_btn_settings.pressed.connect(_on_settings_pressed)
	_btn_quit.pressed.connect(_on_quit_pressed)
	_btn_inventory.pressed.connect(_on_inventory_pressed)


func _wire_character_page() -> void:
	_btn_back.pressed.connect(_show_main_page)
	_btn_apply.pressed.connect(_on_apply_character_pressed)
	_opt_gender.item_selected.connect(_on_identity_changed)
	_opt_race.item_selected.connect(_on_identity_changed)
	_opt_top.item_selected.connect(_on_identity_changed)
	_opt_pants.item_selected.connect(_on_identity_changed)
	_opt_shoes.item_selected.connect(_on_identity_changed)
	_opt_hair.item_selected.connect(_on_identity_changed)


func _on_identity_changed(_i: int = 0) -> void:
	_draft.gender_id = _opt_gender.selected
	_draft.race_id = _opt_race.selected
	_draft.top_id = _opt_top.selected
	_draft.pants_id = _opt_pants.selected
	_draft.shoes_id = _opt_shoes.selected
	_draft.hair_id = _opt_hair.selected


func _fill_character_options() -> void:
	_fill_opts(_opt_gender, ["Femenino", "Masculino", "No indicado"])
	_fill_opts(_opt_race, ["Humano", "Elfo", "Enano", "Bestia", "Constructo", "—"])
	_fill_opts(_opt_top, ["Camiseta básica", "Chaqueta", "Armadura ligera", "Túnica", "—"])
	_fill_opts(_opt_pants, ["Vaqueros", "Pantalón táctico", "Falda / kilt", "—"])
	_fill_opts(_opt_shoes, ["Zapatillas", "Botas", "Sandalias", "—"])
	_fill_opts(_opt_hair, ["Corto", "Largo", "Cola", "Rizado", "—"])


func _fill_opts(ob: OptionButton, labels: PackedStringArray) -> void:
	ob.clear()
	for s in labels:
		ob.add_item(s)
	ob.select(0)


func _show_main_page() -> void:
	_main_page.visible = true
	_char_page.visible = false
	_spacer.visible = true
	_left_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_left_panel.custom_minimum_size = Vector2(400, 0)
	_btn_play.grab_focus()


func _on_customize_pressed() -> void:
	_main_page.visible = false
	_char_page.visible = true
	_spacer.visible = false
	_left_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_left_panel.custom_minimum_size = Vector2(520, 0)
	_btn_back.grab_focus()


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file(PROTOTYPE_SCENE)


func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file(SETTINGS_SCENE)


func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_inventory_pressed() -> void:
	var inv_ui = load(&"res://scenes/ui/inventory_ui.tscn").instantiate()
	get_tree().root.add_child(inv_ui)
	inv_ui.show_inventory()


func _sync_draft_from_ui() -> void:
	_draft.gender_id = _opt_gender.selected
	_draft.race_id = _opt_race.selected
	_draft.top_id = _opt_top.selected
	_draft.pants_id = _opt_pants.selected
	_draft.shoes_id = _opt_shoes.selected
	_draft.hair_id = _opt_hair.selected
	_draft.height_01 = float(_body_sliders[&"height_01"].value)
	_draft.build_01 = float(_body_sliders[&"build_01"].value)
	_draft.head_size_01 = float(_body_sliders[&"head_size_01"].value)
	_draft.arm_length_01 = float(_body_sliders[&"arm_length_01"].value)
	_draft.leg_length_01 = float(_body_sliders[&"leg_length_01"].value)
	_draft.skin_tone_01 = float(_body_sliders[&"skin_tone_01"].value)
	_draft.hair_tone_01 = float(_body_sliders[&"hair_tone_01"].value)


func _on_apply_character_pressed() -> void:
	_sync_draft_from_ui()
	var err: Error = CharacterStorage.save_draft(_draft)
	if err != OK:
		push_error("No se pudo guardar el personaje: %s" % error_string(err))
	else:
		print(
			"Personaje guardado: género=%s raza=%s torso=%s pantalón=%s"
			% [
				_opt_gender.get_item_text(_opt_gender.selected),
				_opt_race.get_item_text(_opt_race.selected),
				_opt_top.get_item_text(_opt_top.selected),
				_opt_pants.get_item_text(_opt_pants.selected),
			]
		)
	_show_main_page()
