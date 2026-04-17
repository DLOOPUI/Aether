extends CharacterBody3D

@export var move_speed: float = 6.0
@export var jump_velocity: float = 5.5
@export var mouse_sensitivity: float = 0.0022
@export var min_pitch_rad: float = deg_to_rad(-50.0)
@export var max_pitch_rad: float = deg_to_rad(35.0)
## Modelo visible en la escena `player.tscn` (David): 0 caballero … 5 pícaro capucha
@export var active_character_index: int = 0

@onready var _spring_arm: SpringArm3D = $SpringArm3D

var _pitch: float = deg_to_rad(-12.0)
var _base_move_speed: float = 6.0

var _animation_player_camera: AnimationPlayer = null
var _character_nodes: Array[Node3D] = []
var _animation_players: Array[AnimationPlayer] = []
var _has_embedded_heroes: bool = false
var _was_sprinting: bool = false


func _ready() -> void:
	_base_move_speed = move_speed
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_spring_arm.rotation.x = _pitch
	mouse_sensitivity *= GameSettings.mouse_sensitivity_multiplier
	if has_node("AnimationPlayer_Camera"):
		_animation_player_camera = $AnimationPlayer_Camera
	_setup_embedded_heroes()


func _setup_embedded_heroes() -> void:
	if not has_node("knight"):
		_has_embedded_heroes = false
		if has_node("Visual"):
			VisualMeshUtils.ensure_node3d_visible_recursive($Visual)
		return
	_has_embedded_heroes = true
	_character_nodes = [$knight, $barbarian, $mage, $ranger, $rogue, $roguehooded]
	_animation_players = [
		$knight_player,
		$barbarian_player,
		$mage_player,
		$ranger_player,
		$rogue_player,
		$roguehooded_player
	]
	_apply_character_visibility()


func _apply_character_visibility() -> void:
	if not _has_embedded_heroes:
		return
	var idx := clampi(active_character_index, 0, _character_nodes.size() - 1)
	var select: Node3D = _character_nodes[idx]
	var members := get_tree().get_nodes_in_group("Characters")
	for i in members:
		if i is Node3D:
			(i as Node3D).visible = i == select


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


func _wants_sprint() -> bool:
	if InputMap.has_action("run"):
		return Input.is_action_pressed("run")
	return Input.is_physical_key_pressed(KEY_SHIFT)


func _physics_process(delta: float) -> void:
	var gravity: float = float(ProjectSettings.get_setting("physics/3d/default_gravity"))
	if not is_on_floor():
		if _has_embedded_heroes:
			velocity.y += -gravity * 5.5 * delta
		else:
			velocity.y -= gravity * delta

	if Input.is_physical_key_pressed(KEY_SPACE) and is_on_floor():
		velocity.y = jump_velocity

	var sprinting := _wants_sprint() and is_on_floor()
	if sprinting:
		move_speed = _base_move_speed * 3.0
	else:
		move_speed = _base_move_speed
	if _animation_player_camera and sprinting != _was_sprinting:
		if sprinting:
			_animation_player_camera.play(&"run")
		else:
			_animation_player_camera.play(&"run_reverse")
	_was_sprinting = sprinting

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

	if _has_embedded_heroes and active_character_index >= 0 and active_character_index < _animation_players.size():
		var anim: AnimationPlayer = _animation_players[active_character_index]
		var moving := dir.length_squared() > 0.0001
		if moving:
			if anim.has_animation(&"Running_B"):
				anim.play(&"Running_B", 0.3)
		else:
			if anim.has_animation(&"Idle_A"):
				anim.play(&"Idle_A", 0.15)
