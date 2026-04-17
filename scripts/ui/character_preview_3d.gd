extends SubViewportContainer

@onready var viewport: SubViewport = $SubViewport
@onready var camera: Camera3D = $SubViewport/Camera3D
@onready var character_root: Node3D = $SubViewport/CharacterRoot

var current_character: Node3D = null
var rotation_speed: float = 0.01
var zoom_speed: float = 0.5

func _ready() -> void:
	# Configure viewport for always updating
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	
	# Try to load a base model, otherwise use placeholder
	load_character("res://assets/models/animations/characters.fbx")
	
	# Initial sync with current draft
	update_preview()

func load_character(path: String) -> void:
	# Clear previous character
	if current_character:
		current_character.queue_free()
	
	print("Attempting to load character from: ", path)
	
	# Try to load the 3D model (FBX/GLB/GLTF)
	if FileAccess.file_exists(path):
		print("File exists: ", path)
		var scene = load(path)
		if scene:
			print("Scene loaded successfully, instantiating...")
			current_character = scene.instantiate()
			character_root.add_child(current_character)
			print("Character model loaded and added to scene: ", path)
			print("Character node type: ", current_character.get_class())
			print("Character children: ", current_character.get_child_count())
			
			# Scale and position the character appropriately
			if current_character is Node3D:
				print("Character is Node3D, applying transformations...")
				current_character.scale = Vector3(0.01, 0.01, 0.01)  # FBX often needs scaling
				current_character.position = Vector3(0, -1, 0)  # Adjust height
				print("Character scale: ", current_character.scale)
				print("Character position: ", current_character.position)
		else:
			print("ERROR: Failed to load scene from: ", path)
	else:
		print("ERROR: File does not exist: ", path)
		# Fallback: Create a placeholder character (Capsule)
		var mesh_instance = MeshInstance3D.new()
		mesh_instance.mesh = CapsuleMesh.new()
		current_character = Node3D.new()
		current_character.add_child(mesh_instance)
		character_root.add_child(current_character)
		print("Warning: Character model not found, using placeholder.")

	update_preview()

func update_preview() -> void:
	var draft = CharacterStorage.load_draft()
	if not draft:
		return
		
	apply_character_customizations(draft)

func apply_character_customizations(draft: CharacterDraft) -> void:
	if not current_character:
		return
		
	# Placeholder implementation for customisations
	# In a real scenario, we would:
	# 1. Change meshes based on draft.top_id, draft.pants_id, etc.
	# 2. Scale bones or the whole mesh based on height_01, build_01, etc.
	# 3. Change material colors based on skin_tone_01 and hair_tone_01.
	
	# For the MVP placeholder, we can modulate the root color to show it's working
	var material = StandardMaterial3D.new()
	# Simple color mapping from skin_tone_01 (0.0 to 1.0)
	var color = Color(0.8, 0.6, 0.4) # Base skin tone
	color.v = lerp(0.5, 1.0, draft.skin_tone_01)
	material.albedo_color = color
	
	# Apply material to all meshes in the character root
	for child in current_character.find_children("*", "MeshInstance3D", true):
		var mi = child as MeshInstance3D
		mi.set_surface_override_material(0, material)

func _input(event: InputEvent) -> void:
	# Rotate character with left mouse drag
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		character_root.rotate_y(-event.relative.x * rotation_speed)
	
	# Zoom with mouse wheel
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera.position.z = clamp(camera.position.z - zoom_speed, 1.0, 5.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera.position.z = clamp(camera.position.z + zoom_speed, 1.0, 5.0)
