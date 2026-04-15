extends Control

const MAIN_MENU := &"res://scenes/ui/main_menu.tscn"

## Si es true, "Volver" y Esc emiten `close_requested` en lugar de ir al menú (p. ej. desde la pausa).
var exit_to_parent: bool = false

signal close_requested

@onready var _slider_vol: HSlider = $SafeArea/MainLayout/LeftPanel/Margin/Column/SliderVol
@onready var _slider_mouse: HSlider = $SafeArea/MainLayout/LeftPanel/Margin/Column/SliderMouse
@onready var _chk_full: CheckBox = $SafeArea/MainLayout/LeftPanel/Margin/Column/ChkFullscreen
@onready var _btn_back: Button = $SafeArea/MainLayout/LeftPanel/Margin/Column/BtnBack
@onready var _column: VBoxContainer = $SafeArea/MainLayout/LeftPanel/Margin/Column

var _gamepad_hint: Label


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if exit_to_parent:
		_btn_back.text = "← Volver a la pausa"
	_slider_vol.value_changed.connect(func(v: float) -> void: GameSettings.set_master_volume_linear(v))
	_slider_mouse.value_changed.connect(func(v: float) -> void: GameSettings.set_mouse_sensitivity_multiplier(v))
	_chk_full.toggled.connect(func(on: bool) -> void: GameSettings.set_fullscreen(on))
	_btn_back.pressed.connect(_go_back)

	_slider_vol.value = GameSettings.master_volume_linear
	_slider_mouse.value = GameSettings.mouse_sensitivity_multiplier
	_chk_full.button_pressed = GameSettings.fullscreen

	SaoUi.apply_to_buttons(_column)
	_setup_gamepad_hint()
	UiGamepadSupport.gamepads_changed.connect(_on_gamepads_changed)
	_on_gamepads_changed(UiGamepadSupport.connected_joypads)


func _setup_gamepad_hint() -> void:
	_gamepad_hint = Label.new()
	_gamepad_hint.text = "Mando: ↑↓←→ · A/B"
	_gamepad_hint.add_theme_color_override(&"font_color", Color(0.55, 0.82, 0.98, 0.88))
	_gamepad_hint.add_theme_font_size_override(&"font_size", 11)
	_gamepad_hint.visible = false
	_gamepad_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_column.add_child(_gamepad_hint)
	_column.move_child(_gamepad_hint, 1)


func _on_gamepads_changed(count: int) -> void:
	if _gamepad_hint:
		_gamepad_hint.visible = count > 0


func _unhandled_input(event: InputEvent) -> void:
	if event == null:
		return
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		_go_back()


func _go_back() -> void:
	if exit_to_parent:
		close_requested.emit()
	else:
		get_tree().change_scene_to_file(MAIN_MENU)
