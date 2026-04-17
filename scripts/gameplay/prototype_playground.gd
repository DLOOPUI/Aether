extends Node3D

const MAIN_MENU := &"res://scenes/ui/main_menu.tscn"
const SETTINGS_SCENE := preload("res://scenes/ui/settings.tscn")
const PLAYER_WITH_COMBAT := preload("res://scenes/gameplay/player_with_combat.tscn")
const BASIC_ENEMY := preload("res://scenes/gameplay/basic_enemy.tscn")
const RANGED_ENEMY := preload("res://scenes/gameplay/ranged_enemy.tscn")
const TANK_ENEMY := preload("res://scenes/gameplay/tank_enemy.tscn")
const FAST_ENEMY := preload("res://scenes/gameplay/fast_enemy.tscn")
const HEALTH_BAR_UI := preload("res://scenes/ui/health_bar.tscn")
const EXPERIENCE_BAR_UI := preload("res://scenes/ui/experience_bar.tscn")
const EXPERIENCE_SYSTEM := preload("res://scripts/core/experience_system.gd")

@onready var _pause: CanvasLayer = $PauseOverlay
@onready var _npc: Node3D = $NpcPlaza
@onready var _player_spawn: Marker3D = $PlayerSpawn
@onready var _enemy_spawns: Array[Marker3D] = []

var _player: Node3D = null
var _vfx_layer: CanvasLayer
var _hit_flash: ColorRect = null
var _death_overlay: CanvasLayer = null


func _ready() -> void:
	_setup_inputs()
	_vfx_layer = CanvasLayer.new()
	_vfx_layer.layer = 45
	add_child(_vfx_layer)
	_hit_flash = ColorRect.new()
	_hit_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hit_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hit_flash.color = Color(0.9, 0.12, 0.12, 0.0)
	_vfx_layer.add_child(_hit_flash)
	_setup_player()
	_setup_enemies()
	_connect_combat_feedback()
	_pause.hide_pause()
	_pause.resume_pressed.connect(_on_pause_resume)
	_pause.main_menu_pressed.connect(_on_pause_main_menu)
	_pause.settings_pressed.connect(_on_pause_settings)


func _unhandled_input(event: InputEvent) -> void:
	if event == null:
		return
	if is_instance_valid(_death_overlay):
		return
	if DialogueManager.is_dialogue_active():
		return
	if get_tree().paused:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_E:
		if _npc is InteractableNpc and (_npc as InteractableNpc).try_interact(_player.global_position):
			get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_J:
		QuestManager.toggle_quest_log()
		if QuestManager.is_quest_log_open():
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		get_viewport().set_input_as_handled()
		return
	if OS.is_debug_build() and event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_F1:
				QuestManager.update_quest_progress("tutorial_plaza")
				get_viewport().set_input_as_handled()
				return
			KEY_F2:
				QuestManager.update_quest_progress("collect_apples")
				get_viewport().set_input_as_handled()
				return
			KEY_F3:
				QuestManager.update_quest_progress("slime_hunt")
				get_viewport().set_input_as_handled()
				return
	if event.is_action_pressed(&"ui_cancel"):
		if QuestManager.is_quest_log_open():
			QuestManager.toggle_quest_log()
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			get_viewport().set_input_as_handled()
			return
		_open_pause()
		get_viewport().set_input_as_handled()
		return


func _open_pause() -> void:
	get_tree().paused = true
	_pause.show_pause()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _on_pause_resume() -> void:
	get_tree().paused = false
	_pause.hide_pause()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _on_pause_main_menu() -> void:
	get_tree().paused = false
	_pause.hide_pause()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file(MAIN_MENU)


func _on_pause_settings() -> void:
	var layer := CanvasLayer.new()
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	layer.layer = 60
	var panel: Control = SETTINGS_SCENE.instantiate()
	panel.exit_to_parent = true
	panel.close_requested.connect(_on_settings_overlay_closed.bind(layer))
	layer.add_child(panel)
	add_child(layer)


func _on_settings_overlay_closed(layer: CanvasLayer) -> void:
	layer.queue_free()
	_pause.focus_resume_button()


func _setup_inputs() -> void:
	# Configurar acción de ataque si no existe
	if not InputMap.has_action("attack"):
		InputMap.add_action("attack")
		
		# Click izquierdo
		var mouse_event = InputEventMouseButton.new()
		mouse_event.button_index = MOUSE_BUTTON_LEFT
		InputMap.action_add_event("attack", mouse_event)
		
		# Tecla F
		var key_event = InputEventKey.new()
		key_event.physical_keycode = KEY_F
		InputMap.action_add_event("attack", key_event)
		
		# Gamepad R2
		var gamepad_event = InputEventJoypadButton.new()
		gamepad_event.button_index = JOY_BUTTON_RIGHT_SHOULDER
		gamepad_event.device = -1
		InputMap.action_add_event("attack", gamepad_event)
		
		print("Acción 'attack' configurada")


func _setup_player() -> void:
	_player = PLAYER_WITH_COMBAT.instantiate()
	var spawn_xf := Transform3D(Basis.IDENTITY, Vector3(0.0, 2.5, 0.0))
	if is_instance_valid(_player_spawn):
		spawn_xf = _player_spawn.global_transform
	_player.global_transform = spawn_xf
	add_child(_player)
	_player.add_to_group("player")
	
	# Añadir sistema de experiencia al jugador
	_add_experience_system()
	
	# Añadir UIs
	_add_player_health_ui()
	_add_experience_ui()


func _setup_enemies() -> void:
	# Encontrar todos los Marker3D para spawn de enemigos
	for child in get_children():
		if child is Marker3D and child.name.begins_with("EnemySpawn"):
			_enemy_spawns.append(child)
	
	# Crear variedad de enemigos
	var enemy_types = [BASIC_ENEMY, RANGED_ENEMY, TANK_ENEMY, FAST_ENEMY]
	var enemy_names = ["Básico", "A distancia", "Tanque", "Rápido"]
	
	for i in range(4):  # Crear 4 enemigos (uno de cada tipo)
		if i < _enemy_spawns.size():
			var enemy_type = enemy_types[i % enemy_types.size()]
			var enemy_name = enemy_names[i % enemy_names.size()]
			var enemy = enemy_type.instantiate()
			enemy.global_transform = _enemy_spawns[i].global_transform
			add_child(enemy)
			print("Enemigo ", enemy_name, " creado en posición ", i)
		else:
			# Si no hay suficientes spawn points, crear en posiciones aleatorias
			var enemy_type = enemy_types[i % enemy_types.size()]
			var enemy_name = enemy_names[i % enemy_names.size()]
			var enemy = enemy_type.instantiate()
			var angle = i * TAU / 4  # Distribuir en círculo
			var radius = 8.0
			enemy.global_position = Vector3(
				sin(angle) * radius,
				1,
				cos(angle) * radius
			)
			add_child(enemy)
			print("Enemigo ", enemy_name, " creado en posición circular")


func _add_player_health_ui() -> void:
	if HEALTH_BAR_UI and _player:
		var health_bar = HEALTH_BAR_UI.instantiate()
		add_child(health_bar)
		print("UI de salud del jugador añadida")


func _add_experience_system() -> void:
	if EXPERIENCE_SYSTEM and _player:
		var exp_system = EXPERIENCE_SYSTEM.new()
		exp_system.name = "ExperienceSystem"
		_player.add_child(exp_system)
		print("Sistema de experiencia añadido al jugador")


func _add_experience_ui() -> void:
	if EXPERIENCE_BAR_UI:
		var exp_bar = EXPERIENCE_BAR_UI.instantiate()
		add_child(exp_bar)


func _connect_combat_feedback() -> void:
	if not _player.has_node("PlayerCombat"):
		return
	var pc: Node = _player.get_node("PlayerCombat")
	pc.enemy_hit.connect(_on_pc_enemy_hit)
	pc.player_took_damage.connect(_on_pc_player_hit)
	pc.player_died.connect(_on_pc_player_died)


func _on_pc_enemy_hit(enemy: Node, damage: float) -> void:
	if enemy is Node3D:
		_spawn_damage_popup((enemy as Node3D).global_position + Vector3(0.0, 0.9, 0.0), damage, Color(1.0, 0.92, 0.35), false)


func _on_pc_player_hit(amount: float) -> void:
	_spawn_damage_popup(_player.global_position + Vector3(0.0, 1.2, 0.0), amount, Color(1.0, 0.38, 0.38), true)
	if is_instance_valid(_hit_flash):
		_hit_flash.color.a = 0.22
		var t := create_tween()
		t.tween_property(_hit_flash, "color:a", 0.0, 0.2)


func _spawn_damage_popup(world_pos: Vector3, amount: float, color: Color, is_player: bool) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var screen := cam.unproject_position(world_pos)
	var lab := Label.new()
	var v := int(round(amount))
	lab.text = ("-%d" % v) if is_player else str(v)
	lab.add_theme_color_override("font_color", color)
	lab.add_theme_font_size_override("font_size", 22)
	lab.position = screen + Vector2(-18.0, -12.0)
	_vfx_layer.add_child(lab)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(lab, "position", screen + Vector2(-18.0, -48.0), 0.55).set_ease(Tween.EASE_OUT)
	tween.tween_property(lab, "modulate:a", 0.0, 0.55)
	tween.finished.connect(lab.queue_free)


func _on_pc_player_died() -> void:
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if is_instance_valid(_death_overlay):
		_death_overlay.queue_free()
	_death_overlay = _create_death_overlay()
	add_child(_death_overlay)


func _create_death_overlay() -> CanvasLayer:
	var layer := CanvasLayer.new()
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	layer.layer = 120
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.0, 0.0, 0.55)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(center)
	var panel := PanelContainer.new()
	center.add_child(panel)
	var vbox := VBoxContainer.new()
	panel.add_child(vbox)
	var title := Label.new()
	title.text = "Has caído"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	var btn_retry := Button.new()
	btn_retry.text = "Reintentar"
	btn_retry.pressed.connect(_on_death_retry.bind(layer))
	vbox.add_child(btn_retry)
	var btn_menu := Button.new()
	btn_menu.text = "Menú principal"
	btn_menu.pressed.connect(_on_death_menu.bind(layer))
	vbox.add_child(btn_menu)
	return layer


func _on_death_retry(layer: CanvasLayer) -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	layer.queue_free()
	_death_overlay = null
	var pc: Node = _player.get_node("PlayerCombat")
	if pc.has_method("respawn_at"):
		var xf := Transform3D(Basis.IDENTITY, Vector3(0.0, 2.5, 0.0))
		if is_instance_valid(_player_spawn):
			xf = _player_spawn.global_transform
		pc.call("respawn_at", xf)


func _on_death_menu(layer: CanvasLayer) -> void:
	get_tree().paused = false
	layer.queue_free()
	_death_overlay = null
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file(MAIN_MENU)
