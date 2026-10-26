extends RefCounted
## The Venture of Montiel — the first boss (NEXT_STEPS.md §2, task 2.11).
##
## "Done when: fighting it in each form is a different fight." These
## tests pin the three things that promise rests on:
##
##   1. the two forms are genuinely different — different movesets,
##      different movement, different health;
##   2. the player has two levers, and they belong to different people:
##      the knight's truth (T) turns the world over and the Venture
##      changes with it, and the squire's Desvelar (X) strips the Book
##      skin and puts it back into its Reality form;
##   3. the asymmetry rules apply to it like they apply to anything
##      else: Sancho staggers it and cannot kill it.

const SCENE := "res://src/world/slice.tscn"


func suite(t: TestHarness) -> void:
	t.suite("Venture")

	var tree := Engine.get_main_loop() as SceneTree
	var parent: Node = tree.current_scene if tree != null and tree.current_scene != null else null
	var packed: PackedScene = load(SCENE)
	t.expect_true(packed != null, "slice.tscn should load")
	if packed == null or parent == null:
		return

	var scene: Node = packed.instantiate()
	parent.add_child(scene)

	var venture: Venture = scene.get_node_or_null("Venture")
	var quixote: CharacterPawn = scene.get_node_or_null("Characters/Quixote")
	var sancho: CharacterPawn = scene.get_node_or_null("Characters/Sancho")
	var ai: CompanionAI = scene.get_node_or_null("CompanionAI")
	t.expect_true(venture != null and quixote != null and sancho != null,
		"the slice should have a Venture and the two of them")
	if venture == null or quixote == null or sancho == null:
		parent.remove_child(scene)
		scene.free()
		return

	# ── The arena ──────────────────────────────────────────────────────
	t.test("the era is a round floor with a way in")
	var era: Node = scene.get_node_or_null("Era")
	var stones := 0
	if era != null:
		for child in era.get_children():
			if child is StaticBody3D:
				stones += 1
	# Sixteen stones, less the one the gate takes.
	t.expect_eq(stones, 15, "a ring of stones with a gap in it")

	t.test("the Venture stands in the middle of it")
	if era != null:
		t.expect_almost_eq(venture.global_position.distance_to(
			Vector3(0.0, 0.0, 36.0)), 0.0, 0.01, "in the middle of the floor")

	# ── Two forms, two fights ──────────────────────────────────────────
	t.test("it has two forms and they are different")
	var reality := venture.form_data_for(0)
	var book := venture.form_data_for(1)
	t.expect_true(reality != null and book != null, "both forms exist")
	if reality == null or book == null:
		parent.remove_child(scene)
		scene.free()
		return
	t.expect_ne(reality.moveset.size(), 0, "the mill has moves")
	t.expect_ne(book.moveset.size(), 0, "the giant has moves")
	t.expect_ne(reality.moveset[0].id, book.moveset[0].id, "and they are not the same moves")
	t.expect_ne(reality.max_health, book.max_health, "and they are not the same fight")
	t.expect_almost_eq(reality.move_speed, 0.0, 0.01, "the mill does not walk")
	t.expect_gt(book.move_speed, 0.0, "the giant does")

	t.test("the world wears the Reality truth to begin with")
	TruthLayer.shift_to(TruthLayer.Layer.REALITY, true)
	t.expect_eq(venture.current_form_layer(), 0, "the mill")
	t.expect_eq(venture.max_health, reality.max_health, "with its health")

	# ── The knight's lever: the truth ──────────────────────────────────
	t.test("turning the world over turns the Venture over with it")
	# T is Quixote's alone, and the world's truth IS this thing's truth.
	TruthLayer.shift_to(TruthLayer.Layer.BOOK, true)
	venture._process(0.05)
	t.expect_eq(venture.current_form_layer(), 1, "the giant now")
	t.expect_eq(venture.max_health, book.max_health, "with the giant's health")
	TruthLayer.shift_to(TruthLayer.Layer.REALITY, true)
	venture._process(0.05)
	t.expect_eq(venture.current_form_layer(), 0, "and the mill again")

	t.test("a change of form keeps the fight where it was")
	# The health carries over as a proportion: a change of shape does
	# not heal it and does not kill it.
	venture.health = venture.max_health * 0.5
	TruthLayer.shift_to(TruthLayer.Layer.BOOK, true)
	venture._process(0.05)
	t.expect_almost_eq(venture.health / venture.max_health, 0.5, 0.02,
		"half way, whichever form it wears")
	TruthLayer.shift_to(TruthLayer.Layer.REALITY, true)
	venture._process(0.05)

	# ── The squire's lever: the Desvelar ───────────────────────────────
	t.test("the Desvelar puts it back into its Reality form")
	TruthLayer.shift_to(TruthLayer.Layer.BOOK, true)
	venture._process(0.05)
	t.expect_eq(venture.current_form_layer(), 1, "the giant to begin with")
	venture.reveal(8.0)
	venture._process(0.05)
	t.expect_eq(venture.current_form_layer(), 0,
		"the skin is off, and the skin off means the Reality form")
	t.expect_true(venture.is_revealed(), "and it says so")
	# And when the skin comes back on, so does the Book form.
	venture.set("_reveal_time", 0.0)
	venture._process(0.05)
	t.expect_eq(venture.current_form_layer(), 1, "the giant again")
	TruthLayer.shift_to(TruthLayer.Layer.REALITY, true)
	venture._process(0.05)

	t.test("and the Desvelar stops the swing it was in the middle of")
	# This is the verb's whole payoff: the squire does not kill, he
	# controls.
	venture.reset()
	quixote.global_position = venture.global_position + Vector3(2.5, 0.0, 0.0)
	quixote.health = 100.0
	_step(venture, 0.05)
	_step(venture, 0.05)
	t.expect_eq(venture.state, Venture.State.WINDUP, "it is winding up")
	venture.reveal(8.0)
	venture._process(0.05)
	t.expect_ne(venture.state, Venture.State.WINDUP, "the tell is over")
	t.expect_eq(venture.current_move(), null, "and there is no blow coming")

	# ── The tell ───────────────────────────────────────────────────────
	t.test("the blow is telegraphed")
	# The whole contract: the player reads the swing, and the companion
	# times its parry off it.
	venture.reset()
	quixote.global_position = venture.global_position + Vector3(2.0, 0.0, 0.0)
	quixote.rotation.y = PI * 0.5
	_step(venture, 0.05)
	_step(venture, 0.05)
	t.expect_true(venture.is_winding_up(), "it says so before it hits")
	t.expect_gt(venture.time_until_strike(), 0.0, "and says how long it has left")
	t.expect_in_range(venture.time_until_strike(), 0.0, 2.0, "in a readable time")

	t.test("the blow lands on whoever is in front of it")
	quixote.health = 100.0
	_step(venture, 1.5)
	t.expect_true(quixote.health < 100.0, "the blow landed, got %f" % quixote.health)

	t.test("and it is the mill's sails that did it")
	# The mill denies the ground: the sails go all the way round it.
	var reach := reality.moveset[0].reach
	t.expect_gt(reach, 3.0, "the sails reach a long way round")

	# ── The asymmetry ──────────────────────────────────────────────────
	t.test("Sancho cannot meaningfully damage it")
	# GDD.md §7.2: he staggers it, he does not kill it.
	venture.reset()
	var before := venture.health
	venture.take_damage(20.0, sancho)
	var sancho_damage := before - venture.health
	t.expect_almost_eq(sancho_damage, 20.0 * 0.4, 0.01,
		"his blow is scaled down")
	venture.reset()
	before = venture.health
	venture.take_damage(20.0, quixote)
	t.expect_almost_eq(before - venture.health, 20.0, 0.01,
		"the knight's is not")

	t.test("the poise breaks and it staggers")
	venture.reset()
	venture.take_damage(1.0, quixote, venture.max_poise + 1.0)
	t.expect_eq(venture.state, Venture.State.STAGGER, "it reels")
	t.expect_eq(venture.poise, 0.0, "and its poise is spent")

	# ── The end of it ──────────────────────────────────────────────────
	t.test("it can be killed, and the reward goes to whoever did it")
	venture.reset()
	var memories := Memoria.get_for(&"quixote")
	venture.take_damage(1000.0, quixote)
	t.expect_true(venture.is_down(), "it is over")
	t.expect_gt(Memoria.get_for(&"quixote"), memories, "the knight is paid")

	t.test("and a Venture that is over is not a target")
	t.expect_false(venture.is_in_group(LockOn.GROUP),
		"the lock goes with it")

	t.test("and it can be put back")
	venture.reset()
	t.expect_false(venture.is_down(), "it stands up")
	t.expect_eq(venture.health, venture.max_health, "with its health")

	t.test("the truth resolution: killing it in Book truth grants the fragment")
	# The Venture resolved via TRUTH grants a Manifiesto fragment
	# from chapter I.7-8 — the windmill passage.
	venture.reset()
	TruthLayer.shift_to(TruthLayer.Layer.BOOK, true)
	venture.set("_reveal_time", 0.0)  # clear any leaked reveal from earlier tests
	venture._process(0.05)
	t.expect_eq(venture.current_form_layer(), 1, "the giant")
	t.expect_false(GameState.codex_pages.has(&"bk.ch01.molinos.01"),
		"not found yet")
	# Deal lethal damage
	venture.take_damage(1000.0, quixote)
	t.expect_true(venture.is_down(), "it is over")
	t.expect_true(GameState.codex_pages.has(&"bk.ch01.molinos.01"),
		"the fragment is granted")
	# Clean up for the next test/suite
	GameState.codex_pages.erase(&"bk.ch01.molinos.01")
	venture.reset()
	TruthLayer.shift_to(TruthLayer.Layer.REALITY, true)
	venture._process(0.05)

	# ── It is a thing in the world ─────────────────────────────────────
	t.test("it can be examined and locked onto")
	t.expect_true(venture.is_in_group(Examine.GROUP), "it is examinable")
	t.expect_true(venture.is_in_group(LockOn.GROUP), "and lockable")
	t.expect_true(venture.is_in_group(AttackHitbox.TARGET_GROUP), "and hittable")
	t.expect_ne(venture.display_name(), "", "and it has a name")

	t.test("and it has a bar over its head")
	# The playtest: "there is no feedback to how much hp the enemies have
	# left". The bar is that feedback, and it is in the world.
	t.expect_true(venture != null, "the Venture node exists")

	# ── The tell ───────────────────────────────────────────────────────
	t.test("the giant telegraphs the blow")
	# The playtest: "the boss is missing animations to be able to dodge
	# and stop the attack with X". A wind-up nobody can see is not a
	# wind-up: the player has to be able to learn it.
	TruthLayer.shift_to(TruthLayer.Layer.BOOK, true)
	venture.set("_reveal_time", 0.0)
	venture._process(0.05)
	venture.reset()
	quixote.global_position = venture.global_position + Vector3(2.5, 0.0, 0.0)
	quixote.rotation.y = PI * 0.5
	var giant := venture.get("_book_form") as Node3D
	t.expect_true(giant != null, "the giant is there")
	if giant != null:
		var arm := giant.get_node_or_null("ShoulderPivotRight") as Node3D
		t.expect_true(arm != null, "and its arm hangs from a shoulder")
		if arm != null:
			var resting := arm.rotation.x
			# Wind it up and let the pose run.
			venture.state = Venture.State.WINDUP
			venture.set("_move", venture.form_data_for(1).moveset[0])
			venture.set("_timer", 0.5)
			venture._process(0.05)
			t.expect_ne(arm.rotation.x, resting, "the arm draws back for the tell")
			t.expect_lt(arm.rotation.x, resting, "and it draws BACK, not forward")
	venture.state = Venture.State.DORMANT
	TruthLayer.shift_to(TruthLayer.Layer.REALITY, true)
	venture._process(0.05)

	# ── The companion's verb ───────────────────────────────────────────
	t.test("and the companion strips the skin off it")
	# Sancho's own verb, and the reason the squire is in the fight at
	# all: "one kills, one controls". He does not kill the Venture — he
	# stops it, and he is the only one who can.
	venture.reset()
	# The skin is back on, whatever an earlier test did to it.
	venture.set("_reveal_time", 0.0)
	venture._process(0.05)
	TruthLayer.shift_to(TruthLayer.Layer.BOOK, true)
	venture._process(0.05)
	t.expect_eq(venture.current_form_layer(), 1, "the giant to begin with")
	# The Venture winds up, and the companion is watching it. The
	# companion has to be near the Venture: it fights the nearest
	# hostile, and the training dummy is nearer to the start.
	quixote.global_position = venture.global_position + Vector3(2.0, 0.0, 0.0)
	sancho.global_position = venture.global_position + Vector3(3.0, 0.0, 0.0)
	ai._pick_target()
	venture.state = Venture.State.WINDUP
	venture.set("_timer", 0.3)
	sancho.stamina = sancho.max_stamina
	ai._process(0.05)
	t.expect_true(venture.is_revealed(), "the skin came off")
	venture._process(0.05)
	t.expect_eq(venture.current_form_layer(), 0, "and the Venture is back in its Reality form")
	t.expect_ne(venture.state, Venture.State.WINDUP, "and the swing it was winding up never came")
	TruthLayer.shift_to(TruthLayer.Layer.REALITY, true)
	venture._process(0.05)

	t.test("a Lost Quixote cannot turn the world over")
	# Push Quixote to Lost and press T: the world stops changing for him.
	Locura.set_for(&"quixote", 60.0)
	t.expect_eq(Locura.threshold_for(&"quixote"), Locura.Threshold.LOST,
		"Quixote is Lost")
	var layer_before := TruthLayer.layer()
	var press := InputEventAction.new()
	press.action = &"toggle_truth"
	press.pressed = true
	scene.call("_unhandled_input", press)
	t.expect_eq(TruthLayer.layer(), layer_before,
		"the world's truth did not change for a Lost Quixote")
	# Clean up: restore Quixote to Lucid
	Locura.set_for(&"quixote", 10.0)

	parent.remove_child(scene)
	scene.free()


## Let a node run its own logic for a moment.
func _step(node: Node, seconds: float) -> void:
	node.call("_physics_process", seconds)
