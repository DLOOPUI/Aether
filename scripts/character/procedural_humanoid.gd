extends Node3D
class_name ProceduralHumanoid
## Cuerpo procedural con primitivas (cápsulas/esfera). Aplica `CharacterDraft` sin assets externos.

const SKIN_INDEX := 0
const HAIR_INDEX := 1
const CLOTH_INDEX := 2

var _torso: MeshInstance3D
var _head: MeshInstance3D
var _hair: MeshInstance3D
var _arm_lu: MeshInstance3D
var _arm_ll: MeshInstance3D
var _arm_ru: MeshInstance3D
var _arm_rl: MeshInstance3D
var _leg_lu: MeshInstance3D
var _leg_ll: MeshInstance3D
var _leg_ru: MeshInstance3D
var _leg_rl: MeshInstance3D


func _ready() -> void:
	_build_mesh_graph()


func _mat_for(kind: int) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.roughness = 0.65
	match kind:
		SKIN_INDEX:
			m.albedo_color = Color(0.85, 0.7, 0.62)
		HAIR_INDEX:
			m.albedo_color = Color(0.12, 0.08, 0.06)
		CLOTH_INDEX:
			m.albedo_color = Color(0.35, 0.38, 0.45)
	return m


func _add_capsule(
	parent: Node3D, radius: float, height: float, pos: Vector3, rot_deg: Vector3, mat_kind: int
) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = radius
	cap.height = height
	mi.mesh = cap
	mi.position = pos
	mi.rotation_degrees = rot_deg
	mi.material_override = _mat_for(mat_kind)
	parent.add_child(mi)
	return mi


func _add_sphere(parent: Node3D, radius: float, pos: Vector3, mat_kind: int) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sp := SphereMesh.new()
	sp.radius = radius
	sp.height = radius * 2.0
	mi.mesh = sp
	mi.position = pos
	mi.material_override = _mat_for(mat_kind)
	parent.add_child(mi)
	return mi


func _build_mesh_graph() -> void:
	var y0 := 0.0
	_torso = _add_capsule(self, 0.22, 0.52, Vector3(0, 0.95 + y0, 0), Vector3.ZERO, SKIN_INDEX)

	_head = _add_sphere(self, 0.13, Vector3(0, 1.48 + y0, 0), SKIN_INDEX)
	_hair = _add_sphere(_head, 0.12, Vector3(0, 0.05, 0), HAIR_INDEX)

	var sh_y := 1.25 + y0
	_arm_lu = _add_capsule(self, 0.07, 0.28, Vector3(-0.32, sh_y, 0), Vector3(0, 0, 90), SKIN_INDEX)
	_arm_ll = _add_capsule(self, 0.06, 0.26, Vector3(-0.52, sh_y - 0.22, 0), Vector3(0, 0, 90), SKIN_INDEX)
	_arm_ru = _add_capsule(self, 0.07, 0.28, Vector3(0.32, sh_y, 0), Vector3(0, 0, -90), SKIN_INDEX)
	_arm_rl = _add_capsule(self, 0.06, 0.26, Vector3(0.52, sh_y - 0.22, 0), Vector3(0, 0, -90), SKIN_INDEX)

	var hip_y := 0.78 + y0
	_leg_lu = _add_capsule(self, 0.1, 0.4, Vector3(-0.12, hip_y, 0), Vector3.ZERO, CLOTH_INDEX)
	_leg_ll = _add_capsule(self, 0.08, 0.38, Vector3(-0.12, hip_y - 0.42, 0), Vector3.ZERO, SKIN_INDEX)
	_leg_ru = _add_capsule(self, 0.1, 0.4, Vector3(0.12, hip_y, 0), Vector3.ZERO, CLOTH_INDEX)
	_leg_rl = _add_capsule(self, 0.08, 0.38, Vector3(0.12, hip_y - 0.42, 0), Vector3.ZERO, SKIN_INDEX)


static func _skin_color(tone: float) -> Color:
	var t := clampf(tone, 0.0, 1.0)
	return Color(lerpf(0.96, 0.38, t), lerpf(0.82, 0.28, t), lerpf(0.72, 0.22, t))


static func _hair_color(tone: float) -> Color:
	var t := clampf(tone, 0.0, 1.0)
	return Color(lerpf(0.05, 0.45, t), lerpf(0.04, 0.32, t), lerpf(0.03, 0.18, t)).darkened(lerpf(0.0, 0.25, t))


func apply_draft(d: CharacterDraft) -> void:
	var h: float = lerpf(0.88, 1.12, clampf(d.height_01, 0.0, 1.0))
	var b: float = lerpf(0.82, 1.18, clampf(d.build_01, 0.0, 1.0))
	var head_m: float = lerpf(0.88, 1.12, clampf(d.head_size_01, 0.0, 1.0))
	var arm_m: float = lerpf(0.9, 1.15, clampf(d.arm_length_01, 0.0, 1.0))
	var leg_m: float = lerpf(0.9, 1.12, clampf(d.leg_length_01, 0.0, 1.0))

	scale = Vector3(h, h, h)

	var skin := _skin_color(d.skin_tone_01)
	var hair := _hair_color(d.hair_tone_01)

	_torso.scale = Vector3(b, 1.0, b)
	_head.scale = Vector3(head_m, head_m, head_m)
	_hair.scale = Vector3(head_m, head_m, head_m)

	_set_mat_albedo(_torso, skin)
	_set_mat_albedo(_head, skin)
	_set_mat_albedo(_hair, hair)
	_set_mat_albedo(_arm_lu, skin)
	_set_mat_albedo(_arm_ll, skin)
	_set_mat_albedo(_arm_ru, skin)
	_set_mat_albedo(_arm_rl, skin)
	_set_mat_albedo(_leg_lu, _cloth_from_ids(d))
	_set_mat_albedo(_leg_ru, _cloth_from_ids(d))
	_set_mat_albedo(_leg_ll, skin)
	_set_mat_albedo(_leg_rl, skin)

	_arm_lu.scale = Vector3(arm_m, arm_m, arm_m)
	_arm_ll.scale = Vector3(arm_m, arm_m, arm_m)
	_arm_ru.scale = Vector3(arm_m, arm_m, arm_m)
	_arm_rl.scale = Vector3(arm_m, arm_m, arm_m)

	_leg_lu.scale = Vector3(leg_m, leg_m, leg_m)
	_leg_ll.scale = Vector3(leg_m, leg_m, leg_m)
	_leg_ru.scale = Vector3(leg_m, leg_m, leg_m)
	_leg_rl.scale = Vector3(leg_m, leg_m, leg_m)


func _set_mat_albedo(mi: MeshInstance3D, col: Color) -> void:
	var m := mi.material_override as StandardMaterial3D
	if m:
		m.albedo_color = col


func _cloth_from_ids(d: CharacterDraft) -> Color:
	var base := Color.from_hsv(fmod(0.52 + float(d.pants_id) * 0.06, 1.0), 0.25, 0.42)
	return base.lerp(Color(0.48, 0.34, 0.26), clampf(float(d.top_id) * 0.05, 0.0, 1.0))
