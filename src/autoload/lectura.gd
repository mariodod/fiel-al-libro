extends Node
## Lectura mode: the investigation mode of the game.
##
## The player enters Lectura with Q. In this mode:
## - The world takes on an investigative tint (handled by the shader)
## - Anamorphoses (hidden details on objects) become spottable
## - Collecting evidence from resolved anamorphoses builds toward a Verdict
##
## The Examine verb (B6) tells you what one character sees of one thing.
## Lectura makes the seams visible across the world: the detail that does
## not add up, on every object that has one, at a glance.
##
## See GDD.md §6 (the Lectura investigation mechanic) and 2.12-2.13.

## How much evidence a single resolved anamorphosis grants.
const EVIDENCE_PER_ANAMORPHOSIS := 1

## How much evidence is needed to unlock a Verdict (2.15).
const EVIDENCE_FOR_VERDICT := 3

## Whether Lectura mode is currently active.
static var _active: bool = false

## Anamorphosis ids the player has spotted (noticed the tell).
static var _spotted: Dictionary = {}

## Anamorphosis ids the player has resolved (understood the detail).
static var _resolved: Dictionary = {}

## Evidence gathered per anamorphosis id.
static var _evidence: Dictionary = {}

## Total evidence collected across all resolved anamorphoses.
static var _total_evidence: int = 0


## Whether Lectura mode is active.
static func is_active() -> bool:
	return _active


## Enter Lectura mode. Emits lectura_entered.
static func enter() -> void:
	if _active:
		return
	_active = true
	EventBus.lectura_entered.emit()


## Exit Lectura mode. Emits lectura_exited.
static func exit() -> void:
	if not _active:
		return
	_active = false
	EventBus.lectura_exited.emit()


## Toggle Lectura mode.
static func toggle() -> void:
	if _active:
		exit()
	else:
		enter()


## Whether an anamorphosis has been spotted (the player noticed its tell).
static func is_spotted(id: StringName) -> bool:
	return bool(_spotted.get(id, false))


## Mark an anamorphosis as spotted. Emits anamorphosis_spotted.
static func spot(id: StringName) -> void:
	if _spotted.get(id, false):
		return
	_spotted[id] = true
	EventBus.anamorphosis_spotted.emit(id)


## Whether an anamorphosis has been resolved (the player understood it).
static func is_resolved(id: StringName) -> bool:
	return bool(_resolved.get(id, false))


## Resolve an anamorphosis and collect its evidence.
##
## Returns the evidence gained (0 if already resolved).
static func resolve(id: StringName, evidence: int = EVIDENCE_PER_ANAMORPHOSIS) -> int:
	if _resolved.get(id, false):
		return 0
	_resolved[id] = true
	_evidence[id] = evidence
	_total_evidence += evidence
	EventBus.anamorphosis_resolved.emit(id)
	EventBus.evidence_collected.emit(id, _total_evidence)
	return evidence


## Total evidence collected so far.
static func total_evidence() -> int:
	return _total_evidence


## Whether enough evidence has been collected for a Verdict.
static func has_enough_for_verdict() -> bool:
	return _total_evidence >= EVIDENCE_FOR_VERDICT


## The number of anamorphoses resolved.
static func resolved_count() -> int:
	return _resolved.size()


## The number of anamorphoses spotted.
static func spotted_count() -> int:
	return _spotted.size()


## Save / load ─────────────────────────────────────────────────────────

func save_state() -> Dictionary:
	return {
		"spotted": _spotted,
		"resolved": _resolved,
		"evidence": _evidence,
		"total_evidence": _total_evidence,
	}


func load_state(data: Dictionary) -> void:
	_spotted = data.get("spotted", {})
	_resolved = data.get("resolved", {})
	_evidence = data.get("evidence", {})
	_total_evidence = int(data.get("total_evidence", 0))
