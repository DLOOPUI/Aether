extends Control

const PROTOTYPE_SCENE := &"res://scenes/gameplay/prototype_playground.tscn"
const SETTINGS_SCENE := &"res://scenes/ui/settings.tscn"

var _draft: CharacterDraft = CharacterDraft.new()

@onready var _main_page: Control = $SafeArea/MainLayout/LeftPanel/Margin/MainColumn/MainPage
@onready var _char_page: Control = $SafeArea/MainLayout/LeftPanel/Margin/MainColumn/CharacterPage

@onready var _btn_play: Button = $SafeArea/MainLayout/LeftPanel/Margin/MainColumn/MainPage/BtnPlay
@onready var _btn_customize: Button = $SafeArea/MainLayout/LeftPanel/Margin/MainColumn/MainPage/BtnCustomize
@onready var _btn_settings: Button = $SafeArea/MainLayout/LeftPanel/Margin/MainColumn/MainPage/BtnSettings
@onready var _btn_quit: Button = $SafeArea/MainLayout/LeftPanel/Margin/MainColumn/MainPage/BtnQuit

@onready var _opt_gender: OptionButton = $SafeArea/MainLayout/LeftPanel/Margin/MainColumn/CharacterPage/Form/OptGender
@onready var _opt_race: OptionButton = $SafeArea/MainLayout/LeftPanel/Margin/MainColumn/CharacterPage/Form/OptRace
@onready var _opt_top: OptionButton = $SafeArea/MainLayout/LeftPanel/Margin/MainColumn/CharacterPage/Form/OptTop
@onready var _opt_pants: OptionButton = $SafeArea/MainLayout/LeftPanel/Margin/MainColumn/CharacterPage/Form/OptPants
@onready var _opt_shoes: OptionButton = $SafeArea/MainLayout/LeftPanel/Margin/MainColumn/CharacterPage/Form/OptShoes
@onready var _opt_hair: OptionButton = $SafeArea/MainLayout/LeftPanel/Margin/MainColumn/CharacterPage/Form/OptHair
@onready var _btn_back: Button = $SafeArea/MainLayout/LeftPanel/Margin/MainColumn/CharacterPage/FooterRow/BtnBack
@onready var _btn_apply: Button = $SafeArea/MainLayout/LeftPanel/Margin/MainColumn/CharacterPage/FooterRow/BtnApply


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	_wire_main_buttons()
	_wire_character_page()
	_fill_character_options()
	_draft = CharacterStorage.load_draft()
	_apply_draft_to_options()
	SaoUi.apply_to_buttons(_main_page)
	SaoUi.apply_to_buttons(_char_page)
	_show_main_page()
	_btn_play.grab_focus()


func _apply_draft_to_options() -> void:
	_safe_select(_opt_gender, _draft.gender_id)
	_safe_select(_opt_race, _draft.race_id)
	_safe_select(_opt_top, _draft.top_id)
	_safe_select(_opt_pants, _draft.pants_id)
	_safe_select(_opt_shoes, _draft.shoes_id)
	_safe_select(_opt_hair, _draft.hair_id)


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


func _wire_character_page() -> void:
	_btn_back.pressed.connect(_show_main_page)
	_btn_apply.pressed.connect(_on_apply_character_pressed)
	_opt_gender.item_selected.connect(func(i: int) -> void: _draft.gender_id = i)
	_opt_race.item_selected.connect(func(i: int) -> void: _draft.race_id = i)
	_opt_top.item_selected.connect(func(i: int) -> void: _draft.top_id = i)
	_opt_pants.item_selected.connect(func(i: int) -> void: _draft.pants_id = i)
	_opt_shoes.item_selected.connect(func(i: int) -> void: _draft.shoes_id = i)
	_opt_hair.item_selected.connect(func(i: int) -> void: _draft.hair_id = i)


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
	_btn_play.grab_focus()


func _on_customize_pressed() -> void:
	_main_page.visible = false
	_char_page.visible = true
	_btn_back.grab_focus()


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file(PROTOTYPE_SCENE)


func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file(SETTINGS_SCENE)


func _on_quit_pressed() -> void:
	get_tree().quit()


func _sync_draft_from_ui() -> void:
	_draft.gender_id = _opt_gender.selected
	_draft.race_id = _opt_race.selected
	_draft.top_id = _opt_top.selected
	_draft.pants_id = _opt_pants.selected
	_draft.shoes_id = _opt_shoes.selected
	_draft.hair_id = _opt_hair.selected


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
