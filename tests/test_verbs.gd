extends RefCounted
## The verbs: the dodge, and the stamina it spends.
##
## GDD.md §7.1: "Dodge — 0.4s i-frames, stamina cost, directional" and
## "Stamina — shared pool, regenerates after 1s idle".
##
## Task 2.5 of the plan. The dodge was a key in the input map and nothing
## behind it; the stamina was a number that only ever went down.

const SCENE := "res://src/world/slice.tscn"


func suite(t: TestHarness) -> void:
	t.suite("Verbs")

	var tree := Engine.get_main_loop() as SceneTree
	var parent: Node = tree.current_scene if tree != null and tree.current_scene != null else null
	var packed: PackedScene = load(SCENE)
	t.expect_true(packed != null, "slice.tscn should load")
	if packed == null or parent == null:
		return

	var scene: Node = packed.instantiate()
	parent.add_child(scene)

	var quixote: CharacterPawn = scene.get_node_or_null("Characters/Quixote")
	t.expect_true(quixote != null, "Quixote should be in the scene")
	if quixote == null:
		parent.remove_child(scene)
		scene.free()
		return
	var sancho: CharacterPawn = scene.get_node_or_null("Characters/Sancho")
	var dummy: TrainingDummy = scene.get_node_or_null("Yard/TrainingDummy")
	t.expect_true(sancho != null and dummy != null, "the yard should have Sancho and a dummy in it")

	t.test("both characters can dodge")
	t.expect_true(quixote.data != null and quixote.data.dodge != null, "Quixote has a dodge")
	t.expect_true(sancho != null and sancho.data != null, "Sancho should be in the scene")
	if sancho != null and sancho.data != null:
		t.expect_true(sancho.data.dodge != null, "Sancho has a dodge")

	t.test("the roll is a distance, and it is less than it was")
	# The second playtest: the roll was six metres, which is a third of
	# the yard. It is four now.
	t.expect_almost_eq(quixote.roll_distance(), 4.0, 0.001, "Quixote's roll is four metres")

	t.test("Sancho's roll is half of Quixote's")
	# *"Sancho's roll should be half the distance."* He is a heavier man
	# with a sack: he goes nowhere, and he is safe while he does it.
	t.expect_almost_eq(sancho.roll_distance(), quixote.roll_distance() * 0.5, 0.001,
		"half the distance")

	t.test("Quixote's invulnerability is shorter: he is not a fighter")
	# *"The invulnerability of Quixote, as he should not be a fighter."*
	t.expect_almost_eq(quixote.invulnerability_seconds(), 0.25, 0.001,
		"a quarter of a second, not four tenths")
	t.expect_gt(sancho.invulnerability_seconds(), quixote.invulnerability_seconds(),
		"and Sancho, who is the practical one, keeps the full window")

	t.test("the dodge carries you exactly that far")
	# You move for as long as you cannot be hit, so the distance and the
	# window together fix the speed.
	for i in 40:
		quixote._physics_process(0.05)
	quixote.stamina = quixote.max_stamina
	quixote.dodge()
	var quixote_speed: float = quixote.get("_dodge_speed")
	var quixote_window: float = quixote.get("_dodge_time")
	t.expect_almost_eq(quixote_speed * quixote_window, 4.0, 0.01,
		"four metres over the window")
	# Let the cooldown run out, so the next dodge is allowed.
	for i in 40:
		quixote._physics_process(0.05)

	for i in 40:
		sancho._physics_process(0.05)
	sancho.stamina = sancho.max_stamina
	sancho.dodge()
	var sancho_speed: float = sancho.get("_dodge_speed")
	var sancho_window: float = sancho.get("_dodge_time")
	t.expect_almost_eq(sancho_speed * sancho_window, 2.0, 0.01,
		"two metres over the window")

	t.test("a dodge costs stamina")
	var before: float = quixote.stamina
	quixote.dodge()
	t.expect_true(quixote.stamina < before, "the dodge cost stamina (%f -> %f)" % [before, quixote.stamina])

	t.test("the i-frames make you untouchable")
	# This is the whole point of a dodge, and it is invisible without it.
	quixote.dodge()
	var health: float = quixote.health
	quixote.take_damage(25.0)
	t.expect_eq(quixote.health, health, "the blow went past")

	t.test("and it wears off")
	# Let the i-frames run out.
	for i in 40:
		quixote._physics_process(0.05)
	quixote.take_damage(25.0)
	t.expect_true(quixote.health < health, "the next blow lands")

	t.test("the dodge is directional")
	for i in 40:
		quixote._physics_process(0.05)
	quixote.stamina = quixote.max_stamina
	quixote.move(Vector2(1.0, 0.0), false)
	quixote.dodge()
	t.expect_true(quixote.get("_dodge_direction").x > 0.5, "the dodge went where you were going")

	t.test("the stamina comes back")
	# Let the previous dodge run out, or this one is refused.
	for i in 40:
		quixote._physics_process(0.05)
	quixote.stamina = quixote.max_stamina
	quixote.dodge()
	var spent: float = quixote.stamina
	t.expect_true(spent < quixote.max_stamina, "the dodge spent something")
	# A second of idling, and then it starts coming back.
	for i in 15:
		quixote._physics_process(0.05)
	var midway: float = quixote.stamina
	t.expect_eq(midway, spent, "the stamina waits a second before it comes back")
	for i in 60:
		quixote._physics_process(0.05)
	t.expect_true(quixote.stamina > midway, "and then it comes back")
	t.expect_true(quixote.stamina <= quixote.max_stamina, "and it never comes back more than you had")

	t.test("you cannot dodge without the stamina")
	for i in 40:
		quixote._physics_process(0.05)
	quixote.stamina = 0.0
	quixote.dodge()
	t.expect_eq(quixote.get("_dodge_time"), 0.0, "no dodge, no burst")

	# ── The chain ──────────────────────────────────────────────────────
	t.test("the light attack is a chain of three")
	# GDD.md §7.1: "2–3 hit combo, low commitment". Each step of the
	# chain hits harder than the last.
	var damages: Array[float] = []
	for step in 3:
		# Long enough for the swing's own rhythm, short enough to stay
		# inside the chain's window.
		for i in 10:
			quixote._physics_process(0.05)
		quixote.stamina = quixote.max_stamina
		quixote._attack_cooldown = 0.0
		_clear_hitboxes(quixote)
		quixote.light_attack()
		var box: AttackHitbox = quixote.get_node_or_null("Hitbox")
		if box != null:
			damages.append(box.damage)
			box.free()
	t.expect_eq(damages.size(), 3, "three swings")
	if damages.size() == 3:
		t.expect_true(damages[0] < damages[1], "the second hits harder")
		t.expect_true(damages[1] < damages[2], "and the third harder still")

	t.test("the chain closes if you wait")
	for i in 40:
		quixote._physics_process(0.05)
	quixote.stamina = quixote.max_stamina
	quixote._attack_cooldown = 0.0
	_clear_hitboxes(quixote)
	quixote.light_attack()
	var reopened: AttackHitbox = quixote.get_node_or_null("Hitbox")
	t.expect_true(reopened != null, "the swing came out")
	if reopened != null:
		t.expect_eq(reopened.damage, 14.0, "and it starts the chain again")
		reopened.free()

	# ── The guard ──────────────────────────────────────────────────────
	t.test("the guard stops most of a blow")
	for i in 20:
		quixote._physics_process(0.05)
	quixote.health = 100.0
	quixote.stamina = quixote.max_stamina
	quixote.block(true)
	t.expect_true(quixote.is_blocking(), "the guard is up")
	quixote.take_damage(20.0)
	t.expect_true(quixote.health > 90.0, "most of it did not get through, got %f" % quixote.health)

	t.test("and the guard costs stamina")
	var guard_stamina := quixote.stamina
	quixote.take_damage(20.0)
	t.expect_true(quixote.stamina < guard_stamina, "catching a blow costs stamina")

	t.test("a guard with no stamina breaks")
	quixote.stamina = 0.0
	quixote.health = 100.0
	quixote.take_damage(20.0)
	t.expect_true(quixote.health < 90.0, "the blow landed in full, got %f" % quixote.health)
	quixote.block(false)

	# ── The parry ──────────────────────────────────────────────────────
	t.test("only Sancho can parry")
	# GDD.md §7.1: "Quixote: lance = wide block, no parry. Sancho:
	# buckler = parry, tight window, huge reward."
	t.expect_false(quixote.data.can_parry, "Quixote's lance cannot parry")
	t.expect_true(sancho.data.can_parry, "Sancho's buckler can")
	t.expect_gt(sancho.data.parry_window, 0.0, "and it has a window")

	t.test("a parry costs no health and opens the attacker")
	for i in 20:
		sancho._physics_process(0.05)
	sancho.health = 100.0
	sancho.stamina = sancho.max_stamina
	sancho.block(true)
	t.expect_true(sancho.can_parry_now(), "the window is open")
	sancho.take_damage(20.0, dummy)
	t.expect_eq(sancho.health, 100.0, "the blow did not touch him")
	t.expect_eq(dummy.state, TrainingDummy.State.STAGGER, "and the attacker is open")
	sancho.block(false)

	# ── The poise ──────────────────────────────────────────────────────
	t.test("blows take the poise, and a broken poise staggers")
	for i in 20:
		quixote._physics_process(0.05)
	quixote.health = 100.0
	quixote.poise = 0.0
	quixote.take_damage(10.0, null, 10.0)
	t.expect_true(quixote.poise > 0.0, "the poise is down")
	t.expect_false(quixote.is_staggered(), "but the character is still up")
	quixote.take_damage(10.0, null, 100.0)
	t.expect_true(quixote.is_staggered(), "the poise broke, and the character reels")

	t.test("a staggered character cannot swing back")
	quixote.stamina = quixote.max_stamina
	quixote._attack_cooldown = 0.0
	_clear_hitboxes(quixote)
	quixote.light_attack()
	t.expect_eq(quixote.get_node_or_null("Hitbox"), null, "no swing while staggered")

	parent.remove_child(scene)
	scene.free()


## The hitboxes of a swing. They free themselves in the game; in a test
## they have to be cleared by hand, or the last one is still there.
func _clear_hitboxes(pawn: CharacterPawn) -> void:
	for child in pawn.get_children():
		if child is AttackHitbox:
			child.free()
