extends PanelContainer

@onready var icon_rect: TextureRect = $Icon
@onready var label: Label = $Label

func set_item(item: Item) -> void:
	if item:
		icon_rect.texture = item.icon
		label.text = item.name
		label.visible = false # Hide by default, show on hover
	else:
		icon_rect.texture = null
		label.text = ""
		label.visible = false

func _on_mouse_entered() -> void:
	# Simple tooltip simulation
	if label.text != "":
		label.visible = true

func _on_mouse_exited() -> void:
	label.visible = false
