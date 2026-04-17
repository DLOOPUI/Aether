extends Object
class_name SaveSlots
## Guardado en `user://aether_save.cfg`: meta global (intro) + 3 ranuras con resumen para menús.

const PATH := "user://aether_save.cfg"
const SLOT_COUNT := 3
const SECTION_META := "meta"
const SECTION_SLOT := "slot_%d"


static func _cf() -> ConfigFile:
	var cf := ConfigFile.new()
	cf.load(PATH)
	return cf


static func _save_cf(cf: ConfigFile) -> void:
	cf.save(PATH)


static func is_intro_fall_complete() -> bool:
	var cf := _cf()
	return bool(cf.get_value(SECTION_META, "intro_fall_complete", false))


static func mark_intro_fall_complete() -> void:
	var cf := _cf()
	cf.set_value(SECTION_META, "intro_fall_complete", true)
	_save_cf(cf)


static func has_any_slot() -> bool:
	for i in SLOT_COUNT:
		if slot_has_data(i):
			return true
	return false


## Ranura con `saved_at` más reciente, o -1 si no hay datos.
static func get_most_recent_filled_slot() -> int:
	var best_t: int = -1
	var best_i: int = -1
	var cf := _cf()
	for i in SLOT_COUNT:
		if not slot_has_data(i):
			continue
		var sec: String = SECTION_SLOT % i
		var t: int = int(cf.get_value(sec, "saved_at", 0))
		if t > best_t:
			best_t = t
			best_i = i
	return best_i


static func slot_has_data(slot: int) -> bool:
	if slot < 0 or slot >= SLOT_COUNT:
		return false
	var cf := _cf()
	var sec: String = SECTION_SLOT % slot
	return bool(cf.get_value(sec, "has_data", false))


static func get_slot_summary(slot: int) -> String:
	if not slot_has_data(slot):
		return "Ranura %d — vacía" % (slot + 1)
	var cf := _cf()
	var sec: String = SECTION_SLOT % slot
	var t: int = int(cf.get_value(sec, "saved_at", 0))
	var wave: int = int(cf.get_value(sec, "wave_index", 0))
	var kills: int = int(cf.get_value(sec, "kills", 0))
	var lvl: int = int(cf.get_value(sec, "level", 1))
	var pt: int = int(cf.get_value(sec, "play_time_sec", 0))
	var m: int = pt / 60
	var s: int = pt % 60
	var when := ""
	if t > 0:
		var d: Dictionary = Time.get_datetime_dict_from_unix_time(t)
		when = " · %02d/%02d %02d:%02d" % [int(d.month), int(d.day), int(d.hour), int(d.minute)]
	return "Ranura %d — Nv.%d · Oleada %d · %d kills · %02d:%02d%s" % [slot + 1, lvl, wave + 1, kills, m, s, when]


static func save_run(slot: int, wave_index: int, kills: int, play_time_sec: int, best_wave: int, level: int, experience: int) -> Error:
	if slot < 0 or slot >= SLOT_COUNT:
		return ERR_INVALID_PARAMETER
	var cf := _cf()
	var sec: String = SECTION_SLOT % slot
	cf.set_value(sec, "has_data", true)
	cf.set_value(sec, "wave_index", wave_index)
	cf.set_value(sec, "kills", kills)
	cf.set_value(sec, "play_time_sec", play_time_sec)
	cf.set_value(sec, "best_wave", best_wave)
	cf.set_value(sec, "level", level)
	cf.set_value(sec, "experience", experience)
	cf.set_value(sec, "saved_at", int(Time.get_unix_time_from_system()))
	_save_cf(cf)
	return OK


static func load_run_into_session(slot: int) -> Dictionary:
	var out := {
		"ok": false,
		"wave_index": 0,
		"kills": 0,
		"play_time_sec": 0,
		"best_wave": 1,
		"level": 1,
		"experience": 0,
	}
	if not slot_has_data(slot):
		return out
	var cf := _cf()
	var sec: String = SECTION_SLOT % slot
	out.ok = true
	out.wave_index = int(cf.get_value(sec, "wave_index", 0))
	out.kills = int(cf.get_value(sec, "kills", 0))
	out.play_time_sec = int(cf.get_value(sec, "play_time_sec", 0))
	out.best_wave = int(cf.get_value(sec, "best_wave", 1))
	out.level = int(cf.get_value(sec, "level", 1))
	out.experience = int(cf.get_value(sec, "experience", 0))
	return out


static func clear_slot(slot: int) -> void:
	if slot < 0 or slot >= SLOT_COUNT:
		return
	var cf := _cf()
	cf.erase_section(SECTION_SLOT % slot)
	_save_cf(cf)
