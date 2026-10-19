extends Node
## Madness as a mechanic, not a costume (P2).
##
## Locura is per-character, 0-100, and is the game's central tension.
## Quixote fights better at high Locura; the game constantly tempts you to
## let him break. Sancho's Locura is the DLC 3 axis.
##
## See GDD.md §4.5.

enum Threshold {
	LUCID = 0,       ## 0-25   full access to Reality Truth
	DISPLACED = 1,   ## 26-50  hints get unreliable, minor Book bleed
	LOST = 2,        ## 51-75  the HUD is written by the book
	ABSORBED = 3,    ## 76-100 you play through the madness
}

const MAX_VALUE := 100.0

## Per-character current value.
var _values: Dictionary = {}
## Per-character threshold index, cached so we only emit on change.
var _thresholds: Dictionary = {}


func _ready() -> void:
	# Both characters start with a value. Quixote starts sick on purpose.
	_values[&"quixote"] = 45.0
	_values[&"sancho"] = 0.0
	_thresholds[&"quixote"] = _threshold_for(45.0)
	_thresholds[&"sancho"] = _threshold_for(0.0)


func _threshold_for(value: float) -> int:
	if value >= 76.0:
		return Threshold.ABSORBED
	if value >= 51.0:
		return Threshold.LOST
	if value >= 26.0:
		return Threshold.DISPLACED
	return Threshold.LUCID


func get_for(character_id: StringName) -> float:
	return float(_values.get(character_id, 0.0))


func set_for(character_id: StringName, value: float) -> void:
	var clamped := clampf(value, 0.0, MAX_VALUE)
	var before := get_for(character_id)
	_values[character_id] = clamped
	EventBus.locura_changed.emit(character_id, clamped, threshold_for(character_id))

	var new_threshold := _threshold_for(clamped)
	if new_threshold != int(_thresholds.get(character_id, Threshold.LUCID)):
		_thresholds[character_id] = new_threshold
		EventBus.locura_threshold_crossed.emit(character_id, new_threshold)


func add_for(character_id: StringName, amount: float) -> void:
	set_for(character_id, get_for(character_id) + amount)


## Draining Locura is a real activity: the "cure" quests gather evidence
## that the world is flat. See GDD.md §4.5.
func reduce_for(character_id: StringName, amount: float) -> void:
	set_for(character_id, get_for(character_id) - amount)


func threshold_for(character_id: StringName) -> int:
	return int(_thresholds.get(character_id, Threshold.LUCID))


## Is this character currently able to see Reality Truth at all?
## Quixote can only do so while Lucid — at higher madness the world starts
## agreeing with him.
func can_perceive_reality(character_id: StringName) -> bool:
	if character_id == &"sancho":
		return true
	return threshold_for(character_id) == Threshold.LUCID


## Book-only abilities are gated on this (GDD.md §5.1).
func has_book_access(character_id: StringName) -> bool:
	return threshold_for(character_id) >= Threshold.DISPLACED


## Used by DLC 3: the madness transfers between characters.
func transfer(from_id: StringName, to_id: StringName, amount: float) -> void:
	reduce_for(from_id, amount)
	add_for(to_id, amount)


# ── Save / load ─────────────────────────────────────────────────────────

func save_state() -> Dictionary:
	return {
		"quixote": get_for(&"quixote"),
		"sancho": get_for(&"sancho"),
	}


func load_state(data: Dictionary) -> void:
	set_for(&"quixote", float(data.get("quixote", 45.0)))
	set_for(&"sancho", float(data.get("sancho", 0.0)))
