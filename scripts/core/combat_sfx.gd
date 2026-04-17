extends RefCounted
class_name CombatSfx
## Reproduce un sonido one-shot; el volumen maestro sigue en GameSettings (bus Master).


static func play(parent: Node, stream: AudioStream, volume_db: float = 0.0) -> void:
	if parent == null or stream == null or not is_instance_valid(parent):
		return
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.volume_db = volume_db
	p.bus = &"SFX"
	parent.add_child(p)
	p.finished.connect(p.queue_free)
	p.play()
