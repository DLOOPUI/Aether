extends CharacterBody3D

@export var move_speed: float = 6.0
@export var jump_velocity: float = 20.0
@export var mouse_sensitivity: float = 0.0022
@export var min_pitch_rad: float = deg_to_rad(-50.0)
@export var max_pitch_rad: float = deg_to_rad(35.0)

@onready var _spring_arm: SpringArm3D = $SpringArm3D
@onready var animation_player_camera: AnimationPlayer = $AnimationPlayer_Camera

var _pitch: float = deg_to_rad(-12.0)

@onready var character = [
	$knight,
	$barbarian,
	$mage,
	$ranger,
	$rogue,
	$roguehooded
]

@onready var animations = [
	$knight_player,
	$barbarian_player,
	$mage_player,
	$ranger_player,
	$rogue_player,
	$roguehooded_player
]

@onready var my = 2

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_spring_arm.rotation.x = _pitch
	mouse_sensitivity *= GameSettings.mouse_sensitivity_multiplier
	visible()

func visible():
	var members = get_tree().get_nodes_in_group("Characters")
	var select = character[my]
	
	print(my)
	
	for i in members:
		
		if i == select:
			i.visible = true
		else:
			i.visible = false


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		_pitch -= event.relative.y * mouse_sensitivity
		_pitch = clampf(_pitch, min_pitch_rad, max_pitch_rad)
		_spring_arm.rotation.x = _pitch


func _physics_process(delta: float) -> void:
	var gravity: float = float(ProjectSettings.get_setting("physics/3d/default_gravity"))
	if not is_on_floor():
		velocity.y += -gravity * 5.5 * delta

	if Input.is_physical_key_pressed(KEY_SPACE) and is_on_floor():
		velocity.y = jump_velocity
	
	if Input.is_action_just_pressed("run") and is_on_floor():
		move_speed = move_speed * 3
		animation_player_camera.play("run")
	elif Input.is_action_just_released("run"):
		move_speed = 6.0
		animation_player_camera.play("run_reverse")
	
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
	
	if Input.is_action_pressed("movement"):
		
		var nodo = animations[my]
		nodo.play("Running_B", 0.3)
	
	if not Input.is_anything_pressed():
		
		var nodo = animations[my]
		
		nodo.play("Idle_A", 1.0)
	
	move_and_slide()
	
	
	
	
	
