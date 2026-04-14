extends Control

@onready var _btn_play: Button = $Center/Panel/Margin/VBox/BtnPlay
@onready var _btn_settings: Button = $Center/Panel/Margin/VBox/BtnSettings
@onready var _btn_quit: Button = $Center/Panel/Margin/VBox/BtnQuit


func _ready() -> void:
	_btn_play.pressed.connect(_on_play_pressed)
	_btn_settings.pressed.connect(_on_settings_pressed)
	_btn_quit.pressed.connect(_on_quit_pressed)


func _on_play_pressed() -> void:
	# Siguiente hito: escena gameplay mínima (personaje 3ª persona + suelo).
	print("Aether: Play — pendiente cargar mundo prototipo.")


func _on_settings_pressed() -> void:
	print("Aether: Ajustes — pendiente submenú.")


func _on_quit_pressed() -> void:
	get_tree().quit()
