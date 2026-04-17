extends CharacterBody3D
## Enemigo tanque: mucha salud, lento, alto daño.

@export var max_health: float = 150.0
@export var move_speed: float = 1.5
@export var attack_damage: float = 25.0
@export var attack_range: float = 2.0
@export var attack_cooldown: float = 2.5
@export var detection_range: float = 10.0
@export var defense: float = 10.0  # Reducción de daño adicional

@export var drop_table: Array[Dictionary] = [
	{"item_id": "health_potion", "chance": 0.6, "min_amount": 1, "max_amount": 2},
	{"item_id": "leather_armor", "chance": 0.2, "min_amount": 1, "max_amount": 1},
	{"item_id": "gold_coin", "chance": 1.0, "min_amount": 5, "max_amount": 15}
]

signal enemy_died
signal health_changed(current: float, max: float)

var _target: Node3D = null
var _attack_timer: float = 0.0
var _health_system: HealthSystem
var _charge_cooldown: float = 0.0
var _is_charging: bool = false
var _charge_direction: Vector3 = Vector3.ZERO
var _charge_speed: float = 8.0

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
	add_to_group("tank_enemies")
	collision_layer = 1
	collision_mask = 3

	if not has_node("MeshInstance3D"):
		var mesh := MeshInstance3D.new()
		mesh.mesh = BoxMesh.new()
		(mesh.mesh as BoxMesh).size = Vector3(1.2, 2.0, 1.2)
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(0.3, 0.1, 0.1)
		mesh.set_surface_override_material(0, material)
		mesh.name = "MeshInstance3D"
		add_child(mesh)
		var collision := get_node_or_null("CollisionShape3D")
		if collision:
			var shape := BoxShape3D.new()
			shape.size = Vector3(1.2, 2.0, 1.2)
			collision.shape = shape

	_add_health_bar()

	print("Tanque enemigo creado: ", max_health, " HP, ", defense, " DEF")


func _process(delta: float) -> void:
	if not _health_system.is_alive():
		return
	
	if _attack_timer > 0.0:
		_attack_timer -= delta
	
	if _charge_cooldown > 0.0:
		_charge_cooldown -= delta
	
	_update_target()
	
	if _is_charging:
		_update_charge(delta)
	else:
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
	
	# Moverse hacia el jugador (lento)
	var direction = (_target.global_position - global_position).normalized()
	direction.y = 0
	
	velocity = direction * move_speed
	
	# Rotar hacia el jugador (lento también)
	if direction.length_squared() > 0.001:
		var target_rotation = atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, delta * 2.0)
	
	move_and_slide()
	
	# Ocasionalmente cargar hacia el jugador
	if _charge_cooldown <= 0.0 and randf() < 0.01:  # 1% chance por frame
		_start_charge()


func _update_charge(delta: float) -> void:
	if not _is_charging:
		return
	
	# Moverse en dirección de carga
	velocity = _charge_direction * _charge_speed
	
	# Reducir velocidad gradualmente
	_charge_speed = lerp(_charge_speed, 0.0, delta * 2.0)
	
	if _charge_speed < 1.0:
		_is_charging = false
		_charge_cooldown = 5.0  # Cooldown de carga
		_charge_speed = 8.0
	
	move_and_slide()
	
	# Daño por contacto durante la carga
	if _target:
		var distance = global_position.distance_to(_target.global_position)
		if distance < 2.5:
			_apply_charge_damage()


func _start_charge() -> void:
	if not _target or _is_charging:
		return
	
	_is_charging = true
	_charge_direction = (_target.global_position - global_position).normalized()
	_charge_direction.y = 0
	_charge_speed = 8.0
	
	print("¡Tanque enemigo carga!")


func _apply_charge_damage() -> void:
	if _target and _target.has_method("take_damage"):
		var charge_damage = attack_damage * 1.5  # Daño extra por carga
		_target.take_damage(charge_damage, self)
		print("Daño de carga: ", charge_damage)


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
	
	# Ataque pesado
	if _target.has_method("take_damage"):
		_target.take_damage(attack_damage, self)
		print("Tanque atacó: ", attack_damage, " daño")
	
	# Efecto visual
	_play_attack_effect()


func _play_attack_effect() -> void:
	var mesh = get_node_or_null("MeshInstance3D")
	if mesh:
		var original_scale = mesh.scale
		var tween = create_tween()
		tween.tween_property(mesh, "scale", original_scale * 1.2, 0.1)
		tween.tween_property(mesh, "scale", original_scale, 0.2)


func take_damage(amount: float, source: Node = null) -> bool:
	if not _health_system.is_alive():
		return false
	
	# Aplicar reducción de daño por defensa
	var reduced_amount = amount * (100.0 / (100.0 + defense))
	var actual_damage = max(reduced_amount, 1.0)  # Mínimo 1 de daño
	
	print("Daño recibido: ", amount, " -> ", actual_damage, " (DEF: ", defense, ")")
	
	var took_damage = _health_system.take_damage(actual_damage, source)
	if took_damage:
		# Feedback visual
		var mesh = get_node_or_null("MeshInstance3D")
		if mesh:
			var original_color = mesh.get_surface_override_material(0).albedo_color
			mesh.get_surface_override_material(0).albedo_color = Color(1.0, 0.3, 0.3)
			
			await get_tree().create_timer(0.3).timeout
			if is_instance_valid(mesh):
				mesh.get_surface_override_material(0).albedo_color = original_color
	
	return took_damage


func _on_death() -> void:
	print("Tanque enemigo murió!")
	enemy_died.emit()
	
	# Generar drops
	_generate_drops()
	
	# Efecto de muerte (más dramático)
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector3.ZERO, 1.0)
	tween.tween_property(self, "rotation:y", rotation.y + PI * 2, 1.0)
	
	await tween.finished
	queue_free()


func _on_health_changed(current: float, max_hp: float) -> void:
	health_changed.emit(current, max_hp)
	
	# Cambiar color según salud restante
	var mesh = get_node_or_null("MeshInstance3D")
	if mesh:
		var health_percent = current / max_hp
		var material = mesh.get_surface_override_material(0).duplicate()
		
		if health_percent > 0.6:
			material.albedo_color = Color(0.3, 0.1, 0.1)  # Rojo oscuro
		elif health_percent > 0.3:
			material.albedo_color = Color(0.4, 0.2, 0.1)  # Marrón
		else:
			material.albedo_color = Color(0.5, 0.3, 0.2)  # Marrón claro (dañado)
		
		mesh.set_surface_override_material(0, material)


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
	
	var offset = Vector3(randf_range(-1.5, 1.5), 0.5, randf_range(-1.5, 1.5))
	item.global_position = global_position + offset
	
	get_parent().add_child(item)


# API
func get_current_health() -> float:
	return _health_system.current_health if _health_system else 0.0

func get_max_health() -> float:
	return _health_system.max_health if _health_system else 0.0

func is_alive() -> bool:
	return _health_system.is_alive() if _health_system else false

func get_defense() -> float:
	return defense


func get_experience_reward() -> int:
	return 110