extends RefCounted
const TestHarness = preload("res://tests/test_harness.gd")
const Perception = preload("res://src/systems/perception.gd")
var TruthObject = preload("res://src/world/truth_object.gd")
var Reaction = preload("res://src/systems/reaction.gd")
## B5: the reaction. When the world moves under a character, they say so.
##
## "When quixote goes back to seeing reality some reaction from his side
## should happen." A filter change is invisible; a character who says so
## is a character, and it is the only way the player finds out that the
## world they are in is not the world they were in.

const SLICE = "res://src/world/slice.tscn"


func suite(t):
	t.suite("Reaction")

	t.test("the key is composed from the character and the thing")
	t.expect_eq(Reaction.bark_key(&"quixote", &"windmill", Perception.BOOK),
		&"dia.quixote.reaction.windmill.book", "Quixote sees the giant")
	t.expect_eq(Reaction.bark_key(&"quixote", &"windmill", Perception.REALITY),
		&"dia.quixote.reaction.windmill.reality", "Quixote sees the windmill again")
	t.expect_eq(Reaction.bark_key(&"sancho", &"rock", Perception.BOOK),
		&"dia.sancho.reaction.rock.book", "Sancho sees the book")
	t.expect_eq(Reaction.bark_key(&"sancho", &"rock", Perception.REALITY),
		&"dia.sancho.reaction.rock.reality", "Sancho sees the rock again")

	t.test("no character, no line")
	t.expect_eq(Reaction.bark_key(&"", &"rock", 0), &"", "a reaction needs a speaker")
	t.expect_eq(Reaction.bark_key(&"quixote", &"", 0), &"", "a reaction needs a thing")

	# ── The live thing ─────────────────────────────────────────────────
	var locale = TranslationServer.get_locale()
	TranslationServer.set_locale("en")

	var tree = Engine.get_main_loop() as SceneTree
	var parent = tree.current_scene if tree != null and tree.current_scene != null else null
	var packed = load(SLICE)
	t.expect_true(packed != null, "slice.tscn should load")
	if packed == null or parent == null:
		TranslationServer.set_locale(locale)
		return

	var scene = packed.instantiate()
	parent.add_child(scene)
	_settle(scene)

	var spoken: Array[StringName] = []
	var speaker: Array[StringName] = []
	var on_spoke = func(character_id: StringName, text_key: StringName, _args: Array):
		spoken.append(text_key)
		speaker.append(character_id)
	EventBus.character_spoke.connect(on_spoke)

	var quixote = scene.get_node("Characters/Quixote")
	var sancho = scene.get_node("Characters/Sancho")
	var controller = scene.get_node("PlayerController")

	# Stand next to the rock, looking at it, so there is something to
	# react to.
	quixote.global_position = Vector3(11.0, 0.0, -9.0)
	quixote.rotation.y = 0.0
	controller.call("_update_examine_target", 1.0)
	_settle(scene)

	t.test("nothing to say until the world moves")
	t.expect_eq(spoken.size(), 0, "nobody has reacted yet")

	t.test("when the world turns over, Quixote reacts")
	TruthLayer.shift_to(TruthLayer.Layer.BOOK, true)
	_settle(scene)
	t.expect_true(spoken.has(&"dia.quixote.reaction.rock.book"),
		"Quixote sees the book now, got %s" % str(spoken))
	t.expect_true(speaker.has(&"quixote"), "and it is Quixote who says it")

	t.test("Sancho does not react to what he cannot see")
	# He has no second sight, so the rock is still a rock to him and
	# nothing about his reading has changed.
	t.expect_false(spoken.has(&"dia.sancho.reaction.rock.book"),
		"Sancho cannot see the Book, so he has nothing to react to")

	t.test("with the second sight, he does")
	sancho.second_sight = true
	_settle(scene)
	spoken.clear()
	TruthLayer.shift_to(TruthLayer.Layer.REALITY, true)
	_settle(scene)
	t.expect_true(spoken.has(&"dia.sancho.reaction.rock.reality"),
		"Sancho sees the rock again, got %s" % str(spoken))
	sancho.second_sight = false

	t.test("the madness letting go is a reaction too")
	# B5, exactly: Quixote goes back to seeing reality.
	spoken.clear()
	TruthLayer.shift_to(TruthLayer.Layer.REALITY, true)
	Locura.set_for(&"quixote", 60.0)
	_settle(scene)
	t.expect_true(spoken.has(&"dia.quixote.reaction.rock.book"),
		"a mad Quixote reads a rock as a book, got %s" % str(spoken))

	spoken.clear()
	Locura.set_for(&"quixote", 10.0)
	_settle(scene)
	t.expect_true(spoken.has(&"dia.quixote.reaction.rock.reality"),
		"and Reality comes back, got %s" % str(spoken))

	EventBus.character_spoke.disconnect(on_spoke)

	Locura.set_for(&"quixote", 10.0)
	TruthLayer.shift_to(TruthLayer.Layer.REALITY, true)
	TruthLayer.set_view_layer(-1)
	parent.remove_child(scene)
	scene.free()
	TranslationServer.set_locale(locale)


## Two frames' worth of settling: the view fades to the new reading, and
## then the objects follow it.
func _settle(scene: Node):
	scene.call("_update_readings")
	TruthLayer.advance_blend(2.0)
	scene.call("_update_readings")
