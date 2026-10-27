extends RefCounted
const TestHarness = preload("res://tests/test_harness.gd")
const Perception = preload("res://src/systems/perception.gd")
## The asymmetry rules, and the verb that came with them.
##
## GDD.md §7.2 and D4. These are the rules that make the two characters
## un-stackable, and they are the reason the player swaps mid-fight:
##
## 1. **Quixote cannot harm innocents.** The blow does not land, and it
##    costs Humanity.
## 2. **Sancho cannot meaningfully damage enemies.** His damage is
##    scaled down; his poise is not. He staggers, he does not kill.
##
## And **Desvelar** (GDD.md §5.2), Sancho's verb: a line that strips the
## "Book skin" off a thing, for eight seconds, for both characters.

const SCENE = "res://src/world/slice.tscn"


func suite(t):
	t.suite("Asymmetry")

	var tree = Engine.get_main_loop() as SceneTree
	var parent = tree.current_scene if tree != null and tree.current_scene != null else null
	var packed = load(SCENE)
	t.expect_true(packed != null, "slice.tscn should load")
	if packed == null or parent == null:
		return

	var scene = packed.instantiate()
	parent.add_child(scene)

	var controller = scene.get_node_or_null("PlayerController")
	var quixote = scene.get_node_or_null("Characters/Quixote")
	var sancho = scene.get_node_or_null("Characters/Sancho")
	var dummy = scene.get_node_or_null("Yard/TrainingDummy")
	var straw = scene.get_node_or_null("Yard/StrawMan")
	t.expect_true(controller != null and quixote != null and sancho != null,
		"the slice has the two of them")
	t.expect_true(dummy != null, "the yard has a dummy")
	t.expect_true(straw != null, "the yard has a straw man")
	if controller == null or quixote == null or sancho == null or dummy == null or straw == null:
		parent.remove_child(scene)
		scene.free()
		return

	var humanity = GameState.humanity

	# ── The innocent ───────────────────────────────────────────────────
	t.test("Quixote cannot harm the innocent")
	# The straw man stands there. Quixote's blow does not land, and it
	# costs him twenty of his Humanity.
	GameState.humanity = 100
	var straw_health = straw.health
	quixote.take_damage(0.0)  # keep the harness honest about the order
	straw.take_damage(20.0, quixote)
	t.expect_eq(straw.health, straw_health, "the blow did not land")
	t.expect_eq(GameState.humanity, 80, "and it cost him twenty Humanity")

	t.test("Sancho can, and it costs him less")
	# He is a practical man with a sack and no chivalry to wound, so the
	# straw comes down — but the world is not a place where that is free.
	GameState.humanity = 100
	straw.reset()
	straw.take_damage(20.0, sancho)
	t.expect_true(straw.health < straw.max_health, "the straw came down")
	t.expect_eq(GameState.humanity, 95, "and it cost him five")

	t.test("and the rule is in the data, not in the code")
	t.expect_false(quixote.data.can_harm_innocents, "Quixote cannot harm innocents")
	t.expect_true(sancho.data.can_harm_innocents, "Sancho can")
	t.expect_gt(quixote.data.innocent_humanity_cost, sancho.data.innocent_humanity_cost,
		"and the knight's conscience is the expensive part")

	# ── The enemy ──────────────────────────────────────────────────────
	t.test("Sancho cannot meaningfully damage an enemy")
	# His kit is control. The same blow leaves it reeling, not dead.
	dummy.reset()
	dummy.take_damage(20.0, quixote)
	var quixote_damage = dummy.max_health - dummy.health
	dummy.reset()
	dummy.take_damage(20.0, sancho)
	var sancho_damage = dummy.max_health - dummy.health
	t.expect_true(quixote_damage > sancho_damage, "the knight kills it, the squire does not")
	t.expect_almost_eq(float(quixote_damage), 20.0, 0.01, "Quixote's blow is whole")
	t.expect_true(sancho_damage > 0.0, "but Sancho's is not nothing")
	t.expect_true(sancho_damage < quixote_damage, "and it is less")

	t.test("and the poise is not scaled")
	# He staggers it; he does not kill it. That is the whole of his kit.
	dummy.reset()
	dummy.poise = 0.0
	dummy.take_damage(1.0, sancho, 20.0)
	t.expect_almost_eq(dummy.poise, 20.0, 0.01, "the poise damage is whole")

	# ── The Desvelar ───────────────────────────────────────────────────
	t.test("Desvelar strips the Book skin off a thing")
	# A book in a rock, in the Book layer. Sancho unveils it, and for
	# eight seconds it is a stone — for both of them.
	TruthLayer.shift_to(TruthLayer.Layer.BOOK, true)
	Locura.set_for(&"quixote", 10.0)
	var rock = scene.get_node_or_null("Rock")
	t.expect_true(rock != null, "the slice has a rock")
	if rock != null:
		controller.request_swap()  # Sancho is driving
		t.expect_eq(controller.active_pawn, sancho, "Sancho has the wheel")

		# Put him in front of the rock, facing it.
		sancho.global_position = Vector3(11.0, 0.0, -9.0)
		sancho.rotation.y = 0.0
		controller.call("_update_examine_target", 1.0)
		sancho.stamina = sancho.max_stamina

		var press = InputEventAction.new()
		press.action = &"desvelar"
		press.pressed = true
		controller._unhandled_input(press)

		t.expect_true(rock.is_revealed(), "the Book skin is off")
		t.expect_eq(rock.name_key_for(Perception.BOOK), &"ui.form.roca",
			"and everybody calls it a stone now")

	t.test("and it wears off")
	if rock != null:
		for i in 400:
			rock.call("_process", 0.05)
		t.expect_false(rock.is_revealed(), "the skin is back on")

	GameState.humanity = humanity
	TruthLayer.shift_to(TruthLayer.Layer.REALITY, true)
	Locura.set_for(&"quixote", 10.0)
	TruthLayer.set_view_layer(-1)
	parent.remove_child(scene)
	scene.free()
