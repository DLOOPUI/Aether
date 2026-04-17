extends Area3D
## Proyectil simple: Area3D que avanza y aplica daño al jugador (RigidBody3D no expone body_entered).

var velocity: Vector3 = Vector3.ZERO
var damage: float = 10.0
var source: Node = null


func setup(p_velocity: Vector3, p_damage: float, p_source: Node) -> void:
	velocity = p_velocity
	damage = p_damage
	source = p_source


func _ready() -> void:
	monitoring = true
	monitorable = false
	collision_layer = 0
	collision_mask = 2
	body_entered.connect(_on_body_entered)
	var mesh := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.2
	mesh.mesh = sm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.8, 0.8, 0.2)
	mesh.set_surface_override_material(0, mat)
	add_child(mesh)
	var col := CollisionShape3D.new()
	var ss := SphereShape3D.new()
	ss.radius = 0.3
	col.shape = ss
	add_child(col)
	var t := Timer.new()
	t.wait_time = 3.0
	t.one_shot = true
	t.timeout.connect(queue_free)
	add_child(t)
	t.start()


func _physics_process(delta: float) -> void:
	global_position += velocity * delta


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage, source)
		queue_free()
