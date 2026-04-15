extends CanvasLayer
## Lista de misiones activas; se actualiza con señales de QuestManager.

@onready var _list: VBoxContainer = $Panel/Margin/VBox/Scroll/List
@onready var _gold_label: Label = $Panel/Margin/VBox/Header/GoldLabel


func _ready() -> void:
	layer = 35
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	QuestManager.quest_added.connect(_on_quest_changed)
	QuestManager.quest_updated.connect(_on_quest_changed)
	QuestManager.quest_completed.connect(_on_quest_changed)
	GameSettings.gold_changed.connect(_on_gold_changed)
	_on_gold_changed(GameSettings.gold)
	_rebuild()


func _on_quest_changed(_quest: Quest) -> void:
	_rebuild()


func _on_gold_changed(amount: int) -> void:
	if _gold_label:
		_gold_label.text = "Oro: %d" % amount


func _rebuild() -> void:
	for c in _list.get_children():
		c.queue_free()
	for q in QuestManager.active_quests:
		_list.add_child(_make_quest_row(q))
	if QuestManager.active_quests.is_empty():
		var empty := Label.new()
		empty.text = "No hay misiones activas."
		empty.add_theme_color_override(&"font_color", Color(0.65, 0.78, 0.92, 1.0))
		_list.add_child(empty)


func _make_quest_row(q: Quest) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 4)
	var title := Label.new()
	title.text = q.title
	title.add_theme_color_override(&"font_color", Color(0.92, 0.97, 1.0, 1.0))
	title.add_theme_font_size_override(&"font_size", 16)
	box.add_child(title)
	var desc := Label.new()
	desc.text = q.description
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_color_override(&"font_color", Color(0.7, 0.85, 0.98, 1.0))
	desc.add_theme_font_size_override(&"font_size", 12)
	box.add_child(desc)
	var prog := Label.new()
	prog.text = "Objetivo: %s  (%s)" % [q.current_objective_label(), q.progress_text()]
	prog.add_theme_color_override(&"font_color", Color(0.55, 0.88, 1.0, 1.0))
	prog.add_theme_font_size_override(&"font_size", 11)
	box.add_child(prog)
	return box
