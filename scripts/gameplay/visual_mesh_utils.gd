extends Object
class_name VisualMeshUtils
## Utilidades para localizar mallas importadas (GLB/FBX) y efectos de tinte sin mutar materiales compartidos.


static func ensure_node3d_visible_recursive(root: Node) -> void:
	if root is Node3D:
		(root as Node3D).visible = true
	for c in root.get_children():
		ensure_node3d_visible_recursive(c)


static func find_first_mesh_instance(root: Node) -> MeshInstance3D:
	if root == null:
		return null
	var direct := root.get_node_or_null("MeshInstance3D") as MeshInstance3D
	if direct:
		return direct
	var list := root.find_children("*", "MeshInstance3D", true, false)
	if list.is_empty():
		return null
	return list[0] as MeshInstance3D


static func flash_mesh_albedo(root: Node, hit_color: Color, duration_sec: float) -> void:
	var mesh := find_first_mesh_instance(root)
	if mesh == null or mesh.mesh == null:
		return
	if mesh.mesh.get_surface_count() < 1:
		return
	var active := mesh.get_active_material(0)
	if active == null or not (active is StandardMaterial3D):
		return
	var mat := active.duplicate() as StandardMaterial3D
	mesh.set_surface_override_material(0, mat)
	var original_color := mat.albedo_color
	mat.albedo_color = hit_color
	var tree := root.get_tree()
	if tree == null:
		return
	var t := tree.create_timer(duration_sec)
	t.timeout.connect(
		func():
			if is_instance_valid(mesh) and is_instance_valid(mat):
				mat.albedo_color = original_color
	)


static func duplicate_surface0_as_override(mesh: MeshInstance3D) -> StandardMaterial3D:
	if mesh == null or mesh.mesh == null or mesh.mesh.get_surface_count() < 1:
		return null
	var active := mesh.get_active_material(0)
	if active == null or not (active is StandardMaterial3D):
		return null
	var mat := active.duplicate() as StandardMaterial3D
	mesh.set_surface_override_material(0, mat)
	return mat
