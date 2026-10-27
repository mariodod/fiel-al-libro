extends RefCounted
const TestHarness = preload("res://tests/test_harness.gd")
var Chatter = preload("res://src/systems/chatter.gd")
## The companion's chatter: a line about the thing it is looking at.
##
## B3, from the first playtest: the barks were the right answer to the
## hand-holding, but the idle ones were a random draw from a pool of two.
## A companion that says "sí, señor" every twenty-five seconds is a
## label, not a person.
##
## So the line is about the thing in front of it — the rock, the mill,
## the dummy — and about what the player is doing: locked onto
## something, or on the ground.

const SCENE = "res://src/world/slice.tscn"

## Everything the companion said while the test was running.
var _spoken: Array[StringName] = []


func suite(t):
	t.suite("Chatter")

	# ── The keys ───────────────────────────────────────────────────────
	var chatter = Chatter.new_instance()
	t.test("the key is composed")
	t.expect_eq(chatter.call("key_for", &"sancho", &"rock"), &"dia.sancho.chatter.rock",
		"the character and the thing")
	t.expect_eq(chatter.call("key_for", &"quixote", &"dummy"), &"dia.quixote.chatter.dummy",
		"and another one")

	t.test("the idle lines cycle")
	t.expect_eq(chatter.call("idle_key", &"quixote", 0), &"dia.quixote.chatter.idle.1", "the first")
	t.expect_eq(chatter.call("idle_key", &"quixote", 1), &"dia.quixote.chatter.idle.2", "the second")
	t.expect_eq(chatter.call("idle_key", &"quixote", 5), &"dia.quixote.chatter.idle.6", "the sixth")
	t.expect_eq(chatter.call("idle_key", &"quixote", 6), &"dia.quixote.chatter.idle.1", "and it wraps around")

	t.test("a character with no id has no line")
	t.expect_eq(chatter.call("key_for", &"", &"rock"), &"", "no key")

	# ── In the world ───────────────────────────────────────────────────
	var tree = Engine.get_main_loop() as SceneTree
	var parent = tree.current_scene if tree != null and tree.current_scene != null else null
	var packed = load(SCENE)
	t.expect_true(packed != null, "slice.tscn should load")
	if packed == null or parent == null:
		return

	var scene = packed.instantiate()
	parent.add_child(scene)

	var ai = scene.get_node_or_null("CompanionAI")
	var sancho = scene.get_node_or_null("Characters/Sancho")
	var quixote = scene.get_node_or_null("Characters/Quixote")
	t.expect_true(ai != null and sancho != null and quixote != null, "the slice has a companion")
	if ai == null or sancho == null or quixote == null:
		parent.remove_child(scene)
		scene.free()
		return

	_spoken.clear()
	EventBus.character_spoke.connect(_on_spoke)

	# Put the companion next to the rock, so the rock is the thing it is
	# looking at.
	sancho.global_position = Vector3(12.0, 0.0, -12.0)
	ai.call("_update_chatter", 20.0)

	t.test("the companion says something about what it is looking at")
	t.expect_eq(_spoken.size(), 1, "it said one thing, got %d" % _spoken.size())
	if _spoken.size() >= 1:
		t.expect_eq(_spoken[0], &"dia.sancho.chatter.rock", "and it was about the rock")

	t.test("and it does not say the same thing twice")
	ai.call("_update_chatter", 20.0)
	t.expect_eq(_spoken.size(), 2, "it said something else")
	if _spoken.size() >= 2:
		t.expect_eq(_spoken[1], &"dia.sancho.chatter.idle.1", "an idle line, not the rock again")

	t.test("a new thing gets a new line")
	# The mill this time.
	sancho.global_position = Vector3(0.0, 0.0, -17.0)
	ai.call("_update_chatter", 20.0)
	t.expect_eq(_spoken.size(), 3, "it said something")
	if _spoken.size() >= 3:
		t.expect_eq(_spoken[2], &"dia.sancho.chatter.windmill", "about the mill")

	t.test("and it speaks when the player goes down")
	_spoken.clear()
	EventBus.character_died.emit(quixote.character_id)
	t.expect_eq(_spoken.size(), 1, "it said one thing")
	if _spoken.size() >= 1:
		t.expect_eq(_spoken[0], &"dia.sancho.chatter.down", "about the player being down")

	_spoken.clear()
	EventBus.character_spoke.disconnect(_on_spoke)
	parent.remove_child(scene)
	scene.free()


## Something was said.
func _on_spoke(character_id: StringName, text_key: StringName, _args: Array):
	_spoken.append(text_key)
