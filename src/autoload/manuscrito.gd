extends Node
## "El Manuscrito" — the save system.
##
## The game is literally a book that is being written. Each completed chapter
## is a written page; the ending is a page the player can read (P4). The
## save file is named after that fiction.
##
## Sizing: the file is JSON so it stays human-readable, diffable and
## debuggable. If it ever gets too big, swap the payload for a binary
## resource and keep the same interface.
##
## See TECH_STACK.md §6.1.

const SAVE_VERSION := 1
const SAVE_DIR := "user://saves"
const SLOT_COUNT := 3
const AUTOSAVE_SLOT := 0


func _ready() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(SAVE_DIR)


func slot_path(slot: int) -> String:
	return "%s/manuscrito_%d.json" % [SAVE_DIR, slot]


func has_save(slot: int) -> bool:
	return FileAccess.file_exists(slot_path(slot))


func delete_save(slot: int) -> void:
	if has_save(slot):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(slot_path(slot)))


# ── Save ────────────────────────────────────────────────────────────────

## Write the current game state to a slot.
## Atomic: writes to a .tmp first, then renames. A crash mid-write can
## never leave a half-written save — the worst possible bug.
func save_game(slot: int) -> bool:
	var payload := {
		"version": SAVE_VERSION,
		"timestamp": Time.get_unix_time_from_system(),
		"ms": OS.get_unique_id(),
		"game_state": _serialize_game_state(),
		"truth_layer": TruthLayer.save_state(),
		"locura": Locura.save_state(),
		"memoria": Memoria.save_state(),
		"biblioteca": Biblioteca.save_state(),
	}

	var tmp_path := slot_path(slot) + ".tmp"
	var file := FileAccess.open(tmp_path, FileAccess.WRITE)
	if file == null:
		push_error("[Manuscrito] Could not open %s for writing (err %d)." % [tmp_path, FileAccess.get_open_error()])
		return false
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()

	var target := slot_path(slot)
	if FileAccess.file_exists(target):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(target))
	var err := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(tmp_path),
		ProjectSettings.globalize_path(target)
	)
	if err != OK:
		push_error("[Manuscrito] Atomic rename failed (err %d)." % err)
		return false

	EventBus.game_saved.emit(slot)
	return true


func _serialize_game_state() -> Dictionary:
	# duplicate() the collections: returning live references would let a
	# later mutation change what the snapshot contains.
	return {
		"current_chapter": String(GameState.current_chapter),
		"current_region": String(GameState.current_region),
		"current_posada": String(GameState.current_posada),
		"humanity": GameState.humanity,
		"flags": GameState.flags.duplicate(true),
		"anamorphoses_spotted": GameState.anamorphoses_spotted.duplicate(true),
		"anamorphoses_resolved": GameState.anamorphoses_resolved.duplicate(true),
		"evidence": GameState.evidence.duplicate(true),
		"codex_pages": GameState.codex_pages.duplicate(),
		"pages_written": GameState.pages_written.duplicate(),
		"ending_id": String(GameState.ending_id),
		"author_revealed": GameState.author_revealed,
	}


# ── Load ────────────────────────────────────────────────────────────────

func load_game(slot: int) -> bool:
	if not has_save(slot):
		push_warning("[Manuscrito] Slot %d is empty." % slot)
		return false

	var file := FileAccess.open(slot_path(slot), FileAccess.READ)
	if file == null:
		push_error("[Manuscrito] Could not open slot %d." % slot)
		return false
	var text := file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("[Manuscrito] Slot %d is corrupt." % slot)
		return false

	var data: Dictionary = parsed
	var version := int(data.get("version", 0))
	if version < SAVE_VERSION:
		data = _migrate(data, version)
		if data.is_empty():
			push_error("[Manuscrito] Could not migrate slot %d." % slot)
			return false

	_apply(data)
	EventBus.game_loaded.emit(slot)
	return true


## Migration chain. Keep this FOREVER — you will break old saves in month 14
## and you will still have players on them in month 30.
func _migrate(data: Dictionary, from_version: int) -> Dictionary:
	var current := from_version
	while current < SAVE_VERSION:
		match current:
			0:
				# v0 -> v1: Humanity was introduced in v1.
				data["game_state"]["humanity"] = GameState.HUMANITY_MAX
				current = 1
			_:
				# Unknown future version. Refuse rather than corrupt.
				push_error("[Manuscrito] Unknown save version %d." % current)
				return {}
	return data


func _apply(data: Dictionary) -> void:
	var gs: Dictionary = data.get("game_state", {})

	GameState.current_chapter = StringName(str(gs.get("current_chapter", "")))
	GameState.current_region = StringName(str(gs.get("current_region", "")))
	GameState.current_posada = StringName(str(gs.get("current_posada", "")))
	GameState.humanity = int(gs.get("humanity", GameState.HUMANITY_MAX))
	GameState.flags = gs.get("flags", {})
	GameState.anamorphoses_spotted = gs.get("anamorphoses_spotted", {})
	GameState.anamorphoses_resolved = gs.get("anamorphoses_resolved", {})
	GameState.evidence = gs.get("evidence", {})
	GameState.codex_pages.clear()
	for id: Variant in gs.get("codex_pages", []):
		GameState.codex_pages.append(StringName(id))
	GameState.pages_written.clear()
	for id: Variant in gs.get("pages_written", []):
		GameState.pages_written.append(StringName(id))
	GameState.ending_id = StringName(str(gs.get("ending_id", "")))
	GameState.author_revealed = bool(gs.get("author_revealed", false))

	TruthLayer.load_state(data.get("truth_layer", {}))
	Locura.load_state(data.get("locura", {}))
	Memoria.load_state(data.get("memoria", {}))
	Biblioteca.load_state(data.get("biblioteca", {}))


# ── Slot metadata (for the "read the manuscript" load screen) ───────────

func slot_summary(slot: int) -> Dictionary:
	if not has_save(slot):
		return {}
	var file := FileAccess.open(slot_path(slot), FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	var data: Dictionary = parsed
	var gs: Dictionary = data.get("game_state", {})
	return {
		"chapter": gs.get("current_chapter", ""),
		"region": gs.get("current_region", ""),
		"timestamp": data.get("timestamp", 0),
		"humanity": gs.get("humanity", 0),
		"books": (data.get("biblioteca", {}) as Dictionary).get("collected", []).size(),
	}
