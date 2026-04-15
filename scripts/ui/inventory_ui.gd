extends CanvasLayer

@onready var grid_container: GridContainer = $Panel/Margin/GridContainer
@onready var close_button: Button = $Panel/Header/CloseButton

var inventory: Inventory
var slot_scene = preload("res://scenes/ui/inventory_slot.tscn")

func _ready() -> void:
	close_button.pressed.connect(hide_inventory)
	
	# Load player inventory from global settings
	inventory = GameSettings.get_player_inventory()
	if inventory:
		inventory.inventory_changed.connect(_refresh_inventory)
	
	_refresh_inventory()
	hide_inventory()

func _refresh_inventory() -> void:
	# Clear existing slots
	for child in grid_container.get_children():
		child.queue_free()

	# Create slots for each item capacity
	for i in range(inventory.max_size):
		var slot = slot_scene.instantiate()
		grid_container.add_child(slot)

		if i < inventory.items.size():
			var item = inventory.items[i]
			slot.set_item(item)

func show_inventory() -> void:
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# get_tree().paused = true # Optional: pause game

func hide_inventory() -> void:
	visible = false
	# Input.mouse_mode = Input.MOUSE_MODE_CAPTURED # Only if in-game
	# get_tree().paused = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and visible:
		hide_inventory()
