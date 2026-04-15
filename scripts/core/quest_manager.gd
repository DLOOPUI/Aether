extends Node
## Autoload: misiones activas, completadas y recompensas. Emite señales para UI y gameplay.
## Plantillas por id para `add_quest_by_template_id` (diálogos, NPCs).

signal quest_added(quest: Quest)
signal quest_updated(quest: Quest)
signal quest_completed(quest: Quest)
signal item_reward_granted(item_id: String)

var active_quests: Array[Quest] = []
var completed_quests: Array[Quest] = []
## Cola simple hasta que exista inventario; consumir con `take_pending_item_rewards()`.
var pending_item_rewards: Array[String] = []

var _quest_templates: Dictionary = {}
var _quest_log: CanvasLayer

const REGISTER_SAMPLE_QUESTS := true


func _ready() -> void:
	_quest_log = preload("res://scenes/ui/quest_log.tscn").instantiate()
	get_tree().root.add_child(_quest_log)
	_quest_log.hide()
	_register_quest_templates()
	if REGISTER_SAMPLE_QUESTS:
		add_quest_by_template_id("tutorial_plaza")
		add_quest_by_template_id("slime_hunt")


func toggle_quest_log() -> void:
	if _quest_log:
		_quest_log.visible = not _quest_log.visible


func is_quest_log_open() -> bool:
	return _quest_log != null and _quest_log.visible


func register_quest_template(quest: Quest) -> void:
	if quest.id.is_empty():
		push_warning("Plantilla de misión sin id.")
		return
	_quest_templates[quest.id] = quest


## Duplica la plantilla y la añade como misión activa (estado reiniciado).
func add_quest_by_template_id(template_id: String) -> bool:
	if not _quest_templates.has(template_id):
		push_warning("Plantilla de misión no encontrada: %s" % template_id)
		return false
	var base: Quest = _quest_templates[template_id] as Quest
	var q: Quest = base.duplicate(true) as Quest
	add_quest(q)
	return true


func add_quest(quest: Quest) -> void:
	if quest.id.is_empty():
		push_warning("Quest sin id; no se añade.")
		return
	for aq in active_quests:
		if aq.id == quest.id:
			push_warning("Ya existe misión activa con id: %s" % quest.id)
			return
	for cq in completed_quests:
		if cq.id == quest.id:
			push_warning("Misión ya completada: %s" % quest.id)
			return
	quest.start()
	active_quests.append(quest)
	quest_added.emit(quest)


func update_quest_progress(quest_id: String) -> void:
	for i in range(active_quests.size()):
		var quest: Quest = active_quests[i]
		if quest.id != quest_id:
			continue
		if quest.complete_objective():
			quest_completed.emit(quest)
			active_quests.remove_at(i)
			completed_quests.append(quest)
			_give_rewards(quest)
		else:
			quest_updated.emit(quest)
		return


func get_quest_by_id(quest_id: String) -> Quest:
	for q in active_quests:
		if q.id == quest_id:
			return q
	for q in completed_quests:
		if q.id == quest_id:
			return q
	return null


func take_pending_item_rewards() -> Array[String]:
	var out: Array[String] = pending_item_rewards.duplicate()
	pending_item_rewards.clear()
	return out


func _give_rewards(quest: Quest) -> void:
	if quest.rewards.is_empty():
		return
	if quest.rewards.has("gold"):
		GameSettings.add_gold(int(quest.rewards["gold"]))
	if quest.rewards.has("items"):
		var items: Variant = quest.rewards["items"]
		if items is Array:
			for it in items:
				var sid: String = str(it)
				pending_item_rewards.append(sid)
				item_reward_granted.emit(sid)


func _register_quest_templates() -> void:
	var q1 := Quest.new()
	q1.id = "tutorial_plaza"
	q1.title = "Bienvenida"
	q1.description = "Explora el prototipo y habla con el NPC en la plaza (placeholder)."
	q1.objectives = ["Encuentra la plaza", "Habla con el NPC"]
	q1.rewards = {"gold": 25}

	var q2 := Quest.new()
	q2.id = "collect_apples"
	q2.title = "Manzanera"
	q2.description = "Recoge manzanas del suelo cuando exista el sistema de recolección."
	q2.objectives = ["Manzana 1/3", "Manzana 2/3", "Manzana 3/3"]
	q2.rewards = {"gold": 50, "items": ["apple_badge"]}

	var q3 := Quest.new()
	q3.id = "slime_hunt"
	q3.title = "Prueba de combate"
	q3.description = "Derrota enemigos cuando el combate esté implementado."
	q3.objectives = ["Enemigo 1/5", "Enemigo 2/5", "Enemigo 3/5", "Enemigo 4/5", "Enemigo 5/5"]
	q3.rewards = {"gold": 120}

	register_quest_template(q1)
	register_quest_template(q2)
	register_quest_template(q3)
