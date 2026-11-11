extends Node
## Global campaign state.
##
## D2: there is exactly one world. One truth layer, one flag set, one save
## file. The two characters differ in perception and verbs — never in whether
## they are standing in a different universe.
##
## See GDD.md §4.1, §12 and TECH_STACK.md §6.1.

const STATE_VERSION := 1

# ── Flow ────────────────────────────────────────────────────────────────
var current_chapter: StringName = &""
var current_region: StringName = &""
var current_posada: StringName = &""

# ── D4: attacking innocents is allowed, and it costs. ───────────────────
const HUMANITY_MAX := 100
var humanity: int = HUMANITY_MAX

# ── Flags ───────────────────────────────────────────────────────────────
## Boolean and integer story flags. `flags` is a flat Dictionary so the save
## file stays human-readable and diffable.
var flags: Dictionary = {}

# ── Investigation ───────────────────────────────────────────────────────
## Anamorphosis ids the player has spotted, and the ones resolved.
var anamorphoses_spotted: Dictionary = {}
var anamorphoses_resolved: Dictionary = {}
## Evidence ids → count. "Gather the evidence that proves the world is flat."
var evidence: Dictionary = {}
## The regions the player has set foot in, and the ones whose case is
## closed (their Venture resolved). GDD.md §11.2: five regions, one
## chapter each.
var regions_found: Dictionary = {}
var regions_resolved: Dictionary = {}
## Chapter ids the player has found (entered the region for).
var chapters_found: Array[StringName] = []
## Chapter ids the player has resolved (completed the Venture/case).
var chapters_resolved: Array[StringName] = []
## The chapter currently active (in progress).
var current_chapter_id: StringName = &""

# ── Manuscript ──────────────────────────────────────────────────────────
## Ids of the 48 Manifiesto fragments the player has found (D7).
var codex_pages: Array[StringName] = []
## Ids of the pages the game has written for the player (D4/P4).
var pages_written: Array[StringName] = []

# ── Endings ─────────────────────────────────────────────────────────────
var ending_id: StringName = &""
## True once the player has staged the Ensayo and been "caught" (D5).
var author_revealed: bool = false

# ── Credits song (GDD.md §14) ───────────────────────────────────────────
## Seconds each character has been the active (driven) pawn. Used at the
## credits to decide whose verse leads: Quixote → Book Truth arrangement,
## Sancho → Reality Truth arrangement.
var quixote_playtime: float = 0.0
var sancho_playtime: float = 0.0

## Add playtime for the character who was driven this frame.
func add_playtime(character_id: StringName, delta: float) -> void:
	if character_id == &"quixote":
		quixote_playtime += delta
	elif character_id == &"sancho":
		sancho_playtime += delta


## Which character was played more (returns &"quixote" or &"sancho").
func character_played_most() -> StringName:
	if quixote_playtime >= sancho_playtime:
		return &"quixote"
	return &"sancho"


## Get playtime for a character.
func get_playtime(character_id: StringName) -> float:
	if character_id == &"quixote":
		return quixote_playtime
	if character_id == &"sancho":
		return sancho_playtime
	return 0.0


func set_flag(key: String, value: Variant = true) -> void:
	flags[key] = value


func get_flag(key: String, default_value: Variant = false) -> Variant:
	return flags.get(key, default_value)


func has_flag(key: String) -> bool:
	return flags.has(key) and bool(flags[key])


func add_evidence(id: StringName) -> void:
	var current: int = int(evidence.get(id, 0))
	evidence[id] = current + 1
	EventBus.evidence_collected.emit(id, current + 1)


func get_evidence_count(id: StringName) -> int:
	return int(evidence.get(id, 0))


func total_evidence() -> int:
	var total := 0
	for key: Variant in evidence:
		total += int(evidence[key])
	return total


# ── Regions ─────────────────────────────────────────────────────────────
## Mark a region as found. The player has set foot in it, or at least
## seen its name on the map.
func find_region(id: StringName) -> void:
	if id.is_empty():
		return
	if not regions_found.has(id):
		regions_found[id] = true
		EventBus.region_found.emit(id)

## Mark a region as resolved — its Venture's case is closed.
func resolve_region(id: StringName) -> void:
	if id.is_empty():
		return
	regions_resolved[id] = true
	EventBus.region_resolved.emit(id)


## Is this region found?
func region_found(id: StringName) -> bool:
	return bool(regions_found.get(id, false))


## Is this region resolved?
func region_resolved(id: StringName) -> bool:
	return bool(regions_resolved.get(id, false))


## How many regions the player has found.
func regions_found_count() -> int:
	return regions_found.size()


## How many regions are resolved.
func regions_resolved_count() -> int:
	return regions_resolved.size()

## Mark a chapter as started (entered).
func chapter_started(id: StringName) -> void:
	if id.is_empty():
		return
	if not chapters_found.has(id):
		chapters_found.append(id)
		EventBus.chapter_started.emit(id)

## Mark a chapter as completed (Venture/case resolved).
func chapter_completed(id: StringName) -> void:
	if id.is_empty():
		return
	if not chapters_resolved.has(id):
		chapters_resolved.append(id)
		EventBus.chapter_completed.emit(id)

## Is this chapter started/found?
func chapter_started_flag(id: StringName) -> bool:
	return chapters_found.has(id)

## Is this chapter completed/resolved?
func chapter_completed_flag(id: StringName) -> bool:
	return chapters_resolved.has(id)

## How many chapters the player has started.
func chapters_started_count() -> int:
	return chapters_found.size()

## How many chapters are completed.
func chapters_completed_count() -> int:
	return chapters_resolved.size()

## Set the current chapter.
func set_current_chapter(id: StringName) -> void:
	current_chapter_id = id

## Get the current chapter id.
func get_current_chapter() -> StringName:
	return current_chapter_id


## Get the chapter id for a given venture id.
##
## Maps each Venture to its chapter. Used when a Venture is resolved to
## mark the chapter and its region as completed.
func chapter_for_venture(venture_id: StringName) -> StringName:
	var venture_to_chapter: Dictionary = {
		&"venture_montiel": &"ch_01_windmills",
		&"venture_basque": &"ch_02_basque",
		&"venture_canting_sea": &"ch_03_canting_sea",
		&"venture_encinados": &"ch_04_encinados",
		&"venture_montesinos": &"ch_05_montesinos",
		&"venture_bridge": &"ch_06_bridge",
		&"venture_dulcinea": &"ch_07_dulcinea",
		&"venture_mirrors": &"ch_11_mirrors",
		&"venture_magician": &"ch_12_magician",
		&"venture_duke": &"ch_13_duke",
	}
	return venture_to_chapter.get(venture_id, &"")


## Get the region id for a chapter id.
##
## Used when marking a chapter's region as resolved.
func region_for_chapter(chapter_id: StringName) -> StringName:
	var chapter_to_region: Dictionary = {
		&"ch_01_windmills": &"camino_la_mancha",
		&"ch_02_basque": &"camino_la_mancha",
		&"ch_03_canting_sea": &"camino_la_mancha",
		&"ch_04_encinados": &"sierra_morena",
		&"ch_05_montesinos": &"sierra_morena",
		&"ch_06_bridge": &"sierra_morena",
		&"ch_07_dulcinea": &"el_toboso",
		&"ch_08_celestina": &"el_toboso",
		&"ch_09_ensayo_setup": &"los_riscos",
		&"ch_10_ensayo_resolution": &"los_riscos",
		&"ch_11_mirrors": &"el_castillo_del_duque",
		&"ch_12_magician": &"el_castillo_del_duque",
		&"ch_13_duke": &"el_castillo_del_duque",
	}
	return chapter_to_region.get(chapter_id, &"")



# ── Humanity (D4) ───────────────────────────────────────────────────────

## Reduce Humanity. Never goes below 0. Emits the change so the manuscript
## can stain the page edge.
func spend_humanity(amount: int) -> void:
	var before := humanity
	humanity = maxi(0, humanity - amount)
	if humanity != before:
		EventBus.humanity_changed.emit(humanity)


## Restore Humanity. Used by the "cure" quests that drain Locura (D1).
func restore_humanity(amount: int) -> void:
	var before := humanity
	humanity = mini(HUMANITY_MAX, humanity + amount)
	if humanity != before:
		EventBus.humanity_changed.emit(humanity)


# ── Ending aggregation (GDD.md §12.2) ───────────────────────────────────

## The five tracked variables that decide the ending. Kept in one place so
## the ending logic is testable in isolation.
func ending_variables() -> Dictionary:
	return {
		"books_collected": Biblioteca.collected.size(),
		"quixote_locura": Locura.get_for(&"quixote"),
		"sancho_locura": Locura.get_for(&"sancho"),
		"humanity": humanity,
		"verdicts_truth": int(flags.get("verdicts_truth", 0)),
		"verdicts_force": int(flags.get("verdicts_force", 0)),
		"second_book": has_flag("found_second_book"),
		"author_revealed": author_revealed,
	}


## Aggregate the ending from the tracked variables.
## Mirrors GDD.md §12.2. Kept deterministic and side-effect free so it can be
## unit-tested (see tests/test_ending.gd).
func compute_ending() -> StringName:
	var v := ending_variables()
	var q := int(v["quixote_locura"])
	var s := int(v["sancho_locura"])
	var books := int(v["books_collected"])
	var humanity_now := int(v["humanity"])

	# The hidden ending: you found the Codex and staged the Ensayo and were
	# caught. The player is the reader.
	if bool(v["author_revealed"]) and books >= 12:
		return &"el_manuscrito"

	# Shared madness: both minds have gone. The world is the book, and both
	# of them are knights. It looks like the happy ending and it is not.
	if q >= 70 and s >= 70:
		return &"la_locura_compartida"

	# The real world: both cured, the book shelved. The sad one.
	if q <= 25 and s <= 25:
		return &"el_mundo_real"

	# Middle ground: the book wins, partly.
	return &"el_libro_gana"
