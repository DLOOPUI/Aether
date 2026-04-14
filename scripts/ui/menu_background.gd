extends TextureRect

## Carga `menu_background.png` / `.jpg` si existen; si no, genera un cielo tipo atardecer (sin asset binario).

const PATHS: PackedStringArray = [
	"res://assets/ui/menu_background.png",
	"res://assets/ui/menu_background.jpg",
]


func _ready() -> void:
	for p in PATHS:
		if ResourceLoader.exists(p):
			var t := load(p) as Texture2D
			if t:
				texture = t
				visible = true
				return
	_apply_procedural_sky()
	visible = true


func _apply_procedural_sky() -> void:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.42, 1.0])
	g.colors = PackedColorArray([
		Color(0.05, 0.07, 0.14),
		Color(0.18, 0.32, 0.52),
		Color(0.92, 0.48, 0.28),
	])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.width = 1920
	gt.height = 1080
	gt.fill_from = Vector2(0.5, 0.0)
	gt.fill_to = Vector2(0.5, 1.0)
	texture = gt
