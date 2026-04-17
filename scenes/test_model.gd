extends Node3D

func _ready() -> void:
	print("=== TEST MODEL SCENE ===")
	print("Attempting to load character model...")
	
	var model_path = "res://assets/models/animations/characters.fbx"
	print("Model path: ", model_path)
	
	if FileAccess.file_exists(model_path):
		print("✓ File exists")
		var scene = load(model_path)
		if scene:
			print("✓ Scene loaded successfully")
			var character = scene.instantiate()
			$Character.add_child(character)
			print("✓ Character instantiated and added to scene")
			print("Character class: ", character.get_class())
			print("Character children: ", character.get_child_count())
			
			# Try different scales
			if character is Node3D:
				character.scale = Vector3(0.01, 0.01, 0.01)
				character.position = Vector3(0, 0, 0)
				print("✓ Transformations applied")
				print("Scale: ", character.scale)
				print("Position: ", character.position)
				
				# List all meshes
				var meshes = character.find_children("*", "MeshInstance3D", true)
				print("Found ", meshes.size(), " mesh(es)")
				for i in meshes.size():
					var mesh = meshes[i] as MeshInstance3D
					print("  Mesh ", i, ": ", mesh.name)
		else:
			print("✗ Failed to load scene")
	else:
		print("✗ File does not exist: ", model_path)
	
	print("=== TEST COMPLETE ===")

func _process(delta: float) -> void:
	# Rotate character slowly
	$Character.rotate_y(delta * 0.5)
