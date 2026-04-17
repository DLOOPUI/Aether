extends CharacterBody3D
## Enemigo básico con IA simple, salud y sistema de daño.

const COMBAT_BALANCE_PATH := "res://resources/combat_balance.tres"

@export var max_health: float = 50.0
@export var move_speed: float = 3.0
@export var attack_damage: float = 10.0
@export var attack_range: float = 1.5
@export var attack_cooldown: float = 1.5
@export var detection_range: float = 8.0
@export var separation_radius: float = 1.8
@export var separation_strength: float = 2.5
@export var drop_table: Array[Dictionary] = [
	{"item_id": "health_potion", "chance": 0.3, "min_amount": 1, "max_amount": 1},
	{"item_id": "gold_coin", "chance": 0.8, "min_amount": 1, "max_amount": 5},
	{"item_id": "mana_potion", "chance": 0.2, "min_amount": 1, "max_amount": 1}
]

signal enemy_died
signal health_changed(current: float, max_hp: float)

var _target: Node3D = null
var _attack_timer: float = 0.0
var _health_system: HealthSystem

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
	collision_layer = 1
	collision_mask = 3
	if has_node("Visual"):
		VisualMeshUtils.ensure_node3d_visible_recursive($Visual)

	if VisualMeshUtils.find_first_mesh_instance(self) == null:
		var mesh := MeshInstance3D.new()
		mesh.mesh = BoxMesh.new()
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(0.8, 0.2, 0.2)
		mesh.set_surface_override_material(0, material)
		mesh.name = "MeshInstance3D"
		add_child(mesh)

	_add_health_bar()


func _process(delta: float) -> void:
	if not _health_system.is_alive():
		return
	
	if _attack_timer > 0.0:
		_attack_timer -= delta
	
	_update_target()
	_update_movement(delta)


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
	
	# Moverse hacia el jugador
	var direction = (_target.global_position - global_position).normalized()
	direction.y = 0  # Mantener en el plano horizontal
	var separation = _get_separation_force()
	velocity = (direction + separation).normalized() * move_speed
	
	# Rotar hacia el jugador
	if direction.length_squared() > 0.001:
		var target_rotation = atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, delta * 5.0)
	
	move_and_slide()
	
	# Atacar si está en rango
	var distance = global_position.distance_to(_target.global_position)
	if distance <= attack_range and _attack_timer <= 0.0:
		_attack_target()


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


func _attack_target() -> void:
	if not _target or not _health_system.is_alive():
		return
	
	_attack_timer = attack_cooldown
	
	# Aplicar daño al jugador
	if _target.has_method("take_damage"):
		_target.take_damage(attack_damage, self)
		print("Enemy attacked player for ", attack_damage, " damage")


func take_damage(amount: float, source: Node = null) -> bool:
	if not _health_system.is_alive():
		return false
	
	var took_damage = _health_system.take_damage(amount, source)
	if took_damage:
		VisualMeshUtils.flash_mesh_albedo(self, Color(1.0, 0.5, 0.5), 0.2)
	return took_damage


func _on_death() -> void:
	print("Enemy died!")
	enemy_died.emit()
	
	# Notificar a sistemas que este enemigo murió
	_notify_death_to_systems()
	
	# Desactivar colisiones y física
	collision_layer = 0
	collision_mask = 0
	set_process(false)
	set_physics_process(false)
	
	# Animación de muerte simple: desaparecer
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3.ZERO, 0.5)
	tween.tween_callback(queue_free)


func _on_health_changed(current: float, max_hp: float) -> void:
	health_changed.emit(current, max_hp)


# API para otros sistemas
func get_current_health() -> float:
	return _health_system.current_health if _health_system else 0.0


func get_max_health() -> float:
	return _health_system.max_health if _health_system else 0.0


func is_alive() -> bool:
	return _health_system.is_alive() if _health_system else false


func get_experience_reward() -> int:
	return 32


func _add_health_bar() -> void:
	# Cargar en runtime (evita que el fallo de la escena bloquee preload del enemigo)
	var health_bar_scene: PackedScene = load("res://scenes/ui/enemy_health_bar.tscn") as PackedScene
	if health_bar_scene:
		var health_bar = health_bar_scene.instantiate()
		health_bar.health_system = _health_system
		add_child(health_bar)
		print("Barra de salud añadida al enemigo")


func _notify_death_to_systems() -> void:
	# Notificar a todos los sistemas interesados que este enemigo murió
	# Podría usarse para quests, logros, estadísticas, etc.
	
	# Emitir señal global (si existe un EventBus o similar)
	# Por ahora, los sistemas se conectarán directamente a enemy_died
	
	# Generar drops
	_generate_drops()


func _generate_drops() -> void:
	# Generar items basados en la drop table
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
	print("Drop generado: ", drop_id, " x", qty)


func _drop_chance_multiplier() -> float:
	var balance := ResourceLoader.load(COMBAT_BALANCE_PATH) as CombatBalance
	if balance:
		return balance.drop_chance_multiplier
	return 1.0
