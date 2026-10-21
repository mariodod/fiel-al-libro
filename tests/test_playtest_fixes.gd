extends RefCounted
## The second playtest, 21 October 2026, and what it found.
##
## Seven things the playtest named, and the rule behind each one:
##
##   1. locking on and pressing forward moved you BACKWARDS (and left and
##      right were inverted too) — the input signs were the wrong way
##      round;
##   2. walking backwards without a lock spun the camera for ever — the
##      character turned round to walk backwards, and the camera followed
##      it round, and the two of them chased each other;
##   3. the dodge left the ground — the hips were keyed two and four
##      metres in the air;
##   4. a character on zero health could still be moved — the corpse
##      kept its last velocity and slid;
##   5. the companion should be able to pick you up;
##   6. when both of them are down, the game is over and it starts again;
##   7. the truth is the knight's alone: T does nothing for Sancho.

const SCENE := "res://src/world/slice.tscn"


func suite(t: TestHarness) -> void:
	t.suite("PlaytestFixes")

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
	t.expect_true(controller != null and quixote != null and sancho != null, "the slice has the two of them")
	if controller == null or quixote == null or sancho == null or ai == null:
		parent.remove_child(scene)
		scene.free()
		return

	# ── 7. The truth is the knight's alone ─────────────────────────────
	t.test("T does nothing for Sancho")
	# "Pressing T with sancho should do nothing. It's a quijote
	# exclusive ability."
	TruthLayer.shift_to(TruthLayer.Layer.REALITY, true)
	controller.active_pawn = sancho
	controller.other_pawn = quixote
	var press := InputEventAction.new()
	press.action = &"toggle_truth"
	press.pressed = true
	scene.call("_unhandled_input", press)
	t.expect_eq(TruthLayer.target_layer(), 0, "the world did not turn over")

	t.test("and T turns the world over for Quixote")
	controller.active_pawn = quixote
	controller.other_pawn = sancho
	scene.call("_unhandled_input", press)
	t.expect_eq(TruthLayer.target_layer(), 1, "the knight's delusion holds")
	TruthLayer.shift_to(TruthLayer.Layer.REALITY, true)

	# ── 4. A character on zero health stays down ──────────────────────
	t.test("a character who is down stays down")
	# "When you have 0 hp you can still move it, you shouldn't be able to
	# do that."
	quixote.health = 0.0
	quixote.take_damage(1.0)
	t.expect_true(quixote.is_dead, "they are down")
	quixote.velocity = Vector3(0.0, 0.0, 6.0)
	var before := quixote.global_position
	for i in 10:
		quixote._physics_process(0.05)
	t.expect_almost_eq(Vector2(quixote.velocity.x, quixote.velocity.z).length(), 0.0, 0.01,
		"the body has stopped")
	t.expect_almost_eq(
		Vector2(quixote.global_position.x - before.x, quixote.global_position.z - before.z).length(),
		0.0, 0.05, "and it has not slid away")
	quixote.revive()

	# ── 5. The companion picks the player up ───────────────────────────
	t.test("the companion picks the player up")
	# "Your partner could help lift you."
	quixote.health = 0.0
	quixote.take_damage(1.0)
	t.expect_true(quixote.is_dead, "the player is down")
	sancho.global_position = quixote.global_position + Vector3(1.0, 0.0, 0.0)
	for i in 60:
		ai._process(0.05)
	t.expect_false(quixote.is_dead, "the companion got them up again")
	quixote.revive()

	# ── 6. Both down: the game is over ────────────────────────────────
	t.test("when both are down the game starts again")
	quixote.health = 0.0
	quixote.take_damage(1.0)
	sancho.health = 0.0
	sancho.take_damage(1.0)
	t.expect_true(quixote.is_dead and sancho.is_dead, "both of them are down")
	scene.call("_update_game_over")
	t.expect_false(quixote.is_dead, "the game starts again")
	t.expect_false(sancho.is_dead, "both of them")
	t.expect_almost_eq(quixote.global_position.distance_to(Vector3(0.0, 0.0, 0.0)), 0.0, 0.5,
		"and they are back at the start")

	parent.remove_child(scene)
	scene.free()
