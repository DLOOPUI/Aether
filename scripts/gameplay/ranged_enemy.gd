extends CharacterBody3D
## Enemigo que ataca a distancia con proyectiles.

const ENEMY_PROJECTILE := preload("res://scripts/gameplay/enemy_projectile_area.gd")
const COMBAT_BALANCE_PATH := "res://resources/combat_balance.tres"

@export var max_health: float = 40.0
@export var move_speed: float = 2.5
@export var attack_damage: float = 15.0
@export var attack_range: float = 10.0
@export var min_range: float = 5.0  # Distancia mínima para atacar
@export var attack_cooldown: float = 2.0
@export var detection_range: float = 12.0
@export var projectile_speed: float = 15.0
@export var separation_radius: float = 2.2
@export var separation_strength: float = 2.0

@export var drop_table: Array[Dictionary] = [
	{"item_id": "health_potion", "chance": 0.4, "min_amount": 1, "max_amount": 1},
	{"item_id": "mana_potion", "chance": 0.4, "min_amount": 1, "max_amount": 1},
	{"item_id": "gold_coin", "chance": 0.9, "min_amount": 2, "max_amount": 8}
]

signal enemy_died
signal health_changed(current: float, max_hp: float)

var _target: Node3D = null
var _attack_timer: float = 0.0
var _health_system: HealthSystem
var _is_retreating: bool = false

@onready var _player: Node3D = get_tree().get_first_node_in_group("player")
var _projectile_spawn: Node3D


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
	add_to_group("ranged_enemies")
	collision_layer = 1
	collision_mask = 3

	if VisualMeshUtils.find_first_mesh_instance(self) == null:
		var mesh := MeshInstance3D.new()
		mesh.mesh = BoxMesh.new()
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(0.2, 0.2, 0.8)
		mesh.set_surface_override_material(0, material)
		mesh.name = "MeshInstance3D"
		add_child(mesh)

	if has_node("ProjectileSpawn"):
		_projectile_spawn = $ProjectileSpawn
	else:
		_projectile_spawn = Node3D.new()
		_projectile_spawn.name = "ProjectileSpawn"
		_projectile_spawn.position = Vector3(0, 1.5, 0)
		add_child(_projectile_spawn)

	_add_health_bar()


func _process(delta: float) -> void:
	if not _health_system.is_alive():
		return
	
	if _attack_timer > 0.0:
		_attack_timer -= delta
	
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


func _update_movement(delta: float) -> void:
	if not _target or not _health_system.is_alive():
		velocity = Vector3.ZERO
		move_and_slide()
		return
	
	var distance = global_position.distance_to(_target.global_position)
	
	# Comportamiento de enemigo a distancia:
	# - Mantener distancia óptima (entre min_range y attack_range)
	# - Retroceder si el jugador está muy cerca
	# - Acercarse si está muy lejos
	
	var direction = (_target.global_position - global_position).normalized()
	direction.y = 0
	
	if distance < min_range:
		# Demasiado cerca, retroceder
		_is_retreating = true
		velocity = -direction * move_speed * 1.2  # Retrocede más rápido
	elif distance > attack_range:
		# Demasiado lejos, acercarse
		_is_retreating = false
		velocity = direction * move_speed
	else:
		# Distancia óptima, moverse lateralmente
		_is_retreating = false
		var lateral = direction.cross(Vector3.UP).normalized()
		# Cambiar dirección lateral periódicamente
		var time = Time.get_ticks_msec() / 1000.0
		var lateral_dir = sin(time)  # Oscila entre -1 y 1
		velocity = lateral * lateral_dir * move_speed * 0.5
	
	velocity += _get_separation_force()
	
	# Rotar hacia el jugador
	if direction.length_squared() > 0.001:
		var target_rotation = atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, delta * 3.0)
	
	move_and_slide()


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


func _update_attack() -> void:
	if not _target or not _health_system.is_alive():
		return
	
	var distance = global_position.distance_to(_target.global_position)
	
	# Atacar si está en rango y no está retrocediendo
	if distance <= attack_range and distance >= min_range and not _is_retreating and _attack_timer <= 0.0:
		_attack_target()


func _attack_target() -> void:
	if not _target or not _health_system.is_alive():
		return
	
	_attack_timer = attack_cooldown
	
	# Disparar proyectil
	_shoot_projectile()
	
	print("Enemigo a distancia disparó al jugador")


func _shoot_projectile() -> void:
	var target_pos := _target.global_position
	var to_target := target_pos - _projectile_spawn.global_position
	to_target.y += 0.5
	var direction := to_target.normalized()
	var projectile := ENEMY_PROJECTILE.new()
	projectile.setup(direction * projectile_speed, attack_damage, self)
	get_parent().add_child(projectile)
	projectile.global_position = _projectile_spawn.global_position
	_play_shot_effect()


func _play_shot_effect() -> void:
	VisualMeshUtils.flash_mesh_albedo(self, Color(0.5, 0.5, 1.0), 0.1)


func take_damage(amount: float, source: Node = null) -> bool:
	if not _health_system.is_alive():
		return false
	
	var took_damage = _health_system.take_damage(amount, source)
	if took_damage:
		VisualMeshUtils.flash_mesh_albedo(self, Color(1.0, 0.5, 0.5), 0.2)
	return took_damage


func _on_death() -> void:
	print("Enemigo a distancia murió!")
	enemy_died.emit()
	
	# Generar drops
	_generate_drops()
	
	# Desactivar
	collision_layer = 0
	collision_mask = 0
	set_process(false)
	set_physics_process(false)
	
	# Animación de muerte
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3.ZERO, 0.5)
	tween.tween_callback(queue_free)


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
	var offset := Vector3(randf_range(-1, 1), 0.5, randf_range(-1, 1))
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
	return 48


func _drop_chance_multiplier() -> float:
	var balance := ResourceLoader.load(COMBAT_BALANCE_PATH) as CombatBalance
	if balance:
		return balance.drop_chance_multiplier
	return 1.0