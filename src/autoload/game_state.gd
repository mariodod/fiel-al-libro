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
## Region id -> fragment id, loaded lazily from src/data/regions/*.tres.
## A region's fragment names the place (GDD.md §20.1), so it is granted when
## the player first sets foot in the region — including the two regions with
## no Venture to grant it (La Mancha's aperture and the Ensayo's manuscript).
var _region_fragments: Dictionary = {}
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
		# The region's own passage is part of finding it, not a Venture drop.
		grant_codex_page(_region_fragment_for(id))


## Grant a Manifiesto page exactly once, notifying listeners so the map's
## fragment marker can light up immediately.
func grant_codex_page(id: StringName) -> void:
	if id.is_empty() or codex_pages.has(id):
		return
	codex_pages.append(id)
	EventBus.codex_page_found.emit(id)


## Region id -> its fragment id, read from the region resources once.
func _region_fragment_for(id: StringName) -> StringName:
	if _region_fragments.is_empty():
		var dir := DirAccess.open("res://src/data/regions/")
		if dir != null:
			for name in dir.get_files():
				if not name.ends_with(".tres"):
					continue
				var res: RegionData = load("res://src/data/regions/" + name)
				if res != null and not res.fragment_id.is_empty():
					_region_fragments[res.id] = res.fragment_id
	return _region_fragments.get(id, &"")

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


## Write a failure into the manuscript. Death does not respawn at the
## checkpoint: the run back is recorded as a page the player can read later
## (GDD §7.3). Ids are unique so repeated deaths at one spot keep their lines.
func write_page(id: StringName, line: String) -> void:
	if pages_written.has(id):
		return
	pages_written.append(id)
	EventBus.manuscript_page_written.emit(id, line)

## Mark a chapter as started (entered).
func chapter_started(id: StringName) -> void:
	if id.is_empty():
		return
	if not chapters_found.has(id):
		chapters_found.append(id)
		EventBus.chapter_started.emit(id)

## Mark a chapter as completed (Venture/case resolved).
## Clear all campaign progress for a New Game. ChapterFlow calls this before
## entering the prologue; the save file is deleted separately.
func reset_progress() -> void:
	current_chapter = &""
	current_region = &""
	current_posada = &""
	humanity = HUMANITY_MAX
	flags.clear()
	anamorphoses_spotted.clear()
	anamorphoses_resolved.clear()
	Lectura.reset()
	evidence.clear()
	regions_found.clear()
	regions_resolved.clear()
	chapters_found.clear()
	chapters_resolved.clear()
	current_chapter_id = &""
	codex_pages.clear()
	pages_written.clear()
	ending_id = &""
	author_revealed = false
	quixote_playtime = 0.0
	sancho_playtime = 0.0


func chapter_completed(id: StringName) -> void:
	if id.is_empty():
		return
	if not chapters_resolved.has(id):
		chapters_resolved.append(id)
	# RegionGraph.complete_chapter() emits the signal for a completion so
	# listeners do not receive the same chapter twice.

## Is this chapter started/found?
## Is this chapter completed/resolved?
## How many chapters the player has started.
## How many chapters are completed.
func chapters_completed_count() -> int:
	return chapters_resolved.size()

## Set the current chapter.
func set_current_chapter(id: StringName) -> void:
	current_chapter_id = id

## Get the current chapter id.
## Get the chapter id for a given venture id.
##
## Maps each Venture to its chapter. Used when a Venture is resolved to
## mark the chapter and its region as completed.
func chapter_for_venture(venture_id: StringName) -> StringName:
	# RegionGraph is authoritative for all 47 chapters; the old 10-entry
	# duplicate silently dropped chapters 14-50.
	for id in RegionGraph.chapters.keys():
		var chapter: Dictionary = RegionGraph.chapters[id]
		if StringName(str(chapter.get("venture_id", ""))) == venture_id:
			return StringName(str(id))
	return &""


func region_for_chapter(chapter_id: StringName) -> StringName:
	var chapter: Dictionary = RegionGraph.chapters.get(chapter_id, {})
	return StringName(str(chapter.get("region_id", "")))



# ── Humanity (D4) ───────────────────────────────────────────────────────

## Reduce Humanity. Never goes below 0. Emits the change so the manuscript
## can stain the page edge.
func spend_humanity(amount: int) -> void:
	var before := humanity
	humanity = maxi(0, humanity - amount)
	if humanity != before:
		EventBus.humanity_changed.emit(humanity)


## Restore Humanity. Used by the "cure" quests that drain Locura (D1).
# ── Ending aggregation (GDD.md §12.2) ───────────────────────────────────

## The five tracked variables that decide the ending. Kept in one place so
## the ending logic is testable in isolation.
func ending_variables() -> Dictionary:
	return {
		"books_collected": Biblioteca.collected.size(),
		"quixote_locura": Locura.get_for(&"quixote"),
		"sancho_locura": Locura.get_for(&"sancho"),
		"humanity": humanity,
		# Read Verdict's own state rather than flags nobody writes.
		"verdicts_truth": Verdict.truth_count(),
		"verdicts_force": Verdict.force_count(),
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

	# The real world: both cured, the book shelved. The sad one — but it is
	# not available to someone who spent the campaign hurting innocents
	# (GDD D4: Humanity is a real cost, not a score).
	if q <= 25 and s <= 25 and humanity_now >= 60:
		return &"el_mundo_real"

	# Middle ground: the book wins, partly.
	return &"el_libro_gana"
