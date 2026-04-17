extends Node
## Autoload: volumen maestro, sensibilidad de cámara (multiplicador), pantalla completa, oro (progreso ligero).

signal gold_changed(new_amount: int)

const CFG_PATH := &"user://settings.cfg"

var master_volume_linear: float = 1.0
var sfx_volume_linear: float = 1.0
## Multiplicador sobre la sensibilidad base del jugador (0.25 — 2.0).
var mouse_sensitivity_multiplier: float = 1.0
var fullscreen: bool = false
## Moneda simple para recompensas de misiones (hasta inventario dedicado).
var gold: int = 0
## Inventario del jugador.
var player_inventory: Inventory = Inventory.new()


func _ready() -> void:
	load_settings()
	apply_audio()
	apply_display()


func load_settings() -> void:
	var cf := ConfigFile.new()
	if cf.load(CFG_PATH) != OK:
		return
	master_volume_linear = float(cf.get_value(&"audio", &"master_linear", 1.0))
	sfx_volume_linear = float(cf.get_value(&"audio", &"sfx_linear", 1.0))
	mouse_sensitivity_multiplier = float(cf.get_value(&"input", &"mouse_sensitivity_multiplier", 1.0))
	fullscreen = bool(cf.get_value(&"display", &"fullscreen", false))
	gold = int(cf.get_value(&"progress", &"gold", 0))
	# Inventario se crea nuevo cada sesión por simplicidad


func save_settings() -> void:
	var cf := ConfigFile.new()
	cf.load(CFG_PATH)
	cf.set_value(&"audio", &"master_linear", master_volume_linear)
	cf.set_value(&"audio", &"sfx_linear", sfx_volume_linear)
	cf.set_value(&"input", &"mouse_sensitivity_multiplier", mouse_sensitivity_multiplier)
	cf.set_value(&"display", &"fullscreen", fullscreen)
	cf.set_value(&"progress", &"gold", gold)
	# Nota: inventario no se guarda en settings.cfg por ahora
	cf.save(CFG_PATH)


func add_gold(amount: int) -> void:
	gold = maxi(0, gold + amount)
	gold_changed.emit(gold)
	save_settings()


func set_master_volume_linear(v: float) -> void:
	master_volume_linear = clampf(v, 0.0, 1.0)
	apply_audio()
	save_settings()


func set_sfx_volume_linear(v: float) -> void:
	sfx_volume_linear = clampf(v, 0.0, 1.0)
	save_settings()


func get_sfx_volume_db() -> float:
	if sfx_volume_linear <= 0.0001:
		return -80.0
	return linear_to_db(sfx_volume_linear)


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


func get_player_inventory() -> Inventory:
	return player_inventory

func grant_item_by_id(item_id: String) -> bool:
	var item: Item
	match item_id:
		"apple":
			item = Apple.new()
		"potion":
			item = Potion.new()
		"apple_badge":
			item = Item.new()
			item.name = "Insignia de Manzana"
			item.description = "Una insignia otorgada por recoger manzanas."
			item.item_type = "equipment"
		_:
			push_error("Item ID desconocido: %s" % item_id)
			return false
	
	return player_inventory.add_item(item)

func process_pending_rewards() -> void:
	var rewards = QuestManager.take_pending_item_rewards()
	for rid in rewards:
		grant_item_by_id(rid)
