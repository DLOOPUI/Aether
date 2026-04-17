extends Control
## Barra de salud UI que se actualiza automáticamente cuando se conecta a un HealthSystem.

@export var health_system_path: NodePath = ""
@export var show_text: bool = true
@export var low_health_threshold: float = 0.3

var _health_system: HealthSystem = null
var _low_health_tween: Tween = null
@onready var _health_fill: Panel = $Background/HealthFill
@onready var _health_text: Label = $Background/HealthText

func _ready() -> void:
	_health_text.visible = show_text
	
	# Intentar conectar al HealthSystem automáticamente
	if health_system_path:
		_health_system = get_node(health_system_path) as HealthSystem
		_connect_to_health_system(_health_system)
	else:
		# Buscar HealthSystem en el árbol
		_try_find_health_system()


func _try_find_health_system() -> void:
	# Buscar jugador en el árbol
	var player = get_tree().get_first_node_in_group("player")
	if player:
		if player.has_node("PlayerCombat/HealthSystem"):
			_health_system = player.get_node("PlayerCombat/HealthSystem") as HealthSystem
			_connect_to_health_system(_health_system)
		elif player.has_node("HealthSystem"):
			_health_system = player.get_node("HealthSystem") as HealthSystem
			_connect_to_health_system(_health_system)


func _connect_to_health_system(system: HealthSystem) -> void:
	if not system:
		return
	
	_health_system = system
	_health_system.health_changed.connect(_on_health_changed)
	
	# Actualizar con valores iniciales
	_update_health_display(_health_system.current_health, _health_system.max_health)


func _on_health_changed(current: float, max_health: float) -> void:
	_update_health_display(current, max_health)
	var health_percent := current / max_health if max_health > 0.0 else 0.0
	if health_percent <= low_health_threshold:
		_start_low_health_pulse()
	else:
		_stop_low_health_pulse()


func _update_health_display(current: float, max_health: float) -> void:
	var health_percent = current / max_health if max_health > 0 else 0.0
	
	# Actualizar ancho de la barra
	var max_width = $Background.size.x - 8  # 4px de margen a cada lado
	_health_fill.size.x = max_width * health_percent
	
	# Actualizar texto
	if show_text:
		_health_text.text = "%d / %d" % [ceil(current), ceil(max_health)]
	
	# Cambiar color según salud
	var stylebox = _health_fill.get_theme_stylebox("panel").duplicate()
	
	if health_percent > 0.6:
		stylebox.bg_color = Color(0.2, 0.8, 0.2)  # Verde
	elif health_percent > 0.3:
		stylebox.bg_color = Color(0.8, 0.8, 0.2)  # Amarillo
	else:
		stylebox.bg_color = Color(0.8, 0.2, 0.2)  # Rojo
	
	_health_fill.add_theme_stylebox_override("panel", stylebox)


func _start_low_health_pulse() -> void:
	if _low_health_tween and is_instance_valid(_low_health_tween):
		return
	_low_health_tween = create_tween()
	_low_health_tween.set_loops()
	_low_health_tween.tween_property(_health_fill, "modulate", Color(1, 1, 1, 0.7), 0.5)
	_low_health_tween.tween_property(_health_fill, "modulate", Color(1, 1, 1, 1), 0.5)


func _stop_low_health_pulse() -> void:
	if _low_health_tween and is_instance_valid(_low_health_tween):
		_low_health_tween.kill()
	_low_health_tween = null
	if is_instance_valid(_health_fill):
		_health_fill.modulate = Color(1, 1, 1, 1)


func set_health_values(current: float, max_health: float) -> void:
	_update_health_display(current, max_health)


func disconnect_from_health_system() -> void:
	if _health_system and _health_system.health_changed.is_connected(_on_health_changed):
		_health_system.health_changed.disconnect(_on_health_changed)
	_health_system = null