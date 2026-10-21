extends RefCounted
## The companion in the fight.
##
## The whole combat design of this game is that the player swaps
## mid-fight (GDD.md §7.2): one of the two does the killing and the
## other one does the controlling. That only means something if the
## companion is IN the fight.
##
## So: it fights the target YOU are locked onto, it catches a wind-up on
## its guard, and — because Sancho's buckler parries — it can leave the
## attacker staggered and open.

const SCENE := "res://src/world/slice.tscn"


func suite(t: TestHarness) -> void:
	t.suite("Companion")

	var tree := Engine.get_main_loop() as SceneTree
	var parent: Node = tree.current_scene if tree != null and tree.current_scene != null else null
	var packed: PackedScene = load(SCENE)
	t.expect_true(packed != null, "slice.tscn should load")
	if packed == null or parent == null:
		return

	var scene: Node = packed.instantiate()
	parent.add_child(scene)

	var controller: PlayerController = scene.get_node_or_null("PlayerController")
	var quixote: CharacterPawn = scene.get_node_or_null("Characters/Quixote")
	var sancho: CharacterPawn = scene.get_node_or_null("Characters/Sancho")
	var ai: CompanionAI = scene.get_node_or_null("CompanionAI")
	var dummy: TrainingDummy = scene.get_node_or_null("Yard/TrainingDummy")
	var straw: StrawMan = scene.get_node_or_null("Yard/StrawMan")
	t.expect_true(controller != null and ai != null, "the slice has a player and a companion")
	t.expect_true(dummy != null and straw != null, "the yard has its two targets")
	if controller == null or ai == null or dummy == null or straw == null:
		parent.remove_child(scene)
		scene.free()
		return

	# The player drives Quixote; Sancho is the companion.
	t.expect_eq(controller.active_pawn, quixote, "the player drives Quixote")
	t.expect_eq(ai.pawn, sancho, "and Sancho follows")

	# ── It waits for the first blow ────────────────────────────────────
	t.test("the squire waits for the player to start the fight")
	# The playtest: "right at the start sancho goes directly to an
	# enemy i didn't start a combat against yet — that behaviour would
	# be okay for quijote, but sancho should only fight after quixote
	# delivers or receives the first blow."
	#
	# And it is right. The knight is the front line: he goes in, and the
	# squire covers him. The squire is control, not force.
	quixote.has_engaged = false
	quixote.global_position = dummy.global_position + Vector3(3.0, 0.0, 0.0)
	sancho.global_position = dummy.global_position + Vector3(2.0, 0.0, 0.0)
	_step(ai)
	t.expect_eq(ai.target, null, "he does not walk into a fight nobody started")

	t.test("and he joins once the first blow lands")
	quixote.has_engaged = true
	_step(ai)
	t.expect_eq(ai.target, dummy, "now he is in it")

	# ── It fights what you point at ────────────────────────────────────
	t.test("the companion fights the target the player is locked onto")
	quixote.global_position = dummy.global_position + Vector3(3.0, 0.0, 0.0)
	quixote.set_lock_target(dummy)
	_step(ai)
	t.expect_eq(ai.target, dummy, "it picked up the player's target")
	t.expect_eq(sancho.lock_target, dummy, "and it faces it")

	t.test("and it does not touch the innocent")
	# The straw man is an INNOCENT: a blow on it costs Humanity.
	quixote.set_lock_target(straw)
	_step(ai)
	t.expect_ne(ai.target, straw, "it will not hit the straw man")

	t.test("with nothing locked, it finds the nearest hostile")
	quixote.clear_lock_target()
	sancho.global_position = straw.global_position + Vector3(1.0, 0.0, 0.0)
	_step(ai)
	t.expect_eq(ai.target, dummy, "the dummy is the only hostile left")

	# ── It swings ─────────────────────────────────────────────────────
	t.test("the companion swings at what it is fighting")
	dummy.reset()
	quixote.set_lock_target(dummy)
	sancho.global_position = dummy.global_position + Vector3(1.8, 0.0, 0.0)
	sancho.stamina = sancho.max_stamina
	# The character's own rhythm runs on its own clock, and the step
	# before this one used it.
	sancho._attack_cooldown = 0.0
	var before := dummy.health
	ai._attack_timer = 0.0
	_step(ai)
	t.expect_true(sancho.stamina < sancho.max_stamina, "it spent stamina on a swing")
	# The swing has to reach: the hitbox lives a moment, and it ticks on
	# its own clock, not with the character's.
	for i in 5:
		_step(ai)
		_step_hitboxes(sancho)
	t.expect_true(dummy.health < before, "and the dummy took it")

	t.test("but Sancho's damage is the control, not the killing")
	# §7.2: he cannot meaningfully damage an enemy. He staggers it.
	dummy.reset()
	var sancho_damage := 0.0
	var before2 := dummy.health
	ai._attack_timer = 0.0
	sancho.stamina = sancho.max_stamina
	# The swing before it left the character's own rhythm running, and
	# that clock only ticks with the character's physics.
	sancho._attack_cooldown = 0.0
	_step(ai)
	for i in 5:
		_step(ai)
		_step_hitboxes(sancho)
	sancho_damage = before2 - dummy.health
	t.expect_true(sancho_damage > 0.0, "Sancho's swing lands")
	t.expect_true(sancho_damage < 14.0, "but it is less than Quixote's whole blow")

	# ── It catches the wind-up ────────────────────────────────────────
	t.test("the companion catches a wind-up on its guard")
	dummy.reset()
	dummy.state = TrainingDummy.State.WINDUP
	# A tenth of a second before the blow: the guard has to go up INSIDE
	# the parry window, and the parry window is a quarter of a second.
	dummy.set("_timer", 0.1)
	ai.guard_chance = 1.0
	ai._guard_timer = 0.0
	ai._guard_rolled = 0
	_step(ai)
	t.expect_true(ai._blocking, "the guard is up")

	t.test("a guard raised too early does not parry")
	# The whole point of the timing: a guard raised at the start of the
	# wind-up has already closed its window by the time the blow lands.
	dummy.reset()
	dummy.state = TrainingDummy.State.WINDUP
	dummy.set("_timer", 0.6)
	ai._guard_timer = 0.0
	ai._guard_rolled = 0
	_step(ai)
	t.expect_false(ai._blocking, "the guard stays down while the blow is far off")

	t.test("and a parry leaves the attacker open")
	# Sancho's buckler parries: the blow costs no health and the
	# attacker staggers.
	dummy.reset()
	sancho.health = 100.0
	sancho.stamina = sancho.max_stamina
	sancho.block(true)
	t.expect_true(sancho.can_parry_now(), "the parry window is open")
	dummy.state = TrainingDummy.State.STRIKE
	dummy.call("_land")
	t.expect_eq(sancho.health, 100.0, "the blow did not touch him")
	t.expect_eq(dummy.state, TrainingDummy.State.STAGGER, "and the attacker is open")
	sancho.block(false)

	t.test("the companion goes back to the player when the fight is over")
	quixote.clear_lock_target()
	ai.target = null
	_step(ai)
	t.expect_eq(ai.target, dummy, "it finds the hostile on its own again")

	parent.remove_child(scene)
	scene.free()


## Let the companion run its own logic for a moment.
func _step(ai: CompanionAI) -> void:
	ai._process(0.05)


## Let the swings of a character live out their moment.
##
## A hitbox is a node with its own clock: it lives for a few frames
## after the swing, and it is the only thing that decides whether a
## blow connects.
func _step_hitboxes(pawn: CharacterPawn) -> void:
	for child in pawn.get_children():
		if child is AttackHitbox:
			child._physics_process(0.05)
