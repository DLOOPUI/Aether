extends TextureRect

## Si existe `assets/ui/menu_background.png` (o `.jpg`), se usa como fondo a pantalla completa.

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
	visible = false
