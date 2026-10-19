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

# ── Manuscript ──────────────────────────────────────────────────────────
## Ids of the 48 Manifiesto fragments the player has found (D7).
var codex_pages: Array[StringName] = []
## Ids of the pages the game has written for the player (D4/P4).
var pages_written: Array[StringName] = []

# ── Endings ─────────────────────────────────────────────────────────────
var ending_id: StringName = &""
## True once the player has staged the Ensayo and been "caught" (D5).
var author_revealed: bool = false


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
