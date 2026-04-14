extends Node
## Autoload: volumen maestro, sensibilidad de cámara (multiplicador), pantalla completa.

const CFG_PATH := &"user://settings.cfg"

var master_volume_linear: float = 1.0
## Multiplicador sobre la sensibilidad base del jugador (0.25 — 2.0).
var mouse_sensitivity_multiplier: float = 1.0
var fullscreen: bool = false


func _ready() -> void:
	load_settings()
	apply_audio()
	apply_display()


func load_settings() -> void:
	var cf := ConfigFile.new()
	if cf.load(CFG_PATH) != OK:
		return
	master_volume_linear = float(cf.get_value(&"audio", &"master_linear", 1.0))
	mouse_sensitivity_multiplier = float(cf.get_value(&"input", &"mouse_sensitivity_multiplier", 1.0))
	fullscreen = bool(cf.get_value(&"display", &"fullscreen", false))


func save_settings() -> void:
	var cf := ConfigFile.new()
	cf.set_value(&"audio", &"master_linear", master_volume_linear)
	cf.set_value(&"input", &"mouse_sensitivity_multiplier", mouse_sensitivity_multiplier)
	cf.set_value(&"display", &"fullscreen", fullscreen)
	cf.save(CFG_PATH)


func set_master_volume_linear(v: float) -> void:
	master_volume_linear = clampf(v, 0.0, 1.0)
	apply_audio()
	save_settings()


func set_mouse_sensitivity_multiplier(v: float) -> void:
	mouse_sensitivity_multiplier = clampf(v, 0.25, 2.0)
	save_settings()


func set_fullscreen(on: bool) -> void:
	fullscreen = on
	apply_display()
	save_settings()


func apply_audio() -> void:
	var bus := AudioServer.get_bus_index(&"Master")
	if master_volume_linear <= 0.0001:
		AudioServer.set_bus_mute(bus, true)
	else:
		AudioServer.set_bus_mute(bus, false)
		AudioServer.set_bus_volume_db(bus, linear_to_db(master_volume_linear))


func apply_display() -> void:
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
