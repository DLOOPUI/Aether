extends CharacterBody3D
## Enemigo que ataca a distancia con proyectiles.

const ENEMY_PROJECTILE := preload("res://scripts/gameplay/enemy_projectile_area.gd")

@export var max_health: float = 40.0
@export var move_speed: float = 2.5
@export var attack_damage: float = 15.0
@export var attack_range: float = 10.0
@export var min_range: float = 5.0  # Distancia mínima para atacar
@export var attack_cooldown: float = 2.0
@export var detection_range: float = 12.0
@export var projectile_speed: float = 15.0

@export var drop_table: Array[Dictionary] = [
	{"item_id": "health_potion", "chance": 0.4, "min_amount": 1, "max_amount": 1},
	{"item_id": "mana_potion", "chance": 0.4, "min_amount": 1, "max_amount": 1},
	{"item_id": "gold_coin", "chance": 0.9, "min_amount": 2, "max_amount": 8}
]

signal enemy_died
signal health_changed(current: float, max: float)

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

	if not has_node("MeshInstance3D"):
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
	
	# Rotar hacia el jugador
	if direction.length_squared() > 0.001:
		var target_rotation = atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, delta * 3.0)
	
	move_and_slide()


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
	# Efecto visual simple (podría ser partículas)
	# Por ahora, cambiar color temporalmente
	var mesh = get_node_or_null("MeshInstance3D")
	if mesh:
		var original_color = mesh.get_surface_override_material(0).albedo_color
		mesh.get_surface_override_material(0).albedo_color = Color(0.5, 0.5, 1.0)
		
		await get_tree().create_timer(0.1).timeout
		if is_instance_valid(mesh):
			mesh.get_surface_override_material(0).albedo_color = original_color


func take_damage(amount: float, source: Node = null) -> bool:
	if not _health_system.is_alive():
		return false
	
	var took_damage = _health_system.take_damage(amount, source)
	if took_damage:
		# Feedback visual
		var mesh = get_node_or_null("MeshInstance3D")
		if mesh:
			var original_color = mesh.get_surface_override_material(0).albedo_color
			mesh.get_surface_override_material(0).albedo_color = Color(1.0, 0.5, 0.5)
			
			await get_tree().create_timer(0.2).timeout
			if is_instance_valid(mesh):
				mesh.get_surface_override_material(0).albedo_color = original_color
	
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
	var health_bar_scene = preload("res://scenes/ui/enemy_health_bar.tscn")
	if health_bar_scene:
		var health_bar = health_bar_scene.instantiate()
		health_bar.health_system = _health_system
		add_child(health_bar)


func _generate_drops() -> void:
	for drop_info in drop_table:
		var chance = drop_info.get("chance", 0.0)
		if randf() <= chance:
			var item_id = drop_info.get("item_id", "")
			var min_amount = drop_info.get("min_amount", 1)
			var max_amount = drop_info.get("max_amount", 1)
			var amount = randi_range(min_amount, max_amount)
			
			_spawn_item_drop(item_id, amount)


func _spawn_item_drop(item_id: String, amount: int) -> void:
	var item_scene = preload("res://scenes/gameplay/item_drop.tscn")
	if not item_scene:
		return
	
	var item = item_scene.instantiate()
	item.item_id = item_id
	item.amount = amount
	
	var offset = Vector3(randf_range(-1, 1), 0.5, randf_range(-1, 1))
	item.global_position = global_position + offset
	
	get_parent().add_child(item)


# API
func get_current_health() -> float:
	return _health_system.current_health if _health_system else 0.0

func get_max_health() -> float:
	return _health_system.max_health if _health_system else 0.0

func is_alive() -> bool:
	return _health_system.is_alive() if _health_system else false


func get_experience_reward() -> int:
	return 48