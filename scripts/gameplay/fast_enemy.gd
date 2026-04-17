extends CharacterBody3D
## Enemigo rápido: poca salud, muy rápido, bajo daño, ataques rápidos.

const COMBAT_BALANCE_PATH := "res://resources/combat_balance.tres"

@export var max_health: float = 20.0
@export var move_speed: float = 6.0
@export var sprint_speed: float = 10.0
@export var attack_damage: float = 8.0
@export var attack_range: float = 1.2
@export var attack_cooldown: float = 0.5
@export var detection_range: float = 12.0
@export var evasion_chance: float = 0.3  # 30% chance de esquivar ataques
@export var separation_radius: float = 1.6
@export var separation_strength: float = 3.0

@export var drop_table: Array[Dictionary] = [
	{"item_id": "gold_coin", "chance": 0.7, "min_amount": 1, "max_amount": 3},
	{"item_id": "iron_sword", "chance": 0.1, "min_amount": 1, "max_amount": 1}
]

signal enemy_died
signal health_changed(current: float, max_hp: float)

var _target: Node3D = null
var _attack_timer: float = 0.0
var _health_system: HealthSystem
var _is_sprinting: bool = false
var _sprint_timer: float = 0.0
var _evasion_timer: float = 0.0
var _movement_pattern: int = 0
var _pattern_timer: float = 0.0

@onready var _player: Node3D = get_tree().get_first_node_in_group("player")


func _ready() -> void:
	if has_node("HealthSystem"):
		_health_system = $HealthSystem as HealthSystem
		_health_system.max_health = max_health
		_health_system.current_health = max_health
	else:
		_health_system = HealthSystem.new()
		_health_system.max_health = max_health
		_health_system.current_health = max_health
		add_child(_health_system)
	_health_system.health_depleted.connect(_on_death)
	_health_system.health_changed.connect(_on_health_changed)

	add_to_group("enemies")
	add_to_group("fast_enemies")
	collision_layer = 1
	collision_mask = 3
	if has_node("Visual"):
		VisualMeshUtils.ensure_node3d_visible_recursive($Visual)

	if VisualMeshUtils.find_first_mesh_instance(self) == null:
		var mesh := MeshInstance3D.new()
		mesh.mesh = BoxMesh.new()
		(mesh.mesh as BoxMesh).size = Vector3(0.6, 1.2, 0.6)
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(0.8, 0.8, 0.2)
		mesh.set_surface_override_material(0, material)
		mesh.name = "MeshInstance3D"
		add_child(mesh)
		var collision := get_node_or_null("CollisionShape3D")
		if collision:
			var shape := BoxShape3D.new()
			shape.size = Vector3(0.6, 1.2, 0.6)
			collision.shape = shape

	_add_health_bar()

	print("Enemigo rápido creado: ", max_health, " HP, ", move_speed, " velocidad")


func _process(delta: float) -> void:
	if not _health_system.is_alive():
		return
	
	if _attack_timer > 0.0:
		_attack_timer -= delta
	
	if _sprint_timer > 0.0:
		_sprint_timer -= delta
		if _sprint_timer <= 0.0:
			_is_sprinting = false
	
	if _evasion_timer > 0.0:
		_evasion_timer -= delta
	
	if _pattern_timer > 0.0:
		_pattern_timer -= delta
	else:
		_change_movement_pattern()
	
	_update_target()
	_update_movement(delta)
	_update_attack()


func _update_target() -> void:
	if _player and _health_system.is_alive():
		var distance = global_position.distance_to(_player.global_position)
		if distance <= detection_range:
			_target = _player
		else:
			_target = null
	else:
		_target = null


func _change_movement_pattern() -> void:
	_movement_pattern = randi_range(0, 3)
	_pattern_timer = randf_range(1.0, 3.0)
	
	# Ocasionalmente activar sprint
	if randf() < 0.3 and not _is_sprinting:
		_is_sprinting = true
		_sprint_timer = randf_range(1.0, 2.0)


func _update_movement(delta: float) -> void:
	if not _target or not _health_system.is_alive():
		velocity = Vector3.ZERO
		move_and_slide()
		return
	
	var current_speed = sprint_speed if _is_sprinting else move_speed
	var distance = global_position.distance_to(_target.global_position)
	
	var direction = (_target.global_position - global_position).normalized()
	direction.y = 0
	
	# Patrones de movimiento diferentes
	var movement = Vector3.ZERO
	
	match _movement_pattern:
		0:  # Perseguir directamente
			movement = direction * current_speed
		1:  # Moverse en círculo alrededor del jugador
			var lateral = direction.cross(Vector3.UP).normalized()
			movement = (direction * 0.7 + lateral * 0.3) * current_speed
		2:  # Zig-zag
			var time = Time.get_ticks_msec() / 300.0
			var zigzag = sin(time) * 0.5
			var lateral = direction.cross(Vector3.UP).normalized()
			movement = (direction + lateral * zigzag).normalized() * current_speed
		3:  # Retroceder y acercarse
			if distance < 3.0:
				movement = -direction * current_speed * 0.8
			else:
				movement = direction * current_speed
	
	velocity = movement + _get_separation_force()
	
	# Rotar rápidamente hacia la dirección de movimiento
	if velocity.length_squared() > 0.001:
		var target_rotation = atan2(velocity.x, velocity.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, delta * 10.0)  # Rotación rápida
	
	move_and_slide()
	
	# Efecto visual de velocidad
	_update_speed_visuals()


func _get_separation_force() -> Vector3:
	var force := Vector3.ZERO
	for e in get_tree().get_nodes_in_group("enemies"):
		if e == self or not (e is Node3D):
			continue
		var d := global_position.distance_to((e as Node3D).global_position)
		if d > 0.001 and d < separation_radius:
			var away := (global_position - (e as Node3D).global_position).normalized()
			force += away * ((separation_radius - d) / separation_radius)
	if force.length_squared() > 0.0001:
		force = force.normalized() * separation_strength
	return force


func _update_speed_visuals() -> void:
	var vis := get_node_or_null("Visual") as Node3D
	if vis:
		var speed_factor = velocity.length() / move_speed
		var target_scale = Vector3(1.0, 1.0, 1.0 + speed_factor * 0.3)
		vis.scale = vis.scale.lerp(target_scale, 0.1)
		if _is_sprinting:
			var mesh := VisualMeshUtils.find_first_mesh_instance(self)
			if mesh:
				var material := VisualMeshUtils.duplicate_surface0_as_override(mesh)
				if material:
					material.albedo_color = Color(1.0, 1.0, 0.5)


func _update_attack() -> void:
	if not _target or not _health_system.is_alive():
		return
	
	var distance = global_position.distance_to(_target.global_position)
	if distance <= attack_range and _attack_timer <= 0.0:
		_attack_target()


func _attack_target() -> void:
	if not _target or not _health_system.is_alive():
		return
	
	_attack_timer = attack_cooldown
	
	# Ataque rápido
	if _target.has_method("take_damage"):
		_target.take_damage(attack_damage, self)
		print("Enemigo rápido atacó: ", attack_damage, " daño")
	
	# Retroceder después de atacar
	_quick_retreat()
	
	# Efecto visual
	_play_attack_effect()


func _quick_retreat() -> void:
	if not _target:
		return
	
	# Retroceder rápidamente
	var retreat_dir = (global_position - _target.global_position).normalized()
	retreat_dir.y = 0
	
	var tween = create_tween()
	var original_pos = position
	var retreat_pos = position + retreat_dir * 3.0
	
	tween.tween_property(self, "position", retreat_pos, 0.2)
	tween.tween_property(self, "position", original_pos + retreat_dir * 1.0, 0.3)


func _play_attack_effect() -> void:
	var vis := get_node_or_null("Visual") as Node3D
	if vis:
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(vis, "scale", Vector3(1.3, 0.7, 1.3), 0.1)
		tween.tween_property(vis, "scale", Vector3(1.0, 1.0, 1.0), 0.2)


func take_damage(amount: float, source: Node = null) -> bool:
	if not _health_system.is_alive():
		return false
	
	# Chance de esquivar el ataque
	if _evasion_timer <= 0.0 and randf() < evasion_chance:
		print("¡Enemigo rápido esquivó el ataque!")
		_play_evasion_effect()
		_evasion_timer = 2.0  # Cooldown de evasión
		return false
	
	var took_damage = _health_system.take_damage(amount, source)
	if took_damage:
		VisualMeshUtils.flash_mesh_albedo(self, Color(1.0, 0.2, 0.2), 0.1)
		# Activar sprint al recibir daño
		if not _is_sprinting:
			_is_sprinting = true
			_sprint_timer = 1.5
	
	return took_damage


func _play_evasion_effect() -> void:
	VisualMeshUtils.flash_mesh_albedo(self, Color(1.0, 1.0, 1.0), 0.12)
	var evade_dir := Vector3(randf_range(-1, 1), 0.0, randf_range(-1, 1))
	if evade_dir.length_squared() < 0.001:
		evade_dir = Vector3(1, 0, 0)
	evade_dir = evade_dir.normalized()
	var original_pos := position
	var tw2 := create_tween()
	tw2.tween_property(self, "position", original_pos + evade_dir * 2.0, 0.2)
	tw2.tween_property(self, "position", original_pos + evade_dir * 0.5, 0.3)


func _on_death() -> void:
	print("Enemigo rápido murió!")
	enemy_died.emit()
	
	# Generar drops
	_generate_drops()
	
	# Animación de muerte rápida
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector3.ZERO, 0.3)
	tween.tween_property(self, "rotation:y", rotation.y + PI * 4, 0.3)
	
	await tween.finished
	queue_free()


func _on_health_changed(current: float, max_hp: float) -> void:
	health_changed.emit(current, max_hp)


func _add_health_bar() -> void:
	var health_bar_scene: PackedScene = load("res://scenes/ui/enemy_health_bar.tscn") as PackedScene
	if health_bar_scene:
		var health_bar = health_bar_scene.instantiate()
		health_bar.health_system = _health_system
		add_child(health_bar)


func _generate_drops() -> void:
	var chance_mult := _drop_chance_multiplier()
	for drop_info in drop_table:
		var chance = clampf(drop_info.get("chance", 0.0) * chance_mult, 0.0, 1.0)
		if randf() <= chance:
			var drop_id: String = str(drop_info.get("item_id", ""))
			var min_amount = drop_info.get("min_amount", 1)
			var max_amount = drop_info.get("max_amount", 1)
			var qty: int = randi_range(min_amount, max_amount)
			_spawn_item_drop(drop_id, qty)


func _spawn_item_drop(drop_id: String, qty: int) -> void:
	var item_scene: PackedScene = load("res://scenes/gameplay/item_drop.tscn") as PackedScene
	if not item_scene:
		return
	var item := item_scene.instantiate() as ItemDrop
	item.item_id = drop_id
	item.amount = qty
	var offset := Vector3(randf_range(-0.8, 0.8), 0.3, randf_range(-0.8, 0.8))
	get_parent().add_child(item)
	item.global_position = global_position + offset


# API
func get_current_health() -> float:
	return _health_system.current_health if _health_system else 0.0

func get_max_health() -> float:
	return _health_system.max_health if _health_system else 0.0

func is_alive() -> bool:
	return _health_system.is_alive() if _health_system else false


func get_experience_reward() -> int:
	return 42


func get_speed() -> float:
	return sprint_speed if _is_sprinting else move_speed


func _drop_chance_multiplier() -> float:
	var balance := ResourceLoader.load(COMBAT_BALANCE_PATH) as CombatBalance
	if balance:
		return balance.drop_chance_multiplier
	return 1.0
