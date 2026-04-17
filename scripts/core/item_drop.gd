class_name ItemDrop
extends Area3D
## Item que puede ser recogido por el jugador.

@export var item_id: String = "health_potion"
@export var amount: int = 1
@export var auto_pickup: bool = true
@export var pickup_range: float = 2.0

@onready var _mesh: MeshInstance3D = $MeshInstance3D
@onready var _collision: CollisionShape3D = $CollisionShape3D

var _item_data: Dictionary = {}
var _collected: bool = false
var _rotation_speed: float = 1.0
var _bob_height: float = 0.2
var _bob_speed: float = 2.0
var _original_y: float = 0.0


func _ready() -> void:
	_setup_item_data()
	_setup_visuals()
	_setup_collision()
	
	_original_y = position.y
	
	monitoring = true
	body_entered.connect(_on_body_entered)
	
	# Iniciar animación
	_start_idle_animation()


func _setup_item_data() -> void:
	# Datos de items predefinidos
	var items_db = {
		"health_potion": {
			"name": "Poción de Salud",
			"description": "Restaura 30 puntos de salud.",
			"icon_color": Color(0.8, 0.2, 0.2),
			"value": 10,
			"type": "consumable",
			"effect": "heal",
			"effect_amount": 30.0
		},
		"mana_potion": {
			"name": "Poción de Maná",
			"description": "Restaura 20 puntos de maná.",
			"icon_color": Color(0.2, 0.2, 0.8),
			"value": 10,
			"type": "consumable",
			"effect": "restore_mana",
			"effect_amount": 20.0
		},
		"gold_coin": {
			"name": "Moneda de Oro",
			"description": "Moneda valiosa.",
			"icon_color": Color(0.9, 0.8, 0.2),
			"value": 1,
			"type": "currency",
			"stackable": true
		},
		"iron_sword": {
			"name": "Espada de Hierro",
			"description": "Una espada básica de hierro.",
			"icon_color": Color(0.6, 0.6, 0.6),
			"value": 50,
			"type": "weapon",
			"damage_bonus": 5.0
		},
		"leather_armor": {
			"name": "Armadura de Cuero",
			"description": "Armadura ligera de cuero.",
			"icon_color": Color(0.5, 0.3, 0.1),
			"value": 40,
			"type": "armor",
			"defense_bonus": 3.0
		}
	}
	
	if items_db.has(item_id):
		_item_data = items_db[item_id].duplicate()
		_item_data["id"] = item_id
		_item_data["amount"] = amount
	else:
		# Item por defecto
		_item_data = {
			"id": item_id,
			"name": "Item Desconocido",
			"description": "Un item misterioso.",
			"icon_color": Color(0.5, 0.5, 0.5),
			"value": 1,
			"type": "misc",
			"amount": amount
		}


func _setup_visuals() -> void:
	# Crear mesh basado en el tipo de item
	var mesh = null
	var material = StandardMaterial3D.new()
	
	match _item_data.type:
		"consumable":
			mesh = SphereMesh.new()
			(mesh as SphereMesh).radius = 0.3
			(mesh as SphereMesh).height = 0.6
		"currency":
			mesh = CylinderMesh.new()
			(mesh as CylinderMesh).top_radius = 0.4
			(mesh as CylinderMesh).bottom_radius = 0.4
			(mesh as CylinderMesh).height = 0.1
		"weapon":
			mesh = BoxMesh.new()
			(mesh as BoxMesh).size = Vector3(0.1, 0.8, 0.1)
		"armor":
			mesh = BoxMesh.new()
			(mesh as BoxMesh).size = Vector3(0.6, 0.8, 0.3)
		_:
			mesh = BoxMesh.new()
			(mesh as BoxMesh).size = Vector3(0.5, 0.5, 0.5)
	
	if mesh:
		_mesh.mesh = mesh
	
	# Aplicar color
	material.albedo_color = _item_data.icon_color
	material.metallic = 0.3
	material.roughness = 0.4
	
	# Efecto brillante para items raros/valiosos
	if _item_data.value >= 100:
		material.emission = _item_data.icon_color * 0.3
		material.emission_enabled = true
	
	_mesh.set_surface_override_material(0, material)


func _setup_collision() -> void:
	# Crear forma de colisión basada en el mesh
	if _mesh.mesh is SphereMesh:
		var shape = SphereShape3D.new()
		shape.radius = 0.5
		_collision.shape = shape
	elif _mesh.mesh is CylinderMesh:
		var shape = CylinderShape3D.new()
		shape.radius = 0.5
		shape.height = 0.2
		_collision.shape = shape
	else:
		var shape = BoxShape3D.new()
		shape.size = Vector3(0.8, 0.8, 0.8)
		_collision.shape = shape
	
	# Capa 2 = jugador (ver player_with_combat.tscn); capa 1 = mundo/enemigos
	collision_layer = 0
	collision_mask = 2


func _start_idle_animation() -> void:
	# Rotación continua
	var rotate_tween = create_tween()
	rotate_tween.set_loops()
	rotate_tween.tween_property(self, "rotation:y", rotation.y + TAU, _rotation_speed)
	
	# Movimiento de flotación
	var bob_tween = create_tween()
	bob_tween.set_loops()
	bob_tween.tween_property(self, "position:y", _original_y + _bob_height, _bob_speed / 2)
	bob_tween.tween_property(self, "position:y", _original_y, _bob_speed / 2)


func _process(_delta: float) -> void:
	if _collected:
		return
	
	# Auto-pickup si el jugador está cerca
	if auto_pickup:
		var player = get_tree().get_first_node_in_group("player")
		if player:
			var distance = global_position.distance_to(player.global_position)
			if distance <= pickup_range:
				_try_pickup(player)


func _on_body_entered(body: Node) -> void:
	if _collected:
		return
	
	if body.is_in_group("player"):
		_try_pickup(body)


func _try_pickup(player: Node) -> void:
	if _collected:
		return
	
	_collected = true
	
	# Notificar al jugador/inventario
	if player.has_method("pickup_item"):
		var success = player.pickup_item(_item_data)
		if success:
			_on_pickup_success()
		else:
			# Inventario lleno o error
			_collected = false
			return
	else:
		# Jugador no tiene sistema de inventario, aplicar efecto directamente
		_apply_item_effect(player)
		_on_pickup_success()


func _apply_item_effect(player: Node) -> void:
	match _item_data.get("effect", ""):
		"heal":
			if player.has_node("PlayerCombat"):
				var combat = player.get_node("PlayerCombat")
				if combat.has_method("heal"):
					combat.heal(_item_data.get("effect_amount", 0.0))
		"restore_mana":
			# Implementar cuando haya sistema de maná
			pass
	
	# Añadir oro si es moneda
	if _item_data.type == "currency":
		if GameSettings.has_method("add_gold"):
			GameSettings.add_gold(_item_data.value * amount)


func _on_pickup_success() -> void:
	# Desactivar colisiones
	_collision.disabled = true
	
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_mesh, "scale", Vector3(1.5, 1.5, 1.5), 0.3)
	tween.tween_property(self, "position:y", position.y + 1.0, 0.3)
	# MeshInstance3D no tiene modulate (solo CanvasItem): alpha vía material.
	var sm := _mesh.get_surface_override_material(0) as StandardMaterial3D
	if sm:
		var fade_mat := sm.duplicate() as StandardMaterial3D
		fade_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_mesh.set_surface_override_material(0, fade_mat)
		var bc: Color = fade_mat.albedo_color
		tween.tween_method(
			func(a: float) -> void:
				fade_mat.albedo_color = Color(bc.r, bc.g, bc.b, a),
			bc.a,
			0.0,
			0.3
		)
	await tween.finished
	queue_free()
	print("Item recogido: ", _item_data.name, " x", amount)


func get_item_data() -> Dictionary:
	return _item_data.duplicate()


func set_item_data(data: Dictionary) -> void:
	_item_data = data.duplicate()
	
	# Actualizar visuals si ya está listo
	if is_inside_tree():
		_setup_visuals()


# API para spawnear items
static func spawn_item(world: Node3D, world_pos: Vector3, p_item_id: String, p_amount: int = 1) -> ItemDrop:
	var item_scene := load("res://scenes/gameplay/item_drop.tscn") as PackedScene
	if not item_scene:
		return null
	var item := item_scene.instantiate() as ItemDrop
	item.item_id = p_item_id
	item.amount = p_amount
	world.add_child(item)
	item.global_position = world_pos
	return item
