extends CharacterBody3D

@export var move_speed: float = 6.0
@export var jump_velocity: float = 5.5
@export var mouse_sensitivity: float = 0.0022
@export var min_pitch_rad: float = deg_to_rad(-50.0)
@export var max_pitch_rad: float = deg_to_rad(35.0)

@onready var _spring_arm: SpringArm3D = $SpringArm3D

var _pitch: float = deg_to_rad(-12.0)


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_spring_arm.rotation.x = _pitch
	mouse_sensitivity *= GameSettings.mouse_sensitivity_multiplier


func take_damage(amount: float, source: Node = null) -> bool:
	var combat := get_node_or_null("PlayerCombat")
	if combat and combat.has_method("take_damage"):
		return combat.take_damage(amount, source)
	return false


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		_pitch -= event.relative.y * mouse_sensitivity
		_pitch = clampf(_pitch, min_pitch_rad, max_pitch_rad)
		_spring_arm.rotation.x = _pitch


func _physics_process(delta: float) -> void:
	var gravity: float = float(ProjectSettings.get_setting("physics/3d/default_gravity"))
	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_physical_key_pressed(KEY_SPACE) and is_on_floor():
		velocity.y = jump_velocity

	var cam_basis: Basis = _spring_arm.global_transform.basis
	var forward: Vector3 = -cam_basis.z
	forward.y = 0.0
	if forward.length_squared() > 0.0001:
		forward = forward.normalized()
	var right: Vector3 = cam_basis.x
	right.y = 0.0
	if right.length_squared() > 0.0001:
		right = right.normalized()

	var ix: float = float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A))
	var iz: float = float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))
	var dir: Vector3 = forward * -iz + right * ix
	if dir.length_squared() > 0.0001:
		dir = dir.normalized() * move_speed
		velocity.x = dir.x
		velocity.z = dir.z
	else:
		velocity.x = move_toward(velocity.x, 0.0, move_speed * 2.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, move_speed * 2.0 * delta)

	move_and_slide()
