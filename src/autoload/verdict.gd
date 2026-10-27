class_name Verdict
extends Node
## Verdict system - the investigation mechanic's resolution.
##
## A "Verdict" is a scripted moment where the world changes layer. It is the
## game's equivalent of a boss mechanic, and it is how quests resolve.
##
## Two characters, two ways to resolve:
##
## - **Quixote's Verdict** — he *insists*. He reenacts a scene from the book at
##   the location (a theatre, a ritual, a speech). The world obliges. Effects:
##   enemies become their Book selves (much stronger, but their patterns are now
##   readable from the novel), new paths open, a codex page is written. Cost:
##   Quixote's Locura rises.
##
## - **Sancho's Verdict** — he *refutes*. He says the plain truth out loud, or
##   produces a piece of evidence. The world drops back to Reality. Effects:
##   illusions break, false nobles are exposed, hidden loot appears, the "real"
##   solution to a Venture unlocks. Cost: he loses the Book's help; some doors
##   only exist in Book Truth stay shut.
##
## Both are needed. A chapter's boss usually has a Reality solution (kill it)
## and a Book solution (solve the case). The Book solution is faster but raises
## Locura and can *unlock a worse ending*.

## How much Locura Quixote gains when he insists (Verdict by truth).
const LOCURA_COST_QUIXOTE = 20

## How much Locura Sancho loses when he refutes (Verdict by force).
## Sancho gains clarity when he speaks the truth.
const LOCURA_GAIN_SANCHO = -15

## How much Locura Quixote loses when he refutes (rare, but possible).
const LOCURA_GAIN_QUIXOTE_REFUTE = -10

## How much Locura Sancho gains when he insists (rare, but possible).
const LOCURA_GAIN_SANCHO_INSIST = 25

## Verdict resolution modes.
const VERDICT_NONE = 0
const VERDICT_TRUTH = 1    ## Quixote insisted, world became Book
const VERDICT_FORCE = 2    ## Sancho refuted, world became Reality

## Per-verdict resolution state. Maps fragment_id -> verdict mode.
static var _verdicts: Dictionary = {}

## Whether a verdict has been resolved for this id.
static func is_resolved(id: StringName) -> bool:
	return _verdicts.has(id) && _verdicts[id] != VERDICT_NONE

## The resolution mode for a fragment id, or VERDICT_NONE if not resolved.
static func verdict_mode(id: StringName) -> int:
	return _verdicts.get(id, VERDICT_NONE)

## How many verdicts have been resolved by truth.
static func truth_count() -> int:
	var count := 0
	for mode in _verdicts.values():
		if mode == VERDICT_TRUTH:
			count += 1
	return count

## How many verdicts have been resolved by force.
static func force_count() -> int:
	var count := 0
	for mode in _verdicts.values():
		if mode == VERDICT_FORCE:
			count += 1
	return count

## Total number of resolved verdicts.
static func total_count() -> int:
	return _verdicts.size()

## Quixote's Verdict - he *insists*. He reenacts a scene from the book at the
## location. The world obliges and shifts to Book Truth. Cost: Quixote's Locura
## rises.
##
## Returns the verdict mode that was applied, or VERDICT_NONE if already
## resolved.
static func verdict_by_truth(id: StringName) -> int:
	if is_resolved(id):
		return _verdicts[id]

	_verdicts[id] = VERDICT_TRUTH
	Locura.add_for(&"quixote", LOCURA_COST_QUIXOTE)
	EventBus.verdict_resolved.emit(id, VERDICT_TRUTH)
	return VERDICT_TRUTH

## Sancho's Verdict - he *refutes*. He says the plain truth out loud, or
## produces a piece of evidence. The world drops back to Reality. Cost: he
## loses the Book's help; some doors only exist in Book Truth stay shut.
##
## Returns the verdict mode that was applied, or VERDICT_NONE if already
## resolved.
static func verdict_by_force(id: StringName) -> int:
	if is_resolved(id):
		return _verdicts[id]

	_verdicts[id] = VERDICT_FORCE
	Locura.add_for(&"sancho", LOCURA_GAIN_SANCHO)
	EventBus.verdict_resolved.emit(id, VERDICT_FORCE)
	return VERDICT_FORCE

## Resolve a verdict for a specific character. Quixote always resolves by
## truth; Sancho always resolves by force.
##
## Returns the verdict mode that was applied, or VERDICT_NONE if already
## resolved.
static func resolve(character_id: StringName, id: StringName) -> int:
	if is_resolved(id):
		return _verdicts[id]

	if character_id == &"quixote":
		return verdict_by_truth(id)
	elif character_id == &"sancho":
		return verdict_by_force(id)
	else:
		return VERDICT_NONE

	_spotted[id] = true  # Resolving implies spotting
	return _verdicts[id]

## Save / load ─────────────────────────────────────────────────────────

static func save_state() -> Dictionary:
	var out: Dictionary = {}
	for id in _verdicts.keys():
		out[id] = _verdicts[id]
	return out


static func load_state(data: Dictionary) -> void:
	_verdicts = {}
	if data != null:
		for id in data.keys():
			_verdicts[id] = int(data[id])
