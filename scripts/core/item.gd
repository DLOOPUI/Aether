class_name Item
extends Resource

@export var name: String = ""
@export var description: String = ""
@export var icon: Texture2D
@export var max_stack: int = 1
@export var item_type: String = "consumable" # consumable, equipment, key, etc.
