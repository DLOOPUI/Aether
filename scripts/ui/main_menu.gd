extends Control

const PROTOTYPE_SCENE := &"res://scenes/gameplay/prototype_playground.tscn"

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
	_apply_sao_styles(_main_page)
	_apply_sao_styles(_char_page)
	_show_main_page()
	_btn_play.grab_focus()


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


func _style_flat(bg: Color, border: Color, border_w: int = 1) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 14
	sb.content_margin_top = 10
	sb.content_margin_right = 14
	sb.content_margin_bottom = 10
	return sb


func _apply_sao_styles(root: Node) -> void:
	var n := _style_flat(Color(0.08, 0.14, 0.22, 0.42), Color(0.35, 0.72, 0.92, 0.35))
	var h := _style_flat(Color(0.12, 0.38, 0.58, 0.62), Color(0.45, 0.92, 1.0, 0.95))
	var p := _style_flat(Color(0.06, 0.22, 0.38, 0.78), Color(0.25, 0.55, 0.75, 1.0))
	_style_walk(root, n, h, p)


func _style_walk(node: Node, n: StyleBoxFlat, h: StyleBoxFlat, p: StyleBoxFlat) -> void:
	if node is OptionButton:
		var ob := node as OptionButton
		ob.add_theme_stylebox_override(&"normal", n.duplicate() as StyleBoxFlat)
		ob.add_theme_stylebox_override(&"hover", h.duplicate() as StyleBoxFlat)
		ob.add_theme_stylebox_override(&"pressed", p.duplicate() as StyleBoxFlat)
	elif node is Button:
		var b := node as Button
		b.add_theme_stylebox_override(&"normal", n.duplicate() as StyleBoxFlat)
		b.add_theme_stylebox_override(&"hover", h.duplicate() as StyleBoxFlat)
		b.add_theme_stylebox_override(&"pressed", p.duplicate() as StyleBoxFlat)
		b.add_theme_stylebox_override(&"focus", h.duplicate() as StyleBoxFlat)
	for c in node.get_children():
		_style_walk(c, n, h, p)


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
	print("Aether: Ajustes (audio / pantalla / controles) — pendiente escena.")


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_apply_character_pressed() -> void:
	print(
		"Personaje aplicado: género=%s raza=%s torso=%s pantalón=%s"
		% [
			_opt_gender.get_item_text(_opt_gender.selected),
			_opt_race.get_item_text(_opt_race.selected),
			_opt_top.get_item_text(_opt_top.selected),
			_opt_pants.get_item_text(_opt_pants.selected),
		]
	)
	_show_main_page()
