extends Control

const MAIN_MENU := &"res://scenes/ui/main_menu.tscn"

## Si es true, "Volver" y Esc emiten `close_requested` en lugar de ir al menú (p. ej. desde la pausa).
var exit_to_parent: bool = false

signal close_requested

@onready var _slider_vol: HSlider = $SafeArea/MainLayout/LeftPanel/Margin/Column/SliderVol
@onready var _slider_mouse: HSlider = $SafeArea/MainLayout/LeftPanel/Margin/Column/SliderMouse
@onready var _chk_full: CheckBox = $SafeArea/MainLayout/LeftPanel/Margin/Column/ChkFullscreen
@onready var _btn_back: Button = $SafeArea/MainLayout/LeftPanel/Margin/Column/BtnBack


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

	SaoUi.apply_to_buttons($SafeArea/MainLayout/LeftPanel/Margin/Column)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_ESCAPE:
		_go_back()


func _go_back() -> void:
	if exit_to_parent:
		close_requested.emit()
	else:
		get_tree().change_scene_to_file(MAIN_MENU)
