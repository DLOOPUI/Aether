class_name HealthSystem
extends Node
## Sistema de salud reutilizable para jugador, NPCs y enemigos.

signal health_changed(current: float, max_health: float)
signal health_depleted
signal damage_taken(amount: float, source: Node)

@export var max_health: float = 100.0

var _current_health: float = 100.0

@export var current_health: float = 100.0:
	get:
		return _current_health
	set(value):
		var old := _current_health
		_current_health = clampf(value, 0.0, max_health)
		if not is_equal_approx(old, _current_health):
			health_changed.emit(_current_health, max_health)
			if _current_health <= 0.0:
				health_depleted.emit()

var is_invulnerable: bool = false
var invulnerability_timer: float = 0.0

func _ready() -> void:
	current_health = max_health

func _process(delta: float) -> void:
	if invulnerability_timer > 0.0:
		invulnerability_timer -= delta
		if invulnerability_timer <= 0.0:
			is_invulnerable = false

func take_damage(amount: float, source: Node = null) -> bool:
	if is_invulnerable or current_health <= 0.0:
		return false
	
	current_health -= amount
	damage_taken.emit(amount, source)
	
	if current_health > 0.0:
		# Pequeña invulnerabilidad después de recibir daño
		is_invulnerable = true
		invulnerability_timer = 0.5
	
	return true

func heal(amount: float) -> bool:
	if current_health >= max_health:
		return false
	
	current_health += amount
	return true

func set_invulnerable(duration: float) -> void:
	is_invulnerable = true
	invulnerability_timer = duration

func get_health_percentage() -> float:
	return current_health / max_health if max_health > 0.0 else 0.0

func is_alive() -> bool:
	return current_health > 0.0

func reset() -> void:
	current_health = max_health
	is_invulnerable = false
	invulnerability_timer = 0.0