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
const ENEMY_TYPES := [BASIC_ENEMY, RANGED_ENEMY, TANK_ENEMY, FAST_ENEMY]

const BASE_WAVE_ENEMIES := 4
const MAX_ACTIVE_ENEMIES := 12
const WAVE_INTERVAL_SEC := 12.0
const ENEMY_HEALTH_GROWTH_PER_WAVE := 0.12
const ENEMY_DAMAGE_GROWTH_PER_WAVE := 0.08

@onready var _pause: CanvasLayer = $PauseOverlay
@onready var _npc: Node3D = $NpcPlaza
@onready var _player_spawn: Marker3D = $PlayerSpawn
@onready var _enemy_spawns: Array[Marker3D] = []

var _player: Node3D = null
var _vfx_layer: CanvasLayer
var _hit_flash: ColorRect = null
var _death_overlay: CanvasLayer = null
var _wave_timer: Timer = null
var _wave_index: int = 0
var _alive_enemies: Array[Node3D] = []
var _wave_label: Label = null
var _stats_label: Label = null
var _run_time_sec: float = 0.0
var _kills: int = 0
var _best_wave_reached: int = 1


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
	_wave_label = Label.new()
	_wave_label.position = Vector2(18, 12)
	_wave_label.add_theme_font_size_override("font_size", 20)
	_wave_label.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	_wave_label.text = "Oleada 1"
	_vfx_layer.add_child(_wave_label)
	_stats_label = Label.new()
	_stats_label.position = Vector2(18, 38)
	_stats_label.add_theme_font_size_override("font_size", 16)
	_stats_label.add_theme_color_override("font_color", Color(0.85, 0.9, 0.95))
	_vfx_layer.add_child(_stats_label)
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
	_spawn_wave(BASE_WAVE_ENEMIES)
	_wave_timer = Timer.new()
	_wave_timer.wait_time = WAVE_INTERVAL_SEC
	_wave_timer.one_shot = false
	_wave_timer.timeout.connect(_on_wave_timer_timeout)
	add_child(_wave_timer)
	_wave_timer.start()


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


func _on_wave_timer_timeout() -> void:
	_cleanup_enemy_refs()
	if _alive_enemies.size() >= MAX_ACTIVE_ENEMIES:
		return
	_wave_index += 1
	var enemies_to_spawn := mini(BASE_WAVE_ENEMIES + _wave_index, MAX_ACTIVE_ENEMIES - _alive_enemies.size())
	_spawn_wave(enemies_to_spawn)


func _spawn_wave(count: int) -> void:
	if count <= 0:
		return
	_wave_label.text = "Oleada %d   Enemigos activos: %d" % [_wave_index + 1, _alive_enemies.size()]
	for i in range(count):
		var scene: PackedScene = ENEMY_TYPES[randi() % ENEMY_TYPES.size()]
		var enemy := scene.instantiate() as Node3D
		var spawn_pos := _pick_spawn_position(i)
		enemy.global_position = spawn_pos
		_apply_wave_scaling(enemy, _wave_index)
		add_child(enemy)
		_alive_enemies.append(enemy)
		if enemy.has_signal("enemy_died"):
			enemy.enemy_died.connect(_on_enemy_died.bind(enemy))
	_cleanup_enemy_refs()
	_wave_label.text = "Oleada %d   Enemigos activos: %d" % [_wave_index + 1, _alive_enemies.size()]


func _pick_spawn_position(index: int) -> Vector3:
	if _enemy_spawns.size() > 0:
		var marker := _enemy_spawns[index % _enemy_spawns.size()]
		var jitter := Vector3(randf_range(-1.6, 1.6), 0.0, randf_range(-1.6, 1.6))
		return marker.global_position + jitter
	var angle := randf() * TAU
	var radius := randf_range(6.0, 12.0)
	return Vector3(cos(angle) * radius, 1.0, sin(angle) * radius)


func _on_enemy_died(enemy: Node3D) -> void:
	_alive_enemies.erase(enemy)
	_kills += 1
	_cleanup_enemy_refs()
	_wave_label.text = "Oleada %d   Enemigos activos: %d" % [_wave_index + 1, _alive_enemies.size()]


func _cleanup_enemy_refs() -> void:
	var keep: Array[Node3D] = []
	for e in _alive_enemies:
		if is_instance_valid(e):
			keep.append(e)
	_alive_enemies = keep


func _apply_wave_scaling(enemy: Node3D, wave: int) -> void:
	if wave <= 0:
		return
	var health_mult := 1.0 + ENEMY_HEALTH_GROWTH_PER_WAVE * float(wave)
	var dmg_mult := 1.0 + ENEMY_DAMAGE_GROWTH_PER_WAVE * float(wave)
	if enemy.has_method("set"):
		if enemy.get("max_health") != null:
			enemy.set("max_health", float(enemy.get("max_health")) * health_mult)
		if enemy.get("attack_damage") != null:
			enemy.set("attack_damage", float(enemy.get("attack_damage")) * dmg_mult)


func _process(delta: float) -> void:
	_run_time_sec += delta
	var mins := int(_run_time_sec) / 60
	var secs := int(_run_time_sec) % 60
	_best_wave_reached = maxi(_best_wave_reached, _wave_index + 1)
	_stats_label.text = "Tiempo %02d:%02d   Kills %d   Mejor oleada %d" % [mins, secs, _kills, _best_wave_reached]


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
	for e in _alive_enemies:
		if is_instance_valid(e):
			e.queue_free()
	_alive_enemies.clear()
	_wave_index = 0
	_run_time_sec = 0.0
	_kills = 0
	_best_wave_reached = 1
	_spawn_wave(BASE_WAVE_ENEMIES)
	if is_instance_valid(_wave_timer):
		_wave_timer.start()
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
