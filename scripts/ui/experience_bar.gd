extends Control
## Barra de experiencia y nivel del jugador.

@export var experience_system_path: NodePath = ""

var _experience_system: ExperienceSystem = null
var _current_level: int = 1
var _current_exp: int = 0
var _exp_to_next: int = 0

@onready var _exp_fill: Panel = $Background/ExperienceFill
@onready var _exp_text: Label = $Background/ExperienceText
@onready var _level_text: Label = $LevelBadge/LevelText


func _ready() -> void:
	# Intentar conectar al ExperienceSystem automáticamente
	if experience_system_path:
		_experience_system = get_node(experience_system_path) as ExperienceSystem
		_connect_to_experience_system(_experience_system)
	else:
		# Buscar ExperienceSystem en el árbol o autoloads
		_try_find_experience_system()
	
	# Mostrar nivel inicial
	_update_level_display(1)


func _try_find_experience_system() -> void:
	# Buscar en autoloads primero
	_experience_system = get_node_or_null("/root/ExperienceSystem")
	
	if not _experience_system:
		# Buscar en el jugador
		var player = get_tree().get_first_node_in_group("player")
		if player:
			if player.has_node("ExperienceSystem"):
				_experience_system = player.get_node("ExperienceSystem") as ExperienceSystem
	
	if _experience_system:
		_connect_to_experience_system(_experience_system)
	else:
		print("ExperienceBar: No se encontró ExperienceSystem")


func _connect_to_experience_system(system: ExperienceSystem) -> void:
	if not system:
		return
	
	_experience_system = system
	_experience_system.experience_gained.connect(_on_experience_gained)
	_experience_system.level_up.connect(_on_level_up)
	
	# Actualizar con valores iniciales
	var info = _experience_system.get_experience_info()
	_current_exp = info.current
	_exp_to_next = info.to_next
	_current_level = _experience_system.get_level()
	
	_update_display()
	_update_level_display(_current_level)


func _on_experience_gained(amount: int, total: int, to_next: int) -> void:
	_current_exp = total
	_exp_to_next = to_next
	
	_update_display()
	
	# Mostrar popup de experiencia ganada
	_show_exp_gain_popup(amount)


func _on_level_up(new_level: int) -> void:
	_current_level = new_level
	
	_update_level_display(new_level)
	_update_display()
	
	# Efecto visual de subida de nivel
	_play_level_up_effect()


func _update_display() -> void:
	var exp_percent = float(_current_exp) / float(_exp_to_next) if _exp_to_next > 0 else 0.0
	
	# Actualizar ancho de la barra
	var max_width = $Background.size.x - 8
	_exp_fill.size.x = max_width * exp_percent
	
	# Actualizar texto
	_exp_text.text = "Nivel %d" % _current_level
	
	# Cambiar color de la barra según nivel
	var stylebox = _exp_fill.get_theme_stylebox("panel").duplicate()
	
	if _current_level < 5:
		stylebox.bg_color = Color(0.4, 0.2, 0.8)  # Morado
	elif _current_level < 10:
		stylebox.bg_color = Color(0.2, 0.4, 0.8)  # Azul
	elif _current_level < 15:
		stylebox.bg_color = Color(0.8, 0.4, 0.2)  # Naranja
	else:
		stylebox.bg_color = Color(0.8, 0.2, 0.2)  # Rojo (nivel alto)
	
	_exp_fill.add_theme_stylebox_override("panel", stylebox)


func _update_level_display(level: int) -> void:
	_level_text.text = str(level)
	
	# Efecto visual al cambiar nivel
	var tween = create_tween()
	tween.tween_property(_level_text, "scale", Vector2(1.3, 1.3), 0.1)
	tween.tween_property(_level_text, "scale", Vector2(1.0, 1.0), 0.2)


func _show_exp_gain_popup(amount: int) -> void:
	# Crear label flotante
	var popup = Label.new()
	popup.text = "+%d XP" % amount
	popup.add_theme_font_size_override("font_size", 16)
	popup.add_theme_color_override("font_color", Color(0.8, 0.6, 1.0))
	popup.position = Vector2(size.x / 2, -20)
	popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	add_child(popup)
	
	# Animación: flotar hacia arriba y desaparecer
	var tween = create_tween()
	tween.tween_property(popup, "position:y", -50, 0.8)
	tween.parallel().tween_property(popup, "modulate:a", 0.0, 0.8)
	tween.tween_callback(popup.queue_free)


func _play_level_up_effect() -> void:
	# Efecto visual para subida de nivel
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Escalar badge
	tween.tween_property($LevelBadge, "scale", Vector2(1.3, 1.3), 0.2)
	tween.tween_property($LevelBadge, "scale", Vector2(1.0, 1.0), 0.2).set_delay(0.2)
	
	# Cambiar color temporalmente
	var original_color = $LevelBadge.get_theme_stylebox("panel").bg_color
	var flash_color = Color(1.0, 1.0, 0.8)
	
	var stylebox = $LevelBadge.get_theme_stylebox("panel").duplicate()
	stylebox.bg_color = flash_color
	$LevelBadge.add_theme_stylebox_override("panel", stylebox)
	
	await get_tree().create_timer(0.4).timeout
	
	stylebox.bg_color = original_color
	$LevelBadge.add_theme_stylebox_override("panel", stylebox)
	
	# Mostrar texto "LEVEL UP!"
	_show_level_up_text()


func _show_level_up_text() -> void:
	var level_up_label = Label.new()
	level_up_label.text = "¡NIVEL %d!" % _current_level
	level_up_label.add_theme_font_size_override("font_size", 24)
	level_up_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	level_up_label.add_theme_constant_override("outline_size", 4)
	level_up_label.add_theme_color_override("font_outline_color", Color(0.2, 0.1, 0.4))
	level_up_label.position = Vector2(size.x / 2, -60)
	level_up_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	add_child(level_up_label)
	
	var tween = create_tween()
	tween.tween_property(level_up_label, "position:y", -100, 1.5)
	tween.parallel().tween_property(level_up_label, "modulate:a", 0.0, 1.5)
	tween.tween_callback(level_up_label.queue_free)


# API para actualización manual
func set_experience_info(level: int, exp: int, exp_to_next: int) -> void:
	_current_level = level
	_current_exp = exp
	_exp_to_next = exp_to_next
	
	_update_display()
	_update_level_display(level)


func disconnect_from_experience_system() -> void:
	if _experience_system:
		if _experience_system.experience_gained.is_connected(_on_experience_gained):
			_experience_system.experience_gained.disconnect(_on_experience_gained)
		if _experience_system.level_up.is_connected(_on_level_up):
			_experience_system.level_up.disconnect(_on_level_up)
	_experience_system = null