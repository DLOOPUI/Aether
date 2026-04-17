class_name ExperienceSystem
extends Node
## Sistema de experiencia, niveles y stats del jugador.

signal level_up(new_level: int)
signal experience_gained(amount: int, total: int, to_next_level: int)
signal stat_changed(stat: StringName, old_value: float, new_value: float)

# Configuración de niveles
@export var base_experience: int = 100
@export var experience_growth: float = 1.5  # Multiplicador por nivel

# Stats del jugador
@export var base_health: float = 100.0
@export var base_attack: float = 20.0
@export var base_defense: float = 5.0
@export var health_per_level: float = 20.0
@export var attack_per_level: float = 5.0
@export var defense_per_level: float = 2.0

var current_level: int = 1
var current_experience: int = 0
var experience_to_next_level: int = 0

# Stats actuales
var max_health: float = 0.0
var attack_damage: float = 0.0
var defense: float = 0.0

# Experiencia por enemigo (podría variar por tipo)
var enemy_experience: Dictionary = {
	"basic": 25,
	"elite": 100,
	"boss": 500
}


func _ready() -> void:
	_calculate_experience_to_next_level()
	_update_stats()
	
	# Conectar a eventos de muerte de enemigos
	_get_enemy_death_signals()


func _get_enemy_death_signals() -> void:
	# Escuchar muerte de enemigos (se conecta dinámicamente cuando se crean)
	pass  # Se conectará cuando se creen enemigos


func gain_experience(amount: int, source: String = "") -> void:
	var old_exp = current_experience
	current_experience += amount
	
	print("Experiencia ganada: +", amount, " (", source, ")")
	experience_gained.emit(amount, current_experience, experience_to_next_level)
	
	# Verificar si subió de nivel
	while current_experience >= experience_to_next_level:
		_level_up()
	
	# Guardar progreso
	_save_progress()


func _level_up() -> void:
	current_level += 1
	current_experience -= experience_to_next_level
	
	_calculate_experience_to_next_level()
	_update_stats()
	
	print("¡Nivel ", current_level, " alcanzado!")
	print("Stats: HP=", max_health, " ATK=", attack_damage, " DEF=", defense)
	
	level_up.emit(current_level)
	
	# Aquí podríamos añadir efectos visuales/auditivos
	_play_level_up_effects()


func _calculate_experience_to_next_level() -> void:
	# Fórmula: base * (growth ^ (nivel-1))
	experience_to_next_level = int(base_experience * pow(experience_growth, current_level - 1))
	print("Nivel ", current_level, ": ", current_experience, "/", experience_to_next_level, " XP")


func _update_stats() -> void:
	var old_health = max_health
	var old_attack = attack_damage
	var old_defense = defense
	
	max_health = base_health + (health_per_level * (current_level - 1))
	attack_damage = base_attack + (attack_per_level * (current_level - 1))
	defense = base_defense + (defense_per_level * (current_level - 1))
	
	if old_health != max_health:
		stat_changed.emit(&"max_health", old_health, max_health)
	if old_attack != attack_damage:
		stat_changed.emit(&"attack_damage", old_attack, attack_damage)
	if old_defense != defense:
		stat_changed.emit(&"defense", old_defense, defense)


func _play_level_up_effects() -> void:
	# Podría mostrar partículas, sonido, etc.
	# Por ahora solo log
	pass


func get_experience_percentage() -> float:
	if experience_to_next_level <= 0:
		return 0.0
	return float(current_experience) / float(experience_to_next_level)


func get_stats_summary() -> Dictionary:
	return {
		"level": current_level,
		"experience": current_experience,
		"experience_to_next": experience_to_next_level,
		"max_health": max_health,
		"attack_damage": attack_damage,
		"defense": defense,
		"experience_percentage": get_experience_percentage()
	}


func _save_progress() -> void:
	# Guardar en ConfigFile o sistema de guardado
	var cf = ConfigFile.new()
	cf.load("user://progress.cfg")
	
	cf.set_value("player", "level", current_level)
	cf.set_value("player", "experience", current_experience)
	
	cf.save("user://progress.cfg")


func load_progress() -> void:
	var cf = ConfigFile.new()
	if cf.load("user://progress.cfg") != OK:
		return  # No hay progreso guardado
	
	current_level = cf.get_value("player", "level", 1)
	current_experience = cf.get_value("player", "experience", 0)
	
	_calculate_experience_to_next_level()
	_update_stats()
	
	print("Progreso cargado: Nivel ", current_level, ", XP: ", current_experience)


func reset() -> void:
	current_level = 1
	current_experience = 0
	
	_calculate_experience_to_next_level()
	_update_stats()
	
	print("Sistema de experiencia reiniciado")


# API para otros sistemas
func get_damage_reduction() -> float:
	# Fórmula simple: reducción = defensa / (defensa + 100)
	return defense / (defense + 100.0)


func get_level() -> int:
	return current_level


func get_experience_info() -> Dictionary:
	return {
		"current": current_experience,
		"to_next": experience_to_next_level,
		"percentage": get_experience_percentage()
	}