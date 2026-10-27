extends RefCounted
const TestHarness = preload("res://tests/test_harness.gd")
const CharacterPawn = preload("res://src/characters/character_pawn.gd")
## The rigs, in the game: the pawn drives the clips, and the clips are
## the right ones.
##
## The assets are pinned in test_rigs.gd. This is the other half: the
## character has to PLAY them, and play the right one — a roll that does
## not roll, a hit that does not flinch, and a chain that stays on
## light_1 forever, are all the same bug.

const SCENE = "res://src/world/slice.tscn"


func suite(t):
	t.suite("Animation")

	var tree = Engine.get_main_loop() as SceneTree
	var parent = tree.current_scene if tree != null and tree.current_scene != null else null
	var packed = load(SCENE)
	t.expect_true(packed != null, "slice.tscn should load")
	if packed == null or parent == null:
		return

	var scene = packed.instantiate()
	parent.add_child(scene)

	var quixote = scene.get_node_or_null("Characters/Quixote")
	var sancho = scene.get_node_or_null("Characters/Sancho")
	t.expect_true(quixote != null and sancho != null, "the slice has the two of them")
	if quixote == null or sancho == null:
		parent.remove_child(scene)
		scene.free()
		return

	t.test("the characters carry their rigs")
	t.expect_true(_player(quixote) != null, "Quixote has an AnimationPlayer")
	t.expect_true(_player(sancho) != null, "Sancho has an AnimationPlayer")

	t.test("and they start on the idle")
	_step(quixote)
	t.expect_eq(_current(quixote), &"idle", "Quixote is standing")
	t.expect_eq(_current(sancho), &"idle", "Sancho is standing")

	t.test("walking plays the walk")
	quixote.velocity = Vector3(0.0, 0.0, 3.0)
	_step(quixote)
	t.expect_eq(_current(quixote), &"walk", "Quixote is walking")
	quixote.velocity = Vector3.ZERO

	t.test("running plays the run")
	quixote.move(Vector2(0.0, 1.0), true)
	quixote.velocity = Vector3(0.0, 0.0, 7.0)
	_step(quixote)
	t.expect_eq(_current(quixote), &"run", "Quixote is running")
	quixote.velocity = Vector3.ZERO
	_step(quixote)

	t.test("a dodge plays the roll")
	quixote.stamina = quixote.max_stamina
	quixote.dodge()
	_step(quixote)
	t.expect_eq(_current(quixote), &"roll", "Quixote is rolling")
	for i in 30:
		_step(quixote)
	t.expect_eq(_current(quixote), &"idle", "and back to standing")

	t.test("a swing plays the chain")
	quixote.stamina = quixote.max_stamina
	quixote._attack_cooldown = 0.0
	quixote.light_attack()
	_step(quixote)
	t.expect_eq(_current(quixote), &"light_1", "the first link of the chain")
	# Inside the chain's window (0.8 s) and outside the swing's own
	# rhythm (0.45 s), so the second press continues the chain.
	for i in 11:
		_step(quixote)
	quixote.stamina = quixote.max_stamina
	quixote._attack_cooldown = 0.0
	quixote.light_attack()
	_step(quixote)
	t.expect_eq(_current(quixote), &"light_2", "the second link")

	t.test("a hit plays the flinch")
	quixote.health = 100.0
	quixote.take_damage(10.0)
	_step(quixote)
	t.expect_eq(_current(quixote), &"hit", "Quixote is reeling")

	t.test("a broken poise plays the stagger")
	quixote.poise = 0.0
	quixote.take_damage(1.0, null, 999.0)
	_step(quixote)
	t.expect_eq(_current(quixote), &"stagger", "Quixote is on his heels")

	t.test("the guard plays the guard")
	for i in 60:
		_step(quixote)
	quixote.block(true)
	_step(quixote)
	t.expect_eq(_current(quixote), &"block", "Quixote's lance is across his chest")
	quixote.block(false)
	_step(quixote)

	t.test("and Sancho's guard is a parry")
	sancho.block(true)
	_step(sancho)
	t.expect_eq(_current(sancho), &"parry", "the buckler comes up")
	sancho.block(false)
	_step(sancho)

	t.test("death plays the death")
	quixote.take_damage(500.0)
	_step(quixote)
	t.expect_eq(_current(quixote), &"death", "Quixote is down")
	quixote.revive()
	_step(quixote)

	t.test("a mad Quixote stands differently")
	# His own idle, not the ordinary one: the Locura is the character.
	# Let the last blow's push die away first, or he is still being
	# knocked about and the walk wins.
	for i in 20:
		_step(quixote)
	Locura.set_for(&"quixote", 60.0)
	for i in 4:
		_step(quixote)
	t.expect_eq(_current(quixote), &"idle_lost", "the madness has its own posture")
	Locura.set_for(&"quixote", 10.0)
	for i in 4:
		_step(quixote)

	t.test("an action holds the floor for its length")
	# The examine: the character leans in to read the thing.
	quixote.play_action(&"interact")
	_step(quixote)
	t.expect_eq(_current(quixote), &"interact", "he is reading it")
	for i in 90:
		_step(quixote)
	t.expect_eq(_current(quixote), &"idle", "and back to standing")

	Locura.set_for(&"quixote", 10.0)
	parent.remove_child(scene)
	scene.free()


## The AnimationPlayer of a character, if it has one.
##
## It is a grandchild: the rig is an imported .glb, and its
## AnimationPlayer is a child of the glb's root, which is a child of the
## character.
func _player(pawn: CharacterPawn):
	if pawn == null:
		return null
	for node in _descendants(pawn):
		if node is AnimationPlayer:
			return node
	return null


func _descendants(node: Node):
	var out = [node]
	for child in node.get_children():
		out.append_array(_descendants(child))
	return out


## The clip playing right now.
func _current(pawn: CharacterPawn):
	var player = _player(pawn)
	if player == null:
		return &""
	return player.current_animation


## Let the character run its own logic for a moment.
func _step(pawn: CharacterPawn):
	pawn._physics_process(0.05)
