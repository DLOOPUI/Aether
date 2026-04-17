extends Node
## Sistema de combate para el jugador: ataques, daño, interacciones.

const SFX_SWING := preload("res://assets/audio/swing.wav")
const SFX_HIT := preload("res://assets/audio/hit.wav")
const SFX_HURT := preload("res://assets/audio/hurt.wav")
const COMBAT_BALANCE_PATH := "res://resources/combat_balance.tres"

signal attack_triggered
signal enemy_hit(enemy: Node, damage: float)
signal enemy_killed(enemy: Node, experience_gained: int)
signal player_died
signal player_took_damage(amount: float)

@export var base_attack_damage: float = 20.0
@export var attack_range: float = 2.5
@export var attack_cooldown: float = 0.8
@export var attack_radius: float = 1.2
@export var combat_balance: CombatBalance

var _attack_timer: float = 0.0
var _experience_system: ExperienceSystem = null

@onready var _player: CharacterBody3D = get_parent()
@onready var _health_system: HealthSystem = $HealthSystem


func _ready() -> void:
	if not _health_system:
		_health_system = HealthSystem.new()
		_health_system.name = "HealthSystem"
		add_child(_health_system)
	
	_health_system.health_depleted.connect(_on_player_death)
	_health_system.damage_taken.connect(_on_health_damage_taken)
	call_deferred("_find_experience_system")
	if combat_balance == null:
		combat_balance = ResourceLoader.load(COMBAT_BALANCE_PATH) as CombatBalance


func _process(delta: float) -> void:
	if _attack_timer > 0.0:
		_attack_timer -= delta
	
	# Detectar input de ataque
	if Input.is_action_just_pressed("attack") and _attack_timer <= 0.0 and _health_system.is_alive():
		_perform_attack()


func _perform_attack() -> void:
	_attack_timer = attack_cooldown
	attack_triggered.emit()
	_play_attack_vfx()
	CombatSfx.play(self, SFX_SWING, -4.0)
	
	# Detectar enemigos en el área de ataque
	var enemies = _detect_enemies_in_range()
	for enemy in enemies:
		_hit_enemy(enemy)
	
	# Reset después de un breve momento
	await get_tree().create_timer(0.3).timeout


func _attack_forward_horizontal() -> Vector3:
	var fwd := -_player.global_transform.basis.z
	fwd.y = 0.0
	if fwd.length_squared() < 0.0001:
		return Vector3.FORWARD
	return fwd.normalized()


func _attack_origin() -> Vector3:
	return _player.global_position + Vector3(0.0, 0.85, 0.0)


func _detect_enemies_in_range() -> Array:
	var enemies = []
	var fwd := _attack_forward_horizontal()
	var origin := _attack_origin()
	var space_state = _player.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(
		origin,
		origin + fwd * attack_range * 1.5,
		0b1
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
	area_query.transform = Transform3D.IDENTITY.translated(origin)
	area_query.collision_mask = 0b1
	
	var area_results = space_state.intersect_shape(area_query)
	for area_result in area_results:
		var collider = area_result.collider
		if collider and collider.has_method("take_damage") and not enemies.has(collider):
			var to_target := (collider as Node3D).global_position - _player.global_position
			to_target.y = 0.0
			if to_target.length_squared() > 0.0001 and fwd.dot(to_target.normalized()) < 0.2:
				continue
			enemies.append(collider)
	
	return enemies


func _play_attack_vfx() -> void:
	var mesh := _player.get_node_or_null("MeshInstance3D") as MeshInstance3D
	if mesh == null:
		return
	var s := mesh.scale
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(mesh, "scale", s * Vector3(1.06, 0.94, 1.06), 0.06)
	tween.tween_property(mesh, "scale", s, 0.12)


func _hit_enemy(enemy: Node) -> void:
	# Aplicar daño al enemigo
	if enemy.has_method("take_damage"):
		var damage = get_attack_damage()
		var damage_dealt = enemy.take_damage(damage, _player)
		if damage_dealt:
			CombatSfx.play(self, SFX_HIT, -2.0)
			enemy_hit.emit(enemy, damage)
			
			# Verificar si el enemigo murió
			if enemy.has_method("is_alive") and not enemy.is_alive():
				_on_enemy_killed(enemy)
			
			# Feedback visual/auditivo podría ir aquí


func take_damage(amount: float, source: Node = null) -> bool:
	var a := amount
	if combat_balance:
		a *= combat_balance.damage_taken_multiplier
	return _health_system.take_damage(a, source)


func heal(amount: float) -> bool:
	return _health_system.heal(amount)


func get_health_percentage() -> float:
	return _health_system.get_health_percentage()


func is_alive() -> bool:
	return _health_system.is_alive()


func respawn_at(spawn_transform: Transform3D) -> void:
	if not _health_system:
		return
	_player.global_transform = spawn_transform
	_health_system.current_health = _health_system.max_health
	_player.set_process(true)
	_player.set_physics_process(true)


func _on_player_death() -> void:
	player_died.emit()
	_player.set_process(false)
	_player.set_physics_process(false)


func _on_health_damage_taken(amount: float, _source: Node) -> void:
	CombatSfx.play(self, SFX_HURT, -1.0)
	player_took_damage.emit(amount)


# API para UI/otros sistemas
func get_current_health() -> float:
	return _health_system.current_health if _health_system else 0.0


func get_max_health() -> float:
	return _health_system.max_health if _health_system else 0.0


func get_attack_damage() -> float:
	var d: float = base_attack_damage
	if _experience_system:
		d = _experience_system.attack_damage
	if combat_balance:
		d *= combat_balance.player_damage_multiplier
	return d


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
	if not _experience_system:
		return
	var exp_amount := 28
	if enemy.has_method("get_experience_reward"):
		exp_amount = int(enemy.call("get_experience_reward"))
	if combat_balance:
		exp_amount = int(round(float(exp_amount) * combat_balance.experience_gain_multiplier))
	_experience_system.gain_experience(exp_amount, "enemy_kill")
	enemy_killed.emit(enemy, exp_amount)