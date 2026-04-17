extends Node3D
## Oleadas y refuerzos: MAX_ACTIVE_ENEMIES evita spam de instancias; un pool de enemigos podría sustituir instanciar/liberar más adelante.

const MAIN_MENU := &"res://scenes/ui/main_menu.tscn"
const SETTINGS_SCENE: PackedScene = preload("res://scenes/ui/settings.tscn")
const PLAYER_WITH_COMBAT: PackedScene = preload("res://scenes/gameplay/player_with_combat.tscn")
## Carga en runtime: evita fallos del analizador si alguna escena de enemigo no reimporta aún.
const ENEMY_SCENE_PATHS: PackedStringArray = [
	"res://scenes/gameplay/basic_enemy.tscn",
	"res://scenes/gameplay/ranged_enemy.tscn",
	"res://scenes/gameplay/tank_enemy.tscn",
	"res://scenes/gameplay/fast_enemy.tscn",
]
const HUD_MMO: PackedScene = preload("res://scenes/ui/hud_mmo.tscn")
const EXPERIENCE_SYSTEM := preload("res://scripts/core/experience_system.gd")
const META_LOAD_SLOT := &"aether_load_slot"
const INTRO_SPAWN_EXTRA_Y := 42.0
const SFX_IMPACT := preload("res://assets/audio/hit.wav")

const BASE_WAVE_ENEMIES := 4
const MAX_ACTIVE_ENEMIES := 12
const WAVE_INTERVAL_SEC := 12.0
const WAVE_TELEGRAPH_SEC := 3.0
const ENEMY_HEALTH_GROWTH_PER_WAVE := 0.12
const ENEMY_DAMAGE_GROWTH_PER_WAVE := 0.08
const AMBIENT_MUSIC_PATH := "res://assets/audio/ambient_loop.ogg"

@onready var _pause: CanvasLayer = $PauseOverlay
@onready var _npc: Node3D = $NpcPlaza
@onready var _player_spawn: Marker3D = $PlayerSpawn
@onready var _enemy_spawns: Array[Marker3D] = []

var _player: Node3D = null
var _hud_layer: CanvasLayer
var _vfx_layer: CanvasLayer
var _hit_flash: ColorRect = null
var _death_overlay: CanvasLayer = null
var _wave_timer: Timer = null
var _wave_index: int = 0
var _alive_enemies: Array[Node3D] = []
var _wave_label: Label = null
var _stats_label: Label = null
var _hud_mmo: HudMmo = null
var _run_time_sec: float = 0.0
var _kills: int = 0
var _best_wave_reached: int = 1
var _enemy_scenes: Array[PackedScene] = []
var _stats_refresh_timer: float = 0.0
var _load_slot: int = -1
var _pending_load: Dictionary = {}
var _spawn_extra_y: float = 0.0
var _intro_fall_active: bool = false
var _intro_was_airborne: bool = false
var _toast_layer: CanvasLayer = null
var _edge_left: ColorRect
var _edge_right: ColorRect
var _edge_top: ColorRect
var _edge_bottom: ColorRect
var _saturation_toast_cd: float = 0.0
var _wave_color_default: Color = Color(0.92, 0.96, 1.0)


func _ready() -> void:
	_consume_session_boot()
	_setup_inputs()
	_load_enemy_scenes()
	# HUD 2D bajo un CanvasLayer (no colgar Control directamente del Node3D: ocupa mal el viewport).
	_hud_layer = CanvasLayer.new()
	_hud_layer.layer = 12
	add_child(_hud_layer)
	_vfx_layer = CanvasLayer.new()
	_vfx_layer.layer = 45
	add_child(_vfx_layer)
	_hit_flash = ColorRect.new()
	_hit_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hit_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hit_flash.color = Color(0.9, 0.12, 0.12, 0.0)
	_vfx_layer.add_child(_hit_flash)
	_setup_directional_damage_edges()
	_toast_layer = CanvasLayer.new()
	_toast_layer.layer = 100
	_toast_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_toast_layer)
	_setup_player()
	_hud_mmo = HUD_MMO.instantiate() as HudMmo
	_hud_layer.add_child(_hud_mmo)
	_wave_label = _hud_mmo.wave_label
	_stats_label = _hud_mmo.stats_label
	_hud_mmo.set_resource_bar_mana_mode(false)
	if _intro_fall_active:
		_wave_label.text = "Aterriza para comenzar"
	if not _intro_fall_active:
		_setup_enemies()
	_try_start_ambient_music()
	_connect_combat_feedback()
	_pause.hide_pause()
	_pause.resume_pressed.connect(_on_pause_resume)
	_pause.main_menu_pressed.connect(_on_pause_main_menu)
	_pause.settings_pressed.connect(_on_pause_settings)
	_pause.save_slot_pressed.connect(_on_pause_save_slot)


func _physics_process(_delta: float) -> void:
	if not _intro_fall_active or not is_instance_valid(_player):
		return
	var body := _player as CharacterBody3D
	if body == null:
		return
	if not body.is_on_floor():
		_intro_was_airborne = true
	elif _intro_was_airborne:
		_finish_intro_land()


func _finish_intro_land() -> void:
	if not _intro_fall_active:
		return
	_intro_fall_active = false
	SaveSlots.mark_intro_fall_complete()
	var tp := _player as ThirdPersonPlayer
	if tp:
		tp.controls_locked = false
	if is_instance_valid(_hit_flash):
		_hit_flash.color = Color(0.45, 0.48, 0.55, 0.38)
		var t := create_tween()
		t.tween_property(_hit_flash, "color:a", 0.0, 0.4)
	_play_intro_impact_fx()
	_setup_enemies()


func _play_intro_impact_fx() -> void:
	if is_instance_valid(_player):
		var arm := _player.get_node_or_null("SpringArm3D") as SpringArm3D
		if arm:
			var base: Vector3 = arm.rotation
			var tw := create_tween()
			tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			tw.tween_property(arm, "rotation", base + Vector3(0.1, 0.06, 0.0), 0.05)
			tw.tween_property(arm, "rotation", base + Vector3(-0.06, -0.05, 0.02), 0.06)
			tw.tween_property(arm, "rotation", base, 0.22)
	CombatSfx.play(self, SFX_IMPACT, -8.0)


func _show_game_toast(message: String) -> void:
	if _toast_layer == null:
		return
	for c in _toast_layer.get_children():
		c.queue_free()
	var lab := Label.new()
	lab.text = message
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lab.set_anchors_preset(Control.PRESET_TOP_WIDE)
	lab.offset_top = 52.0
	lab.offset_bottom = 92.0
	lab.add_theme_font_size_override(&"font_size", 17)
	lab.add_theme_color_override(&"font_color", Color(0.62, 0.96, 0.82))
	lab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_layer.add_child(lab)
	var host := Node.new()
	host.process_mode = Node.PROCESS_MODE_ALWAYS
	_toast_layer.add_child(host)
	var tw := host.create_tween()
	tw.tween_interval(1.85)
	tw.tween_property(lab, "modulate:a", 0.0, 0.4)
	tw.finished.connect(func() -> void: lab.queue_free(); host.queue_free())


func _on_pause_save_slot(slot: int) -> void:
	if slot < 0 or slot >= SaveSlots.SLOT_COUNT:
		return
	if not is_instance_valid(_player):
		return
	var es: ExperienceSystem = _player.get_node_or_null("ExperienceSystem") as ExperienceSystem
	var lvl: int = es.current_level if es else 1
	var xp: int = es.current_experience if es else 0
	var err: Error = SaveSlots.save_run(
		slot,
		_wave_index,
		_kills,
		int(floor(_run_time_sec)),
		_best_wave_reached,
		lvl,
		xp
	)
	if err == OK:
		if es:
			es.persist_progress_file()
		_show_game_toast("Partida guardada · Ranura %d" % (slot + 1))
	else:
		_show_game_toast("No se pudo guardar la partida.")


func _try_start_ambient_music() -> void:
	if not ResourceLoader.exists(AMBIENT_MUSIC_PATH):
		return
	var stream: AudioStream = load(AMBIENT_MUSIC_PATH) as AudioStream
	if stream == null:
		return
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	elif stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	var ap := AudioStreamPlayer.new()
	ap.name = "AmbientMusic"
	ap.bus = &"Music"
	ap.stream = stream
	ap.volume_db = -10.0
	ap.process_mode = Node.PROCESS_MODE_ALWAYS
	ap.autoplay = true
	add_child(ap)


func _setup_directional_damage_edges() -> void:
	_edge_left = _make_edge_rect()
	_edge_left.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	_edge_left.offset_right = 96.0
	_vfx_layer.add_child(_edge_left)
	_edge_right = _make_edge_rect()
	_edge_right.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	_edge_right.offset_left = -96.0
	_vfx_layer.add_child(_edge_right)
	_edge_top = _make_edge_rect()
	_edge_top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_edge_top.offset_bottom = 72.0
	_vfx_layer.add_child(_edge_top)
	_edge_bottom = _make_edge_rect()
	_edge_bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_edge_bottom.offset_top = -72.0
	_vfx_layer.add_child(_edge_bottom)


func _make_edge_rect() -> ColorRect:
	var r := ColorRect.new()
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.color = Color(1.0, 0.12, 0.1, 0.0)
	return r


func _flash_directional_hit(source: Node, amount: float) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null or not is_instance_valid(_player) or not is_instance_valid(source):
		_flash_uniform_hit_flash(amount)
		return
	if not (source is Node3D):
		_flash_uniform_hit_flash(amount)
		return
	var to_src: Vector3 = (source as Node3D).global_position - _player.global_position
	to_src.y = 0.0
	if to_src.length_squared() < 0.0001:
		_flash_uniform_hit_flash(amount)
		return
	to_src = to_src.normalized()
	var right: Vector3 = cam.global_transform.basis.x
	var fwd: Vector3 = -cam.global_transform.basis.z
	right.y = 0.0
	fwd.y = 0.0
	if right.length_squared() > 0.0001:
		right = right.normalized()
	if fwd.length_squared() > 0.0001:
		fwd = fwd.normalized()
	var lr: float = to_src.dot(right)
	var fb: float = to_src.dot(fwd)
	var edge: ColorRect = _edge_right
	if absf(lr) >= absf(fb):
		edge = _edge_left if lr < 0.0 else _edge_right
	else:
		edge = _edge_top if fb < 0.0 else _edge_bottom
	var a: float = clampf(amount / 45.0, 0.12, 0.42)
	_pulse_edge(edge, a)


func _pulse_edge(edge: ColorRect, alpha_max: float) -> void:
	if edge == null:
		return
	edge.color.a = alpha_max
	var tw := create_tween()
	tw.tween_property(edge, "color:a", 0.0, 0.38).set_ease(Tween.EASE_OUT)


func _flash_uniform_hit_flash(amount: float) -> void:
	if not is_instance_valid(_hit_flash):
		return
	_hit_flash.color = Color(0.92, 0.15, 0.12, clampf(amount / 55.0, 0.12, 0.28))
	var t := create_tween()
	t.tween_property(_hit_flash, "color:a", 0.0, 0.22)


func _unhandled_input(event: InputEvent) -> void:
	if event == null:
		return
	if is_instance_valid(_death_overlay):
		return
	if DialogueManager.is_dialogue_active():
		return
	if get_tree().paused:
		return
	if _intro_fall_active:
		if event.is_action_pressed(&"ui_cancel"):
			_open_pause()
			get_viewport().set_input_as_handled()
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


func _load_enemy_scenes() -> void:
	_enemy_scenes.clear()
	for path in ENEMY_SCENE_PATHS:
		var ps: PackedScene = load(path) as PackedScene
		if ps:
			_enemy_scenes.append(ps)
		else:
			push_error("prototype_playground: no se pudo cargar escena: %s" % path)


func _consume_session_boot() -> void:
	_load_slot = -1
	_pending_load = {}
	_spawn_extra_y = 0.0
	_intro_fall_active = false
	_intro_was_airborne = false

	var root: Window = get_tree().root
	if root.has_meta(META_LOAD_SLOT):
		_load_slot = int(root.get_meta(META_LOAD_SLOT, -1))
		root.remove_meta(META_LOAD_SLOT)

	if _load_slot >= 0 and SaveSlots.slot_has_data(_load_slot):
		_pending_load = SaveSlots.load_run_into_session(_load_slot)
		_wave_index = int(_pending_load.get("wave_index", 0))
		_kills = int(_pending_load.get("kills", 0))
		_run_time_sec = float(int(_pending_load.get("play_time_sec", 0)))
		_best_wave_reached = maxi(1, int(_pending_load.get("best_wave", 1)))
		return

	if not SaveSlots.is_intro_fall_complete():
		_intro_fall_active = true
		_intro_was_airborne = false
		_spawn_extra_y = INTRO_SPAWN_EXTRA_Y


func _setup_player() -> void:
	_player = PLAYER_WITH_COMBAT.instantiate()
	var spawn_xf := Transform3D(Basis.IDENTITY, Vector3(0.0, 2.5, 0.0))
	if is_instance_valid(_player_spawn):
		spawn_xf = _player_spawn.global_transform
	spawn_xf.origin.y += _spawn_extra_y
	_player.global_transform = spawn_xf
	add_child(_player)
	_player.add_to_group("player")

	_add_experience_system()
	if bool(_pending_load.get("ok", false)):
		var es: ExperienceSystem = _player.get_node_or_null("ExperienceSystem") as ExperienceSystem
		if es:
			es.apply_loaded_progress(
				int(_pending_load.get("level", 1)),
				int(_pending_load.get("experience", 0)))

	if _intro_fall_active:
		var tp := _player as ThirdPersonPlayer
		if tp:
			tp.controls_locked = true
	
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


func _add_experience_system() -> void:
	if EXPERIENCE_SYSTEM and _player:
		var exp_system = EXPERIENCE_SYSTEM.new()
		exp_system.name = "ExperienceSystem"
		_player.add_child(exp_system)
		print("Sistema de experiencia añadido al jugador")


func _on_wave_timer_timeout() -> void:
	_cleanup_enemy_refs()
	if _alive_enemies.size() >= MAX_ACTIVE_ENEMIES:
		if _saturation_toast_cd <= 0.0:
			_show_game_toast("Zona saturada: derrota enemigos para recibir refuerzos.")
			_saturation_toast_cd = 10.0
		return
	_wave_index += 1
	var enemies_to_spawn := mini(BASE_WAVE_ENEMIES + _wave_index, MAX_ACTIVE_ENEMIES - _alive_enemies.size())
	_spawn_wave(enemies_to_spawn)


func _spawn_wave(count: int) -> void:
	if count <= 0 or _enemy_scenes.is_empty():
		return
	for i in range(count):
		var scene: PackedScene = _enemy_scenes[randi() % _enemy_scenes.size()]
		var enemy := scene.instantiate() as Node3D
		add_child(enemy)
		enemy.global_position = _pick_spawn_position(i)
		_apply_wave_scaling(enemy, _wave_index)
		_alive_enemies.append(enemy)
		if enemy.has_signal("enemy_died"):
			enemy.enemy_died.connect(_on_enemy_died.bind(enemy))
	_cleanup_enemy_refs()
	_refresh_wave_hud()


func _refresh_wave_hud() -> void:
	if not is_instance_valid(_wave_label):
		return
	if _intro_fall_active:
		return
	_wave_label.modulate = _wave_color_default
	var wave_num: int = _wave_index + 1
	var active: int = _alive_enemies.size()
	var line: String = "Oleada %d   Enemigos activos: %d" % [wave_num, active]
	if active >= MAX_ACTIVE_ENEMIES:
		line += "   · ¡Saturado!"
	if is_instance_valid(_wave_timer) and not _wave_timer.is_stopped():
		var tl: float = _wave_timer.time_left
		if tl > 0.05:
			line += "   · Refuerzos ~%ds" % int(ceil(tl))
			if tl <= WAVE_TELEGRAPH_SEC:
				_wave_label.modulate = Color(1.0, 0.92, 0.55)
	_wave_label.text = line


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
	_refresh_wave_hud()


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
	if not _intro_fall_active:
		_run_time_sec += delta
	if _saturation_toast_cd > 0.0:
		_saturation_toast_cd = maxf(0.0, _saturation_toast_cd - delta)
	_refresh_wave_hud()
	_best_wave_reached = maxi(_best_wave_reached, _wave_index + 1)
	if not _stats_label.visible and (_run_time_sec >= 5.0 or _kills > 0):
		_stats_label.visible = true
		_update_stats_line()
	_stats_refresh_timer += delta
	if not _stats_label.visible:
		return
	if _stats_refresh_timer < 0.5:
		return
	_stats_refresh_timer = 0.0
	_update_stats_line()


func _update_stats_line() -> void:
	if not is_instance_valid(_stats_label) or not _stats_label.visible:
		return
	var elapsed := int(floor(_run_time_sec))
	var mins := int(floor(float(elapsed) / 60.0))
	var secs := elapsed % 60
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


func _on_pc_player_hit(amount: float, source: Node = null) -> void:
	_spawn_damage_popup(_player.global_position + Vector3(0.0, 1.2, 0.0), amount, Color(1.0, 0.38, 0.38), true)
	if source != null and is_instance_valid(source):
		_flash_directional_hit(source, amount)
	else:
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
	var et: int = int(floor(_run_time_sec))
	var mins: int = int(floor(float(et) / 60.0))
	var secs: int = et % 60
	var summary := Label.new()
	summary.text = "Oleada %d · Tiempo %02d:%02d · Kills %d" % [_wave_index + 1, mins, secs, _kills]
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary.add_theme_color_override(&"font_color", Color(0.72, 0.82, 0.94))
	summary.add_theme_font_size_override(&"font_size", 13)
	vbox.add_child(summary)
	var hint := Label.new()
	hint.text = "Reintentar: oleada y estadísticas vuelven al inicio (tu nivel se mantiene)."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.custom_minimum_size = Vector2(300, 0)
	hint.add_theme_color_override(&"font_color", Color(0.55, 0.62, 0.72))
	hint.add_theme_font_size_override(&"font_size", 11)
	vbox.add_child(hint)
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
	if is_instance_valid(_stats_label):
		_stats_label.visible = false
	_stats_refresh_timer = 0.0
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
