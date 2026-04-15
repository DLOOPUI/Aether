extends Node3D
class_name ProceduralHumanoid
## Placeholder procedural estilo “chibi” (cabezón). Sustituir por GLTF anime cuando tengáis arte.
## Orejas de elfo visibles si raza = índice 1 (Elfo).

const SKIN := 0
const HAIR := 1
const CLOTH := 2

var _torso: MeshInstance3D
var _head: MeshInstance3D
var _hair: MeshInstance3D
var _hair_side: MeshInstance3D
var _ear_l: MeshInstance3D
var _ear_r: MeshInstance3D
var _arm_lu: MeshInstance3D
var _arm_ll: MeshInstance3D
var _arm_ru: MeshInstance3D
var _arm_rl: MeshInstance3D
var _leg_lu: MeshInstance3D
var _leg_ll: MeshInstance3D
var _leg_ru: MeshInstance3D
var _leg_rl: MeshInstance3D


func _ready() -> void:
	_build_mesh_graph_chibi()


func _mat(kind: int) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.metallic = 0.0
	m.roughness = 0.42
	m.rim_enabled = true
	m.rim = 0.35
	m.rim_tint = 0.75
	match kind:
		SKIN:
			m.albedo_color = Color(0.88, 0.74, 0.66)
			m.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
			m.specular_mode = BaseMaterial3D.SPECULAR_TOON
			m.roughness = 0.48
			m.subsurface_scattering_enabled = true
			m.subsurface_scattering_strength = 0.45
		HAIR:
			m.albedo_color = Color(0.14, 0.1, 0.08)
			m.roughness = 0.55
			m.rim = 0.5
		CLOTH:
			m.albedo_color = Color(0.38, 0.42, 0.52)
			m.roughness = 0.62
	return m


func _caps(
	parent: Node3D, radius: float, height: float, pos: Vector3, rot_deg: Vector3, kind: int
) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = radius
	cap.height = height
	mi.mesh = cap
	mi.position = pos
	mi.rotation_degrees = rot_deg
	mi.material_override = _mat(kind)
	parent.add_child(mi)
	return mi


func _sph(parent: Node3D, radius: float, pos: Vector3, kind: int) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sp := SphereMesh.new()
	sp.radius = radius
	sp.height = radius * 2.0
	sp.radial_segments = 20
	sp.rings = 12
	mi.mesh = sp
	mi.position = pos
	mi.material_override = _mat(kind)
	parent.add_child(mi)
	return mi


func _build_mesh_graph_chibi() -> void:
	# Proporciones chibi: cabeza grande, torso corto, extremidades cortas.
	_torso = _caps(self, 0.14, 0.34, Vector3(0, 0.62, 0), Vector3.ZERO, SKIN)

	_head = _sph(self, 0.21, Vector3(0, 1.02, 0), SKIN)
	_hair = _sph(_head, 0.19, Vector3(0, 0.1, 0), HAIR)
	_hair_side = _sph(_head, 0.14, Vector3(0, 0.02, -0.12), HAIR)

	_ear_l = _sph(_head, 0.045, Vector3(-0.2, 0.02, 0.02), SKIN)
	_ear_r = _sph(_head, 0.045, Vector3(0.2, 0.02, 0.02), SKIN)
	_ear_l.scale = Vector3(0.55, 1.15, 0.45)
	_ear_r.scale = Vector3(0.55, 1.15, 0.45)
	_ear_l.visible = false
	_ear_r.visible = false

	var sh_y := 0.88
	_arm_lu = _caps(self, 0.055, 0.2, Vector3(-0.26, sh_y, 0), Vector3(0, 0, 90), SKIN)
	_arm_ll = _caps(self, 0.048, 0.16, Vector3(-0.4, sh_y - 0.16, 0), Vector3(0, 0, 90), SKIN)
	_arm_ru = _caps(self, 0.055, 0.2, Vector3(0.26, sh_y, 0), Vector3(0, 0, -90), SKIN)
	_arm_rl = _caps(self, 0.048, 0.16, Vector3(0.4, sh_y - 0.16, 0), Vector3(0, 0, -90), SKIN)

	var hip_y := 0.48
	_leg_lu = _caps(self, 0.075, 0.26, Vector3(-0.09, hip_y, 0), Vector3.ZERO, CLOTH)
	_leg_ll = _caps(self, 0.06, 0.22, Vector3(-0.09, hip_y - 0.28, 0), Vector3.ZERO, SKIN)
	_leg_ru = _caps(self, 0.075, 0.26, Vector3(0.09, hip_y, 0), Vector3.ZERO, CLOTH)
	_leg_rl = _caps(self, 0.06, 0.22, Vector3(0.09, hip_y - 0.28, 0), Vector3.ZERO, SKIN)


static func _skin_color(tone: float) -> Color:
	var t := clampf(tone, 0.0, 1.0)
	return Color(lerpf(0.96, 0.38, t), lerpf(0.82, 0.28, t), lerpf(0.72, 0.22, t))


static func _hair_color(tone: float) -> Color:
	var t := clampf(tone, 0.0, 1.0)
	return Color(lerpf(0.05, 0.55, t), lerpf(0.04, 0.38, t), lerpf(0.03, 0.22, t)).darkened(
		lerpf(0.0, 0.2, t)
	)


func apply_draft(d: CharacterDraft) -> void:
	var h: float = lerpf(0.9, 1.1, clampf(d.height_01, 0.0, 1.0))
	var b: float = lerpf(0.78, 1.2, clampf(d.build_01, 0.0, 1.0))
	var head_m: float = lerpf(0.92, 1.14, clampf(d.head_size_01, 0.0, 1.0))
	var arm_m: float = lerpf(0.88, 1.12, clampf(d.arm_length_01, 0.0, 1.0))
	var leg_m: float = lerpf(0.88, 1.1, clampf(d.leg_length_01, 0.0, 1.0))

	scale = Vector3(h, h, h)

	var skin := _skin_color(d.skin_tone_01)
	var hair := _hair_color(d.hair_tone_01)

	_torso.scale = Vector3(b, 1.0, b)
	_head.scale = Vector3(head_m, head_m, head_m)
	_hair.scale = Vector3(head_m, head_m, head_m)
	_hair_side.scale = Vector3(head_m, head_m, head_m)

	_set_albedo(_torso, skin)
	_set_albedo(_head, skin)
	_set_albedo(_hair, hair)
	_set_albedo(_hair_side, hair)
	_set_albedo(_arm_lu, skin)
	_set_albedo(_arm_ll, skin)
	_set_albedo(_arm_ru, skin)
	_set_albedo(_arm_rl, skin)
	_set_albedo(_leg_lu, _cloth_from_ids(d))
	_set_albedo(_leg_ru, _cloth_from_ids(d))
	_set_albedo(_leg_ll, skin)
	_set_albedo(_leg_rl, skin)
	_set_albedo(_ear_l, skin)
	_set_albedo(_ear_r, skin)

	var elf: bool = d.race_id == 1
	_ear_l.visible = elf
	_ear_r.visible = elf

	_arm_lu.scale = Vector3(arm_m, arm_m, arm_m)
	_arm_ll.scale = Vector3(arm_m, arm_m, arm_m)
	_arm_ru.scale = Vector3(arm_m, arm_m, arm_m)
	_arm_rl.scale = Vector3(arm_m, arm_m, arm_m)

	_leg_lu.scale = Vector3(leg_m, leg_m, leg_m)
	_leg_ll.scale = Vector3(leg_m, leg_m, leg_m)
	_leg_ru.scale = Vector3(leg_m, leg_m, leg_m)
	_leg_rl.scale = Vector3(leg_m, leg_m, leg_m)


func _set_albedo(mi: MeshInstance3D, col: Color) -> void:
	var m := mi.material_override as StandardMaterial3D
	if m:
		m.albedo_color = col


func _cloth_from_ids(d: CharacterDraft) -> Color:
	var base := Color.from_hsv(fmod(0.52 + float(d.pants_id) * 0.06, 1.0), 0.28, 0.48)
	return base.lerp(Color(0.48, 0.34, 0.26), clampf(float(d.top_id) * 0.05, 0.0, 1.0))
