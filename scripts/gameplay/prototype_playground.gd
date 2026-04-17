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


func _ready() -> void:
	_setup_inputs()
	_setup_player()
	_setup_enemies()
	_pause.hide_pause()
	_pause.resume_pressed.connect(_on_pause_resume)
	_pause.main_menu_pressed.connect(_on_pause_main_menu)
	_pause.settings_pressed.connect(_on_pause_settings)


func _unhandled_input(event: InputEvent) -> void:
	if event == null:
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
	# Instanciar jugador con combate
	_player = PLAYER_WITH_COMBAT.instantiate()
	_player.global_transform = _player_spawn.global_transform
	add_child(_player)
	_player.add_to_group("player")
	print("Jugador con combate creado")
	
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
		print("UI de experiencia añadida")


func _process(delta: float) -> void:
	# Debug: mostrar info del jugador (solo si no hay UI)
	if _player and _player.has_node("PlayerCombat"):
		var combat = _player.get_node("PlayerCombat")
		if combat.has_method("get_current_health"):
			var health = combat.get_current_health()
			var max_health = combat.get_max_health()
			if Engine.get_frames_drawn() % 300 == 0:  # Cada 5 segundos aprox
				print("Salud del jugador: ", health, " / ", max_health)
	
	# Debug: mostrar experiencia si existe
	if _player and _player.has_node("ExperienceSystem"):
		var exp_system = _player.get_node("ExperienceSystem") as ExperienceSystem
		if exp_system and Engine.get_frames_drawn() % 300 == 0:
			var info = exp_system.get_experience_info()
			print("Experiencia: ", info.current, "/", info.to_next, " (Nivel ", exp_system.get_level(), ")")
