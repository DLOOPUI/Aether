extends Control

const PROTOTYPE_SCENE := &"res://scenes/gameplay/prototype_playground.tscn"

@onready var _btn_play: Button = $Center/Panel/Margin/VBox/BtnPlay
@onready var _btn_settings: Button = $Center/Panel/Margin/VBox/BtnSettings
@onready var _btn_quit: Button = $Center/Panel/Margin/VBox/BtnQuit


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_btn_play.pressed.connect(_on_play_pressed)
	_btn_settings.pressed.connect(_on_settings_pressed)
	_btn_quit.pressed.connect(_on_quit_pressed)
	_btn_play.grab_focus()


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file(PROTOTYPE_SCENE)


func _on_settings_pressed() -> void:
	print("Aether: Ajustes — pendiente submenú.")


func _on_quit_pressed() -> void:
	get_tree().quit()
