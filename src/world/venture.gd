class_name Venture
extends TruthObject
## The Venture of Montiel — the first thing in the game you fight rather
## than look at.
##
## NEXT_STEPS.md §2, task 2.11: *"The windmill Venture — a boss with a
## Book form and a Reality form, different movesets, different rewards.
## Done when: fighting it in each form is a different fight."*
##
## The two forms are the same thing read two ways, which is the whole
## game, and they are two different fights because of it:
##
##   **THE MILL** (Reality) — it does not walk. Its sails turn, and the
##   ground within four metres of the tower is not yours. It topples
##   when you least expect it and takes a long time to get up. A fight
##   of position: come close, hit, and be somewhere else.
##
##   **THE GIANT** (Book) — it walks. It comes to you, and its arm is
##   longer than your roll. It is fast, it hurts more, and it has half
##   the windmill's health. A short, dangerous fight.
##
## And the player has two levers, and they belong to different people:
##
##   **T (Quixote)** turns the world over — and the world's truth IS
##   this thing's truth, so the boss changes with it. The knight picks
##   the shape of the fight, and he is the only one who can.
##
##   **X (Sancho)** strips the Book skin off — and that puts the Venture
##   back into its Reality form for eight seconds, which stops the
##   swing it was in the middle of and leaves it standing still. The
##   squire does not kill. He controls. GDD.md §5.2, §7.2.
##
## The Venture is a fact of the world, not a reading of one: it wears the
## world's truth and not the reader's, so swapping characters does not
## change the fight underneath you. Turning the world over does.

## What it is doing.
enum State {
	DORMANT,   ## it has not noticed you
	APPROACH,  ## it is coming for you
	WINDUP,    ## the tell. THIS is the window to read it.
	STRIKE,    ## the blow
	RECOVER,   ## it is open
	STAGGER,   ## the poise broke. It is reeling, and it is open.
	REVEALED,  ## the skin is off: it is reeling and it is not moving
	DOWN,      ## it is over
}

## The Venture itself: the enemy, its two forms and their movesets.
@export var venture: VentureData
## Who it is, and what may be done to it. It is an enemy: Sancho can
## stagger it and cannot kill it. GDD.md §7.2.
@export var faction: Harm.Faction = Harm.Faction.HOSTILE
## How close you have to be before it notices you.
@export var aggro_radius: float = 15.0
## How long it reels when the poise breaks.
@export var stagger_seconds: float = 1.6
## How long it takes to stop what it was doing when the skin comes off.
@export var reveal_seconds: float = 0.9
## How long the form takes to change, in seconds.
@export var form_seconds: float = 0.35

## How much health it has left.
var health: float = 0.0
## How much poise it has left. A broken poise leaves it open.
var poise: float = 0.0
## The health it started with, in the form it is wearing.
var max_health: float = 0.0
## The poise it can take before it reels.
var max_poise: float = 0.0
## What it is doing right now. Read by the HUD and by the tests.
var state: int = State.DORMANT

var _timer: float = 0.0
## The move it is in the middle of.
var _move: EnemyMoveData = null
## Which move that was, so the next one is not the same one twice.
var _move_index: int = -1
## How long until each move can come out again.
var _cooldowns: Array[float] = []
## The damage the move in progress does. Fixed when the move starts.
var _move_damage: float = 0.0
## The character it is fighting.
var _target: CharacterPawn = null
## Who landed the last blow. The reward goes to them.
var _last_attacker: CharacterPawn = null
## The truth it is wearing.
var _form_layer: int = 0
## True while the Book skin is off. The edge of that is what the
## Desvelar is for.
var _was_revealed: bool = false
## The body, so the tell can be seen.
var _body: Node3D = null


func _ready() -> void:
	super._ready()
	# It is a target: a swing finds it, and the lock-on can pick it.
	add_to_group(AttackHitbox.TARGET_GROUP)
	add_to_group(LockOn.GROUP)
	_build_collider()
	# The form changes faster than an object does: this is a fight, and
	# the body has to be the other shape before the next blow.
	transition_seconds = form_seconds
	_apply_form(current_form_layer(), true, false)


## The two bodies come from the enemy data, not from the reading: the
## Venture's shape belongs to the fight.
func _build_forms() -> void:
	_clear_forms()
	if venture == null or venture.enemy == null:
		return
	var reality := venture.enemy.reality_form
	var book := venture.enemy.book_form
	if reality != null and reality.model_scene != null:
		_reality_form = reality.model_scene.instantiate()
		add_child(_reality_form)
	if book != null and book.model_scene != null:
		_book_form = book.model_scene.instantiate()
		add_child(_book_form)


## The body, so the character cannot walk through it.
func _build_collider() -> void:
	var body := StaticBody3D.new()
	body.name = "Body"
	body.collision_layer = 5
	body.collision_mask = 5
	var collider := CollisionShape3D.new()
	collider.name = "Shape"
	var shape := CapsuleShape3D.new()
	shape.radius = 1.5
	shape.height = 8.0
	collider.shape = shape
	collider.position = Vector3(0.0, 4.0, 0.0)
	body.add_child(collider)
	add_child(body)
	_body = body


## What the HUD and the lock-on marker call it.
func display_name() -> String:
	if venture == null:
		return ""
	return Loc.t(venture.display_name_key)


# ── The truth it wears ──────────────────────────────────────────────────

## The truth the Venture is in right now.
##
## The world's truth, and not the reader's: a Venture is a fact of the
## world, not a reading of one. But when the Book skin is off — Sancho's
## Desvelar — it is the Reality form whatever the world says, for as
## long as the skin is off.
func current_form_layer() -> int:
	if is_revealed():
		return Perception.REALITY
	return TruthLayer.target_layer()


## The form's data in a truth layer.
func form_data_for(layer: int) -> FormData:
	if venture == null or venture.enemy == null:
		return null
	if layer == Perception.BOOK:
		return venture.enemy.book_form
	return venture.enemy.reality_form


## The form it is wearing now.
func current_form() -> FormData:
	return form_data_for(_form_layer)


## Put on a form.
##
## The health carries over as a *proportion*, so a change of form does
## not heal it and does not kill it: the fight keeps its place, and only
## the shape of it changes.
func _apply_form(layer: int, instant: bool = false, interrupt: bool = true) -> void:
	if layer == _form_layer and not instant:
		return
	var ratio := 1.0 if max_health <= 0.0 else clampf(health / max_health, 0.0, 1.0)
	_form_layer = layer
	var form := form_data_for(layer)
	if form == null:
		return
	max_health = form.max_health
	max_poise = form.poise
	health = ratio * max_health
	poise = minf(poise, max_poise)
	_cooldowns.resize(form.moveset.size())
	# The move in progress belongs to the form it came from.
	if interrupt:
		_interrupt()
	# And the body follows the truth.
	set_layer(layer, instant)


## The truth of the world, and the skin coming off, are the two things
## that can change the shape of this fight.
func _process(delta: float) -> void:
	super._process(delta)
	var revealed := is_revealed()
	if revealed and not _was_revealed:
		# The skin came off. Whatever it was doing, it is not doing it
		# now: the squire's verb is a control, and a control that lets
		# the swing finish is not one.
		_interrupt()
	_was_revealed = revealed
	var layer := current_form_layer()
	if layer != _form_layer:
		_apply_form(layer, false, false)
	_pose(delta)


## Stop what you are doing.
func _interrupt() -> void:
	_move = null
	_enter(State.REVEALED, reveal_seconds)


# ── The fight ───────────────────────────────────────────────────────────

func _physics_process(delta: float) -> void:
	_timer = maxf(0.0, _timer - delta)
	_tick_cooldowns(delta)
	if state == State.DOWN:
		return
	if _target == null or _target.is_dead:
		_target = _find_target()
	match state:
		State.DORMANT:
			if _target == null:
				_target = _find_target()
			if _target != null and _distance_to_target() <= aggro_radius:
				_enter(State.APPROACH, 0.0)
		State.APPROACH:
			_face_target(delta)
			_approach(delta)
			_try_move()
		State.WINDUP:
			_face_target(delta * 0.5)
			if _timer <= 0.0:
				_enter(State.STRIKE, _move.strike_seconds if _move != null else 0.1)
				_land()
		State.STRIKE:
			if _timer <= 0.0:
				_enter(State.RECOVER, _move.recover_seconds if _move != null else 0.8)
				_finish_move()
		State.RECOVER:
			# It is open, and it keeps coming. A giant that only walks
			# between its swings is a giant that never arrives.
			_approach(delta)
			if _timer <= 0.0:
				_enter(State.APPROACH, 0.0)
		State.STAGGER:
			if _timer <= 0.0:
				_enter(State.APPROACH, 0.0)
		State.REVEALED:
			if _timer <= 0.0:
				_enter(State.APPROACH, 0.0)


## Change state, and start the clock for it.
func _enter(next: int, seconds: float) -> void:
	state = next
	_timer = seconds


## The move in progress is over: its cooldown starts now.
func _finish_move() -> void:
	if _move != null and _move_index >= 0 and _move_index < _cooldowns.size():
		_cooldowns[_move_index] = _move.cooldown
	_move = null


## The wind-up is over and the cooldown starts.
func _tick_cooldowns(delta: float) -> void:
	for i in range(_cooldowns.size()):
		if _cooldowns[i] > 0.0:
			_cooldowns[i] = maxf(0.0, _cooldowns[i] - delta)


## Pick the next move: the first one that is ready and that can reach,
## starting after the one that was last used.
##
## A Venture has a rhythm, not a dice roll. The player has to be able to
## learn it.
func _try_move() -> void:
	if _target == null:
		return
	var form := current_form()
	if form == null or form.moveset.is_empty():
		return
	var distance := _distance_to_target()
	for offset in range(form.moveset.size()):
		var index := (_move_index + 1 + offset) % form.moveset.size()
		if _cooldowns.size() <= index or _cooldowns[index] > 0.0:
			continue
		var move := form.moveset[index]
		if move == null or distance > move.reach:
			continue
		# A move that is not a ring only comes out when the thing it is
		# aimed at is in front of it. Otherwise the tell is a lie: the
		# player watches a wind-up and the blow goes somewhere else.
		if not move.is_ring() and not _facing_target(move.half_arc()):
			continue
		_start_move(move, index)
		return


## Is the character it is fighting inside the given angle of where it
## is looking?
func _facing_target(half_arc: float) -> bool:
	if _target == null:
		return false
	var forward := -global_transform.basis.z
	forward.y = 0.0
	if forward.length_squared() < 0.0001:
		return false
	var to_target := _target.global_position - global_position
	to_target.y = 0.0
	if to_target.length_squared() < 0.0001:
		return true
	return forward.normalized().angle_to(to_target.normalized()) <= half_arc


## Begin a move: the tell starts now.
func _start_move(move: EnemyMoveData, index: int) -> void:
	_move = move
	_move_index = index
	_move_damage = move.damage * _damage_multiplier()
	_enter(State.WINDUP, move.windup_seconds)


## How hard this form hits.
func _damage_multiplier() -> float:
	var form := current_form()
	return 1.0 if form == null else form.damage_multiplier


## The blow lands.
##
## Everything in the arc takes it, and the check happens NOW, not when
## the wind-up began. That is the whole contract: a character who dodged
## is no longer in the arc, and a swing that is still arriving when the
## damage is resolved reads as a lie.
func _land() -> void:
	if _move == null:
		return
	var origin := global_position
	var forward := -global_transform.basis.z
	forward.y = 0.0
	if forward.length_squared() < 0.0001:
		return
	forward = forward.normalized()
	var half_arc := _move.half_arc()

	for pawn in _pawns():
		var to_pawn := pawn.global_position - origin
		to_pawn.y = 0.0
		var distance := to_pawn.length()
		if distance > _move.reach:
			continue
		if distance > 0.05 and not _move.is_ring():
			var angle := forward.angle_to(to_pawn / distance)
			if angle > half_arc:
				continue
		pawn.take_damage(_move_damage, self, _move.poise_damage)


## Walk towards the player, if this form can walk.
##
## The mill does not. Its fight is not about closing a distance: it is
## about the ground the sails deny, and the tower you have to reach.
func _approach(delta: float) -> void:
	var form := current_form()
	if form == null or form.move_speed <= 0.0 or _target == null:
		return
	var to_target := _target.global_position - global_position
	to_target.y = 0.0
	var distance := to_target.length()
	if distance <= form.engage_distance:
		return
	global_position += to_target.normalized() * form.move_speed * delta


## Turn towards the character it is fighting.
func _face_target(delta: float) -> void:
	if _target == null:
		return
	var form := current_form()
	var speed := 1.5 if form == null else form.turn_speed
	var to_target := _target.global_position - global_position
	to_target.y = 0.0
	if to_target.length_squared() < 0.0001:
		return
	var desired := atan2(-to_target.x, -to_target.z)
	var diff := wrapf(desired - rotation.y, -PI, PI)
	rotation.y += clampf(diff, -speed * delta, speed * delta)


## The pose, in code.
##
## The Venture has no rig and no clips: it is a low-poly model with
## named parts, and the parts move. The tell is the whole point — the
## player has to be able to *learn* to dodge it and to time the
## Desvelar against it — so the wind-up has to be a shape and not a
## number.
##
## Each form tells its own way, and each move tells differently:
##
##   THE MILL — the topple leans the whole tower back and drops it
##   forward (a heavy blow); the sails spin up (a light one).
##
##   THE GIANT — the sweep draws one arm back (a light blow); the slam
##   raises both (a heavy one).
func _pose(delta: float) -> void:
	_pose_mill(delta)
	_pose_giant(delta)


## How far through its wind-up the move is, from 0 to 1.
func _windup_progress() -> float:
	if _move == null or state != State.WINDUP:
		return 0.0
	if _move.windup_seconds <= 0.0:
		return 1.0
	return 1.0 - clampf(_timer / _move.windup_seconds, 0.0, 1.0)


## The mill: the tower leans, and the sails run up before they come round.
func _pose_mill(delta: float) -> void:
	if _reality_form == null:
		return
	var heavy := _move != null and _move.heavy
	var progress := _windup_progress()

	# The tower.
	var lean := 0.0
	var speed := 3.0
	if heavy:
		if state == State.WINDUP:
			lean = -0.42 * progress
		elif state == State.STRIKE:
			lean = 0.55
			speed = 12.0
		elif state == State.RECOVER:
			lean = 0.35
	else:
		lean = -0.08 * progress
	_reality_form.rotation.x = move_toward(_reality_form.rotation.x, lean, speed * delta)

	# The sails. A run-up is the mill's way of saying "this one is
	# coming": the blades speed up before they come round.
	var sails := _reality_form.get_node_or_null("Sails")
	if sails == null:
		return
	var spin := 9.0
	if heavy:
		spin = 26.0
	elif state == State.WINDUP:
		spin = 9.0 + 16.0 * progress
	elif state == State.STRIKE:
		spin = 30.0
	sails.set("degrees_per_second", spin)


## The giant: the arms are the tell, and each blow has its own.
func _pose_giant(delta: float) -> void:
	if _book_form == null:
		return
	var heavy := _move != null and _move.heavy
	var progress := _windup_progress()
	var speed := 4.0

	var back := 0.0
	var both := 0.0
	if state == State.WINDUP:
		if heavy:
			both = -1.55 * progress
		else:
			back = -1.15 * progress
	elif state == State.STRIKE:
		if heavy:
			both = 1.15
		else:
			back = 0.85
		speed = 13.0

	_pose_arm(_book_form.get_node_or_null("ShoulderPivotLeft"), back, both, speed, delta)
	_pose_arm(_book_form.get_node_or_null("ShoulderPivotRight"), back, both, speed, delta)


## One arm: the right one draws back for a sweep, both go up for a slam.
func _pose_arm(pivot: Node, back: float, both: float, speed: float, delta: float) -> void:
	if pivot == null:
		return
	var angle := back + both
	pivot.rotation.x = move_toward(pivot.rotation.x, angle, speed * delta)


# ── Being hit ───────────────────────────────────────────────────────────

## Take a hit. The same interface a character has, so a swing does not
## need to know what it is hitting.
func take_damage(amount: float, source: Node = null, poise_damage: float = 0.0) -> void:
	if state == State.DOWN:
		return
	var attacker := source as CharacterPawn
	if attacker != null:
		_last_attacker = attacker
	# The asymmetry rules. Sancho cannot meaningfully damage an enemy:
	# his blow is scaled down, so he staggers and does not kill.
	var damage := Harm.damage_for(faction, attacker, amount)
	if damage <= 0.0:
		return
	health = maxf(0.0, health - damage)
	if poise_damage > 0.0:
		poise += poise_damage
		if poise >= max_poise:
			poise = 0.0
			stagger()
	if health <= 0.0:
		_die()


## The poise broke. It reels, and for a moment it cannot swing.
func stagger() -> void:
	if state == State.DOWN or state == State.STAGGER:
		return
	# Not every blow is worth catching. A spinning blade is turned aside
	# and the thing keeps coming; a blow that was meant to break a guard
	# is caught and turned back on the arm that threw it.
	if _move != null and not _move.heavy:
		return
	_enter(State.STAGGER, stagger_seconds)
	_move = null


## How far away a companion should stand from this thing.
##
## A training dummy is fought at arm's length. A Venture with turning
## sails is not: standing where the blades go is how a companion dies for
## no reason, and it is the one thing the companion is for.
func safe_distance() -> float:
	var form := current_form()
	if form == null:
		return 0.0
	var distance := form.engage_distance
	for move in form.moveset:
		if move != null and move.is_ring():
			distance = maxf(distance, move.reach + 0.8)
	return distance


## Is this thing about to swing?
##
## The convention every target follows: it says so before it hits. That
## is what makes a parry possible, and a parry is what makes a companion
## worth having.
func is_winding_up() -> bool:
	return state == State.WINDUP


## How long until the blow lands, in seconds.
func time_until_strike() -> float:
	if state != State.WINDUP or _move == null:
		return 99.0
	return _timer


## The move it is winding up, for the HUD.
func current_move() -> EnemyMoveData:
	return _move


## It goes over.
func _die() -> void:
	_enter(State.DOWN, 0.0)
	health = 0.0
	poise = 0.0
	_move = null
	# A thing that is out of the fight is not a target.
	remove_from_group(LockOn.GROUP)
	if _body != null:
		_body.rotation.x = 0.0
	# The truth resolution: if the Venture is defeated while the world is
	# in Book truth, it resolves via TRUTH instead of FORCED — the knight's
	# delusion wins, the giant is real, and the fragment reward is granted.
	# Otherwise it resolves via FORCED — the knight killed a windmill.
	var resolution: int = VentureData.Resolution.FORCED
	if venture != null and venture.allows_truth_resolution and TruthLayer.is_book():
		resolution = VentureData.Resolution.TRUTH
		# Grant the fragment reward: the page of the original book.
		if venture.manifesto_fragments.size() > 0:
			for fragment_id in venture.manifesto_fragments:
				if not GameState.codex_pages.has(fragment_id):
					GameState.codex_pages.append(fragment_id)
					EventBus.codex_page_found.emit(fragment_id)
	# The reward goes to whoever finished it.
	var amount := 0
	if venture != null and venture.enemy != null:
		amount = venture.enemy.recuerdos
	var who := &"quixote"
	if _last_attacker != null:
		who = _last_attacker.character_id
	if amount > 0:
		Memoria.gain(who, amount)
	EventBus.venture_resolved.emit(venture.id if venture != null else &"", resolution)


## Is the Venture down? The HUD says so.
func is_down() -> bool:
	return state == State.DOWN


## Put it back: the Venture stands up, and the morning starts again.
func reset() -> void:
	poise = 0.0
	_move = null
	_move_index = -1
	_cooldowns.clear()
	_target = null
	_last_attacker = null
	_form_layer = current_form_layer()
	var form := form_data_for(_form_layer)
	if form != null:
		max_health = form.max_health
		max_poise = form.poise
		health = max_health
		_cooldowns.resize(form.moveset.size())
	else:
		health = max_health
	if _body != null:
		_body.rotation.x = 0.0
	add_to_group(LockOn.GROUP)
	_enter(State.DORMANT, 0.0)


# ── The company ─────────────────────────────────────────────────────────

## The character it is fighting.
##
## It fights the PLAYER, and not the nearest thing. A boss that turns
## its back on the player to hit the companion is a boss the player is
## not in a fight with — and the companion is the one that has a job
## here anyway: it catches the wind-up, and it controls.
func _find_target() -> CharacterPawn:
	var driven := _driven_pawn()
	if driven != null and not driven.is_dead:
		return driven
	return _nearest_pawn()


## The character the player is driving right now.
func _driven_pawn() -> CharacterPawn:
	var tree := get_tree()
	if tree == null:
		return null
	for node in tree.get_nodes_in_group(PlayerController.GROUP):
		var controller := node as PlayerController
		if controller != null:
			return controller.active_pawn
	return null


## The character closest to the Venture.
func _nearest_pawn() -> CharacterPawn:
	var best: CharacterPawn = null
	var best_distance := INF
	for pawn in _pawns():
		var distance := pawn.global_position.distance_to(global_position)
		if distance < best_distance:
			best_distance = distance
			best = pawn
	return best


func _distance_to_target() -> float:
	if _target == null:
		return INF
	var to_target := _target.global_position - global_position
	to_target.y = 0.0
	return to_target.length()


func _pawns() -> Array[CharacterPawn]:
	var out: Array[CharacterPawn] = []
	var tree := get_tree()
	if tree == null:
		return out
	for node in tree.get_nodes_in_group(&"pawns"):
		var pawn := node as CharacterPawn
		if pawn != null and not pawn.is_dead:
			out.append(pawn)
	return out
