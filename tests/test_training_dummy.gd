extends RefCounted
## The training dummy, and the yard it stands in.
##
## The second playtest, in one line: *"For the dodge it is difficult to
## assess if it's fine at this stage without any enemies or space
## limitations."*
##
## A dodge on an open plain is a dash: you cannot tell a good one from a
## bad one, because there is nothing to dodge and nowhere you cannot go.
## So the slice grows a dummy that telegraphs, swings, hurts — and can
## be hit back.
##
## These tests pin the two things that matter for the dodge:
##   1. the swing is TELEGRAPHED, so a character can read it and move;
##   2. the hit is resolved at the moment the arm comes down, so a
##      character who has already moved is not hit.

const SCENE := "res://src/world/slice.tscn"


func suite(t: TestHarness) -> void:
	t.suite("TrainingDummy")

	var tree := Engine.get_main_loop() as SceneTree
	var parent: Node = tree.current_scene if tree != null and tree.current_scene != null else null
	var packed: PackedScene = load(SCENE)
	t.expect_true(packed != null, "slice.tscn should load")
	if packed == null or parent == null:
		return

	var scene: Node = packed.instantiate()
	parent.add_child(scene)

	var dummy: TrainingDummy = scene.get_node_or_null("Yard/TrainingDummy")
	t.expect_true(dummy != null, "the yard should have a dummy in it")
	if dummy == null:
		parent.remove_child(scene)
		scene.free()
		return

	var quixote: CharacterPawn = scene.get_node_or_null("Characters/Quixote")
	t.expect_true(quixote != null, "the slice should have Quixote")

	# ── The yard ───────────────────────────────────────────────────────
	t.test("the yard has walls")
	# The space limit is half of the note. Without it, a dodge is a dash.
	var walls := 0
	var yard: Node = scene.get_node_or_null("Yard")
	if yard != null:
		for child in yard.get_children():
			if child is StaticBody3D:
				walls += 1
	t.expect_eq(walls, 5, "four walls and the two halves of the gate wall")

	t.test("the yard is a bounded space")
	# The dummy stands in the middle of it, and the walls are far enough
	# away that there is room to fight but not room to run.
	var distance := 0.0
	if yard != null:
		var walls_node := yard.get_node_or_null("Wall")
		if walls_node != null:
			distance = walls_node.global_position.distance_to(dummy.global_position)
	t.expect_gt(distance, 5.0, "the dummy is not against the wall")

	# ── The dummy ──────────────────────────────────────────────────────
	t.test("the dummy can be hit")
	dummy.take_damage(20.0)
	t.expect_eq(dummy.health, dummy.max_health - 20.0, "it took the hit")

	t.test("and it can be put back")
	dummy.reset()
	t.expect_eq(dummy.health, dummy.max_health, "reset puts the health back")

	t.test("the swing is telegraphed")
	# The wind-up is the whole reason a dodge is a decision: the player
	# has to be able to see it coming.
	quixote.global_position = dummy.global_position + Vector3(2.0, 0.0, 0.0)
	dummy.state = TrainingDummy.State.IDLE
	dummy.set("_timer", 0.0)
	_step(dummy, 0.05)
	t.expect_eq(dummy.state, TrainingDummy.State.WINDUP, "it winds up before it swings")
	_step(dummy, 0.05)
	t.expect_eq(dummy.state, TrainingDummy.State.WINDUP, "and it stays wound up for a while")

	t.test("the hit lands on whoever is in front of it")
	quixote.global_position = dummy.global_position + Vector3(2.0, 0.0, 0.0)
	quixote.rotation.y = 0.0
	var health := quixote.health
	# Wind up, then let the arm come down.
	_step(dummy, 0.05)
	_step(dummy, 0.9)
	t.expect_true(quixote.health < health, "the blow landed, got %f" % quixote.health)

	t.test("a character who has moved is not hit")
	# The check happens when the arm comes down, not when it went up.
	quixote.health = 100.0
	quixote.global_position = dummy.global_position + Vector3(2.0, 0.0, 0.0)
	dummy.state = TrainingDummy.State.IDLE
	dummy.set("_timer", 0.0)
	_step(dummy, 0.05)
	# The dodge: out of the arc before the arm comes down.
	quixote.global_position = dummy.global_position + Vector3(6.0, 0.0, 0.0)
	var missed := quixote.health
	_step(dummy, 0.9)
	t.expect_eq(quixote.health, missed, "the blow went past")

	t.test("the i-frames are what make the dodge work")
	# The dodge is a burst with 0.4s of invulnerability. That is the
	# number the playtest has to judge.
	quixote.health = 100.0
	quixote.stamina = quixote.max_stamina
	quixote.dodge()
	var before := quixote.health
	quixote.take_damage(20.0)
	t.expect_eq(quixote.health, before, "the blow went past")

	# ── Hitting it back ────────────────────────────────────────────────
	t.test("a light attack lands on the dummy")
	dummy.reset()
	# The dummy faces east, towards the gate. The character stands east
	# of it and faces west, into the dummy.
	quixote.global_position = dummy.global_position + Vector3(1.6, 0.0, 0.0)
	quixote.rotation.y = PI * 0.5
	quixote.stamina = quixote.max_stamina
	quixote._attack_cooldown = 0.0
	var before_health := dummy.health
	quixote.light_attack()
	t.expect_true(quixote.stamina < quixote.max_stamina, "the swing cost stamina")
	# The hitbox is a child of the character, and it lives for a moment.
	var hitbox: AttackHitbox = quixote.get_node_or_null("Hitbox")
	t.expect_true(hitbox != null, "the swing spawned a hitbox")
	if hitbox != null:
		_step(hitbox, 0.05)
		t.expect_true(dummy.health < before_health, "the dummy took the hit")

	t.test("a swing cannot hit the same target twice")
	if hitbox != null:
		var after_first := dummy.health
		_step(hitbox, 0.05)
		t.expect_eq(dummy.health, after_first, "one swing, one hit")

	t.test("the dummy goes down and gets up")
	dummy.take_damage(dummy.max_health * 2.0)
	t.expect_true(dummy.is_down(), "enough damage knocks it down")
	dummy.reset()
	t.expect_false(dummy.is_down(), "and reset gets it back up")
	t.expect_eq(dummy.health, dummy.max_health, "with its health")

	parent.remove_child(scene)
	scene.free()


## Let a node run its own logic for a moment.
func _step(node: Node, seconds: float) -> void:
	node.call("_physics_process", seconds)
