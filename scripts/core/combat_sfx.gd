extends RefCounted
class_name CombatSfx
## Reproduce un sonido one-shot; el volumen maestro sigue en GameSettings (bus Master).


static func play(parent: Node, stream: AudioStream, volume_db: float = 0.0) -> void:
	if parent == null or stream == null or not is_instance_valid(parent):
		return
	var p := AudioStreamPlayer.new()
	p.stream = stream
	var sfx_db := 0.0
	var gs := parent.get_node_or_null("/root/GameSettings")
	if gs and gs.has_method("get_sfx_volume_db"):
		sfx_db = gs.get_sfx_volume_db()
	p.volume_db = volume_db + sfx_db
	p.bus = &"Master"
	parent.add_child(p)
	p.finished.connect(p.queue_free)
	p.play()
