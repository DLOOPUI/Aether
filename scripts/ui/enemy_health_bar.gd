extends Node3D
## Barra de salud 3D que flota sobre enemigos.

@export var health_system: HealthSystem = null
@export var vertical_offset: float = 2.2
@export var always_face_camera: bool = true

var _current_health: float = 0.0
var _max_health: float = 0.0

@onready var _health_fill: Panel = $SubViewport/Control/Background/HealthFill
@onready var _sprite: Sprite3D = $Sprite3D


func _ready() -> void:
	if health_system:
		_connect_to_health_system(health_system)
	
	# Posicionar sobre el padre
	if get_parent() is Node3D:
		global_position = get_parent().global_position + Vector3(0, vertical_offset, 0)
	
	# Ocultar inicialmente
	_sprite.visible = false


func _process(_delta: float) -> void:
	if always_face_camera:
		var camera := get_viewport().get_camera_3d()
		if camera:
			var target := camera.global_position
			var here := global_position
			var to_cam := target - here
			if to_cam.length_squared() > 0.0001:
				var up := Vector3.UP
				var n := to_cam.normalized()
				if absf(n.dot(up)) > 0.98:
					up = Vector3.FORWARD
				look_at(target, up)
	if get_parent() is Node3D:
		global_position = (get_parent() as Node3D).global_position + Vector3(0, vertical_offset, 0)


func _connect_to_health_system(system: HealthSystem) -> void:
	if not system:
		return
	
	health_system = system
	health_system.health_changed.connect(_on_health_changed)
	health_system.damage_taken.connect(_on_damage_taken)
	
	# Mostrar solo si no está a máxima salud
	_current_health = system.current_health
	_max_health = system.max_health
	
	_update_display()
	_sprite.visible = _current_health < _max_health


func _on_health_changed(current: float, max_health: float) -> void:
	_current_health = current
	_max_health = max_health
	
	_update_display()
	
	# Mostrar/ocultar según salud
	if _current_health >= _max_health:
		_sprite.visible = false
	else:
		_sprite.visible = true
		
		# Mostrar temporalmente después de recibir daño
		var tween = create_tween()
		tween.tween_property(_sprite, "modulate:a", 1.0, 0.1)
		
		# Ocultar después de 3 segundos si no recibe más daño
		if has_method("_schedule_hide"):
			_schedule_hide()


func _on_damage_taken(_amount: float, _source: Node) -> void:
	# Asegurar que sea visible al recibir daño
	_sprite.visible = true
	_sprite.modulate.a = 1.0
	
	# Cancelar ocultado programado
	if has_method("_cancel_scheduled_hide"):
		_cancel_scheduled_hide()
	
	# Programar ocultado
	_schedule_hide()


func _update_display() -> void:
	var health_percent: float = _current_health / _max_health if _max_health > 0 else 0.0
	var max_width: float = 96.0
	var w: float = max_width * health_percent
	_health_fill.set_deferred(&"size", Vector2(w, _health_fill.size.y))
	
	# Cambiar color según salud
	var stylebox = _health_fill.get_theme_stylebox("panel").duplicate()
	
	if health_percent > 0.6:
		stylebox.bg_color = Color(0.9, 0.1, 0.1)  # Rojo (enemigo)
	elif health_percent > 0.3:
		stylebox.bg_color = Color(0.9, 0.5, 0.1)  # Naranja
	else:
		stylebox.bg_color = Color(0.9, 0.8, 0.1)  # Amarillo (crítico)
	
	_health_fill.add_theme_stylebox_override("panel", stylebox)


func _schedule_hide() -> void:
	# Cancelar timer anterior si existe
	if has_node("HideTimer"):
		$HideTimer.stop()
		$HideTimer.queue_free()
	
	# Crear nuevo timer
	var timer = Timer.new()
	timer.name = "HideTimer"
	timer.wait_time = 3.0
	timer.one_shot = true
	timer.timeout.connect(_hide_bar)
	add_child(timer)
	timer.start()


func _cancel_scheduled_hide() -> void:
	if has_node("HideTimer"):
		$HideTimer.stop()
		$HideTimer.queue_free()


func _hide_bar() -> void:
	if _current_health < _max_health:
		var tween = create_tween()
		tween.tween_property(_sprite, "modulate:a", 0.3, 0.5)


func set_health_values(current: float, max_health: float) -> void:
	_current_health = current
	_max_health = max_health
	_update_display()
	_sprite.visible = _current_health < _max_health