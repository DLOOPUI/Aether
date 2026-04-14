extends Object
class_name CharacterStorage

const DRAFT_PATH := &"user://character_draft.tres"


static func save_draft(d: CharacterDraft) -> Error:
	return ResourceSaver.save(d, DRAFT_PATH)


static func load_draft() -> CharacterDraft:
	if FileAccess.file_exists(String(DRAFT_PATH)):
		var r := ResourceLoader.load(String(DRAFT_PATH))
		if r is CharacterDraft:
			return r as CharacterDraft
	return CharacterDraft.new()
