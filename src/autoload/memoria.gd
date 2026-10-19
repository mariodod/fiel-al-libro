extends Node
## Progression — "Recuerdos" (memories) and the milestone unlocks.
##
## Level-ups are NOT stat picks. They are new verbs, and critically new
## things you are able to NOTICE: a new kind of anamorphosis becomes
## visible. Progression is perception, not damage numbers. This is the
## strongest anti-grind argument in the design.
##
## See GDD.md §8.1.

const MILESTONES_PER_CHARACTER := 8

## Memory thresholds. Each one unlocks a verb.
const MILESTONE_COSTS: Array[int] = [1, 2, 3, 4, 6, 8, 11, 15]

var _recuerdos: Dictionary = {}
var _milestones: Dictionary = {}


func _ready() -> void:
	_recuerdos[&"quixote"] = 0
	_recuerdos[&"sancho"] = 0
	_milestones[&"quixote"] = 0
	_milestones[&"sancho"] = 0


func get_for(character_id: StringName) -> int:
	return int(_recuerdos.get(character_id, 0))


func milestone_for(character_id: StringName) -> int:
	return int(_milestones.get(character_id, 0))


## Grant memories. Reading an anamorphosis is worth double — that is the
## design's way of making investigation the most efficient way to level,
## without ever making combat pointless.
func gain(character_id: StringName, amount: int, is_reading: bool = false) -> void:
	var total := amount * 2 if is_reading else amount
	_recuerdos[character_id] = get_for(character_id) + total
	EventBus.recuerdos_gained.emit(character_id, total)
	_check_milestones(character_id)


func _check_milestones(character_id: StringName) -> void:
	var current := get_for(character_id)
	var index := milestone_for(character_id)
	while index < MILESTONE_COSTS.size() and current >= MILESTONE_COSTS[index]:
		index += 1
		EventBus.milestone_reached.emit(character_id, index)
	_milestones[character_id] = index


## Has this character unlocked the milestone at this index?
func has_milestone(character_id: StringName, index: int) -> bool:
	return milestone_for(character_id) >= index


# ── Save / load ─────────────────────────────────────────────────────────

func save_state() -> Dictionary:
	return {
		"quixote": _recuerdos.get(&"quixote", 0),
		"sancho": _recuerdos.get(&"sancho", 0),
		"m_quixote": _milestones.get(&"quixote", 0),
		"m_sancho": _milestones.get(&"sancho", 0),
	}


func load_state(data: Dictionary) -> void:
	_recuerdos[&"quixote"] = int(data.get("quixote", 0))
	_recuerdos[&"sancho"] = int(data.get("sancho", 0))
	_milestones[&"quixote"] = int(data.get("m_quixote", 0))
	_milestones[&"sancho"] = int(data.get("m_sancho", 0))
