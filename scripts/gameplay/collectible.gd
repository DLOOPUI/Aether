extends Area3D
class_name Collectible

@export var item_data: Item

func _ready() -> void:
	# Ensure we have an item to collect
	if not item_data:
		push_warning("Collectible created without item_data!")
		# Default to apple if empty for testing
		item_data = Apple.new()

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		# Add to inventory
		var inv = GameSettings.get_player_inventory()
		if inv.add_item(item_data):
			print("Recogido: ", item_data.name)
			queue_free()
		else:
			print("Inventario lleno")
