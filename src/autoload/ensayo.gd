extends Node
## El Ensayo — the player-staged case (GDD.md §6.5).
##
## One chapter has no combat: the player stages a test of trust between
## two characters and lives with the outcome. Reuses Verdict scaffolding
## as a data-driven system (D5).
##
## See NEXT_STEPS.md §3.2 and GDD.md §6.5.

## The four setup sliders.
@export var tested_options: Array[StringName] = ["quixote", "sancho"]
@export var examiner_options: Array[StringName] = ["quixote", "sancho"]
@export var secret_options: Array[StringName] = ["wife_name", "treasure", "truth"]
@export var told_options: Array[StringName] = ["tested", "examiner", "neither"]

## The five-six outcomes.
enum Outcome {
	TEST_HELD,       # The tested stays loyal; quest line opens in Region V
	TEST_BROKEN,     # Betrayal; tested kills self; Humanity −20
	EXAMINER_BROKEN, # Examiner becomes the Impertinent recurring NPC
	NOTHING_HAPPENS, # Anticlimax; honest ending, codex page
	PLAYER_CAUGHT,   # Player revealed as author; unlocks El Manuscrito ending
	REFUSED,         # Player walks away; gap in manuscript on shelf
}

## Current state.
var state: String = "setup"   # setup | simulation | consequence
var setup: Dictionary = {}    # tested, examiner, secret, told
var interventions: Array[Dictionary] = []  # Each: {round, round_num, type, text, target}
var current_round: int = 0
var max_rounds: int = 5
var current_outcome: Outcome = Outcome.TEST_HELD
var outcome_reasons: Array[String] = []

## AI motives for the non-player character.
var motive_options: Array[StringName] = [
	"curiosity", "jealousy", "love", "need_to_be_important",
	"need_to_be_right", "fear_of_foolishness"
]

## Start Phase 1 setup with the given configuration.
func start_setup(tested: StringName, examiner: StringName, secret: StringName, told: StringName) -> void:
	state = "setup"
	setup = {
		"tested": tested,
		"examiner": examiner,
		"secret": secret,
		"told": told,
	}
	interventions = []
	current_round = 0
	EventBus.ensayo_setup_started.emit(setup)

## Begin the simulation phase with the given setup.
func start_simulation(tested: StringName, examiner: StringName, secret: StringName, told: StringName) -> void:
	state = "simulation"
	setup = {
		"tested": tested,
		"examiner": examiner,
		"secret": secret,
		"told": told,
	}
	interventions = []
	current_round = 1
	EventBus.ensayo_simulation_started.emit(setup, current_round)

## Record a player intervention during a round.
func add_intervention(intervention_type: String, text: String = "", target: StringName = &"") -> void:
	if state != "simulation":
		return
	var intervention: Dictionary = {
		"round": current_round,
		"type": intervention_type,   # dialogue, warning, look, letter
		"text": text,
		"target": target,
	}
	interventions.append(intervention)
	EventBus.ensayo_intervention.emit(intervention)

## Advance to the next round.
func next_round() -> void:
	current_round += 1
	if current_round > max_rounds:
		resolve_consequence()
	else:
		EventBus.ensayo_round_started.emit(current_round)

## Resolve the Ensayo from setup + interventions.
func resolve_consequence() -> void:
	state = "consequence"
	current_outcome = _determine_outcome()
	EventBus.ensayo_resolved.emit(current_outcome, _outcome_reasons())
	EventBus.ensayo_consequence.emit(current_outcome)
	apply_outcome(current_outcome)

## Internal: determine outcome from setup + interventions.
func _determine_outcome() -> Outcome:
	## Base probabilities weighted by setup choices.
	var truth_weight: float = 0.0   # favors TEST_HELD / NOTHING_HAPPENS
	var force_weight: float = 0.0   # favors TEST_BROKEN / EXAMINER_BROKEN
	var madness_weight: float = 0.0 # favors EXAMINER_BROKEN / PLAYER_CAUGHT

	## Setup-based weighting.
	var tested: StringName = setup.get("tested", &"")
	var examiner: StringName = setup.get("examiner", &"")
	var secret: StringName = setup.get("secret", &"")
	var told: StringName = setup.get("told", &"")

	if tested == &"quixote":
		madness_weight += 0.2  # Quixote is already mad
	if tested == &"sancho" and examiner == &"quixote":
		force_weight += 0.2    # Sancho testing Quixote is confrontational
	if secret == &"truth":
		truth_weight += 0.2    # Truth as the secret is volatile
	if told == &"neither":
		force_weight += 0.1    # Keeping secrets is dangerous
	if told == &"tested":
		truth_weight += 0.1    # Telling the tested builds trust

	## Intervention weighting.
	for intervention in interventions:
		var itype: String = str(intervention.get("type", ""))
		if itype == "warning":
			truth_weight += 0.1   # Warnings build trust
		elif itype == "letter":
			force_weight += 0.1   # Letters are evidence, can be used against
		elif itype == "look":
			madness_weight += 0.05  # Ambiguous
		elif itype == "dialogue":
			truth_weight += 0.05   # Dialogue builds understanding

	## Locura weighting.
	var quixote_locura: float = 0.0
	var sancho_locura: float = 0.0
	# Note: we can't easily access Locura from here without circular deps;
	# use GameState flags instead.
	var locura_quixote: float = float(GameState.get_flag("quixote_locura", 0.0))
	var locura_sancho: float = float(GameState.get_flag("sancho_locura", 0.0))
	madness_weight += (quixote_locura + sancho_locura) * 0.001

	## Normalize and pick. All weights are raw (not divided by total),
	## and roll is compared against each weight directly.
	var total: float = truth_weight + force_weight + madness_weight + 1.0 + 0.15 + 0.10
	var roll: float = randf() * total

	if roll < truth_weight:
		return Outcome.TEST_HELD
	roll -= truth_weight
	if roll < force_weight:
		return Outcome.TEST_BROKEN
	roll -= force_weight
	if roll < madness_weight:
		return Outcome.EXAMINER_BROKEN
	roll -= madness_weight
	if roll < 1.0:  # base weight -> REFUSED
		return Outcome.REFUSED
	roll -= 1.0
	if roll < 0.15:  # base anticlimax chance
		return Outcome.NOTHING_HAPPENS
	roll -= 0.15
	if roll < 0.10:  # base caught chance
		return Outcome.PLAYER_CAUGHT
	return Outcome.REFUSED  # unreachable fallback

## Get human-readable outcome reasons.
func _outcome_reasons() -> Array[String]:
	var reasons: Array[String] = []
	var setup_desc: String = "Tested: %s, Examiner: %s, Secret: %s, Told: %s" % [
		setup.get("tested", &""), setup.get("examiner", &""),
		setup.get("secret", &""), setup.get("told", &"")
	]
	reasons.append(setup_desc)
	reasons.append("Interventions: %d" % interventions.size())
	return reasons

## Get outcome display name key.
func outcome_name_key(outcome: Outcome) -> StringName:
	match outcome:
		Outcome.TEST_HELD: return &"ensayo.outcome.holds"
		Outcome.TEST_BROKEN: return &"ensayo.outcome.breaks"
		Outcome.EXAMINER_BROKEN: return &"ensayo.outcome.examiner_breaks"
		Outcome.NOTHING_HAPPENS: return &"ensayo.outcome.nothing"
		Outcome.PLAYER_CAUGHT: return &"ensayo.outcome.caught"
		Outcome.REFUSED: return &"ensayo.outcome.refuses"
	return &"ensayo.outcome.holds"

## Get outcome description key.
func outcome_desc_key(outcome: Outcome) -> StringName:
	match outcome:
		Outcome.TEST_HELD: return &"ensayo.outcome.holds_desc"
		Outcome.TEST_BROKEN: return &"ensayo.outcome.breaks_desc"
		Outcome.EXAMINER_BROKEN: return &"ensayo.outcome.examiner_breaks_desc"
		Outcome.NOTHING_HAPPENS: return &"ensayo.outcome.nothing_desc"
		Outcome.PLAYER_CAUGHT: return &"ensayo.outcome.caught_desc"
		Outcome.REFUSED: return &"ensayo.outcome.refuses_desc"
	return &"ensayo.outcome.holds_desc"

## Apply outcome effects to game state.
func apply_outcome(outcome: Outcome) -> void:
	match outcome:
		Outcome.TEST_HELD:
			## Quest line opens in Region V castle.
			GameState.set_flag("ensayo_quest_unlocked", true)
			EventBus.ensayo_outcome_holds.emit()
		Outcome.TEST_BROKEN:
			GameState.spend_humanity(20)
			EventBus.ensayo_outcome_broken.emit()
		Outcome.EXAMINER_BROKEN:
			GameState.set_flag("impertinent_active", true)
			EventBus.ensayo_outcome_examiner_broken.emit()
		Outcome.NOTHING_HAPPENS:
			EventBus.ensayo_outcome_nothing.emit()
		Outcome.PLAYER_CAUGHT:
			GameState.set_flag("author_revealed", true)
			EventBus.ensayo_outcome_caught.emit()
		Outcome.REFUSED:
			GameState.set_flag("ensayo_refused", true)
			EventBus.ensayo_outcome_refused.emit()

## Get the current outcome.
func get_outcome() -> Outcome:
	return current_outcome

## Get the setup dictionary.
func get_setup() -> Dictionary:
	return setup.duplicate()

## Get interventions.
func get_interventions() -> Array[Dictionary]:
	return interventions.duplicate()

## Check if in setup phase.
func is_in_setup() -> bool:
	return state == "setup"

## Check if in simulation phase.
func is_in_simulation() -> bool:
	return state == "simulation"

## Check if in consequence phase.
func is_in_consequence() -> bool:
	return state == "consequence"