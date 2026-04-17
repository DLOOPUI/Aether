extends Node
## Sistema de combate para el jugador: ataques, daño, interacciones.

signal attack_triggered
signal enemy_hit(enemy: Node, damage: float)
signal enemy_killed(enemy: Node, experience_gained: int)

@export var base_attack_damage: float = 20.0
@export var attack_range: float = 2.5
@export var attack_cooldown: float = 0.8
@export var attack_radius: float = 1.2

var _attack_timer: float = 0.0
var _is_attacking: bool = false
var _experience_system: ExperienceSystem = null

@onready var _player: CharacterBody3D = get_parent()
@onready var _health_system: HealthSystem = $HealthSystem


func _ready() -> void:
	if not _health_system:
		_health_system = HealthSystem.new()
		_health_system.name = "HealthSystem"
		add_child(_health_system)
	
	_health_system.health_depleted.connect(_on_player_death)
	call_deferred("_find_experience_system")


func _process(delta: float) -> void:
	if _attack_timer > 0.0:
		_attack_timer -= delta
	
	# Detectar input de ataque
	if Input.is_action_just_pressed("attack") and _attack_timer <= 0.0 and _health_system.is_alive():
		_perform_attack()


func _perform_attack() -> void:
	_attack_timer = attack_cooldown
	_is_attacking = true
	attack_triggered.emit()
	
	# Detectar enemigos en el área de ataque
	var enemies = _detect_enemies_in_range()
	for enemy in enemies:
		_hit_enemy(enemy)
	
	# Reset después de un breve momento
	await get_tree().create_timer(0.3).timeout
	_is_attacking = false


func _detect_enemies_in_range() -> Array:
	var enemies = []
	
	# Rayo hacia adelante desde la posición del jugador
	var space_state = _player.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(
		_player.global_position,
		_player.global_position + _player.global_transform.basis.z * -attack_range * 1.5,
		0b1  # Colisión con layer 1 (enemigos)
	)
	
	var result = space_state.intersect_ray(query)
	if result:
		var collider = result.collider
		if collider and collider.has_method("take_damage"):
			enemies.append(collider)
	
	# También verificar área esférica alrededor del jugador
	var area_query = PhysicsShapeQueryParameters3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = attack_radius
	area_query.shape = sphere
	area_query.transform = Transform3D.IDENTITY.translated(_player.global_position)
	area_query.collision_mask = 0b1  # Layer de enemigos
	
	var area_results = space_state.intersect_shape(area_query)
	for area_result in area_results:
		var collider = area_result.collider
		if collider and collider.has_method("take_damage") and not enemies.has(collider):
			enemies.append(collider)
	
	return enemies


func _hit_enemy(enemy: Node) -> void:
	# Aplicar daño al enemigo
	if enemy.has_method("take_damage"):
		var damage = get_attack_damage()
		var damage_dealt = enemy.take_damage(damage, _player)
		if damage_dealt:
			enemy_hit.emit(enemy, damage)
			
			# Verificar si el enemigo murió
			if enemy.has_method("is_alive") and not enemy.is_alive():
				_on_enemy_killed(enemy)
			
			# Feedback visual/auditivo podría ir aquí


func take_damage(amount: float, source: Node = null) -> bool:
	return _health_system.take_damage(amount, source)


func heal(amount: float) -> bool:
	return _health_system.heal(amount)


func get_health_percentage() -> float:
	return _health_system.get_health_percentage()


func is_alive() -> bool:
	return _health_system.is_alive()


func _on_player_death() -> void:
	print("Player died!")
	# Aquí iría la lógica de muerte: animación, respawn, etc.
	# Por ahora solo desactivamos el control
	_player.set_process(false)
	_player.set_physics_process(false)


# API para UI/otros sistemas
func get_current_health() -> float:
	return _health_system.current_health if _health_system else 0.0


func get_max_health() -> float:
	return _health_system.max_health if _health_system else 0.0


func get_attack_damage() -> float:
	# Calcular daño basado en nivel si hay sistema de experiencia
	if _experience_system:
		return _experience_system.attack_damage
	return base_attack_damage


func _find_experience_system() -> void:
	var parent := get_parent()
	while parent:
		if parent.has_node("ExperienceSystem"):
			_experience_system = parent.get_node("ExperienceSystem") as ExperienceSystem
			break
		parent = parent.get_parent()
	if not _experience_system:
		_experience_system = get_node_or_null("/root/ExperienceSystem")
	if _experience_system:
		if not _experience_system.stat_changed.is_connected(_on_experience_stat_changed):
			_experience_system.stat_changed.connect(_on_experience_stat_changed)
		_sync_max_health_from_experience()


func _on_experience_stat_changed(stat: StringName, _old_value: float, new_value: float) -> void:
	if stat != &"max_health":
		return
	if not _health_system:
		return
	var ratio := (
		_health_system.current_health / _health_system.max_health
		if _health_system.max_health > 0.0
		else 1.0
	)
	_health_system.max_health = new_value
	_health_system.current_health = clampf(new_value * ratio, 0.0, new_value)


func _sync_max_health_from_experience() -> void:
	if not _experience_system or not _health_system:
		return
	var target := _experience_system.max_health
	if is_equal_approx(target, _health_system.max_health):
		return
	var ratio := (
		_health_system.current_health / _health_system.max_health
		if _health_system.max_health > 0.0
		else 1.0
	)
	_health_system.max_health = target
	_health_system.current_health = clampf(target * ratio, 0.0, target)


func _on_enemy_killed(enemy: Node) -> void:
	# Otorgar experiencia por matar enemigo
	if _experience_system:
		var exp_amount = 25  # Experiencia base por enemigo básico
		_experience_system.gain_experience(exp_amount, "enemy_kill")
		enemy_killed.emit(enemy, exp_amount)
		print("Experiencia ganada: +", exp_amount, " por matar enemigo")