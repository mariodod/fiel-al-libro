extends RefCounted
const TestHarness = preload("res://tests/test_harness.gd")
const Perception = preload("res://src/systems/perception.gd")
var Examine = preload("res://src/systems/examine.gd")
var TruthObject = preload("res://src/world/truth_object.gd")
var TruthObjectData = preload("res://src/data/truth_object_data.gd")
var TruthFace = preload("res://src/data/truth_face.gd")
## The Examine verb: the thing in front of you, and what you make of it.
##
## The first playtest asked for this verb twice, by two people who had
## never spoken to each other: "seeing the rock I wanted to interact with
## it, even more the book I expected to be able to interact with it and
## read it", and "wanted to interact with book and giant". There was
## nothing to press.
##
## The second playtest said what was wrong with it: *"Examining shouldn't
## give away all the information. It should give the information the
## character sees."* So the panel gives ONE character's perception — the
## name, the description, the title, the text, and the one detail that
## does not add up — and never the truth table and never the other
## character's reading.
##
## So: the targeting (what are you looking at), the faces (one per
## truth), the perception (what this character makes of it right now),
## and the panel that says it.

const SLICE = "res://src/world/slice.tscn"


func suite(t):
	t.suite("Examine")

	var tree = Engine.get_main_loop() as SceneTree
	var parent = tree.current_scene if tree != null and tree.current_scene != null else null

	# ── Targeting ──────────────────────────────────────────────────────
	var ahead = _make_object(&"ahead")
	var behind = _make_object(&"behind")
	var distant = _make_object(&"distant")
	var sideways = _make_object(&"sideways")
	if parent != null:
		parent.add_child(ahead)
		parent.add_child(behind)
		parent.add_child(distant)
		parent.add_child(sideways)

	var origin = Vector3.ZERO
	var forward = Vector3(0.0, 0.0, -1.0)

	t.test("the object in front of you is the one you examine")
	ahead.global_position = Vector3(0.0, 0.0, -3.0)
	behind.global_position = Vector3(0.0, 0.0, 3.0)
	distant.global_position = Vector3(0.0, 0.0, -30.0)
	sideways.global_position = Vector3(20.0, 0.0, 0.0)
	var examine = Examine.new_instance()
	t.expect_eq(examine.call("find_target", [ahead, behind, distant, sideways], origin, forward), ahead,
		"the object in front should be the target")

	t.test("what is behind you is not the target")
	t.expect_eq(examine.call("find_target", [behind], origin, forward), null,
		"an object behind the player should not be examined")

	t.test("what is too far away is not the target")
	t.expect_eq(examine.call("find_target", [distant], origin, forward), null,
		"an object out of reach should not be examined")

	t.test("the one you are looking at most directly wins")
	# The windmill is eleven metres tall and the rock is a pebble: the
	# player is looking at the windmill, so the windmill is the target,
	# even though the pebble is nearer and off to one side.
	var tall = _make_object(&"tall")
	var pebble = _make_object(&"pebble")
	if parent != null:
		parent.add_child(tall)
		parent.add_child(pebble)
	tall.global_position = Vector3(0.0, 0.0, -4.0)
	pebble.global_position = Vector3(1.2, 0.0, -1.5)
	t.expect_eq(examine.call("find_target", [pebble, tall], origin, forward), tall,
		"the thing you are facing is the target, not the nearest thing")

	t.test("nothing to look at is no target")
	t.expect_eq(examine.call("find_target", [], origin, forward), null, "no candidates, no target")

	# ── The faces ──────────────────────────────────────────────────────
	t.test("a thing has one face per truth")
	var reality = examine.call("face_for", ahead, 0)
	var book = examine.call("face_for", ahead, 1)
	t.expect_true(reality != null and book != null, "both faces exist")
	if reality != null and book != null:
		t.expect_eq(reality.name_key, &"ui.form.molino", "the Reality name")
		t.expect_eq(book.name_key, &"ui.form.gigante", "the Book name")
		t.expect_true(reality.has_tell(), "a face can carry a seam")
		t.expect_false(book.has_fragment(), "a face carries a page only if it has one")

	# ── The panel ──────────────────────────────────────────────────────
	var locale = TranslationServer.get_locale()
	TranslationServer.set_locale("en")

	var packed = load(SLICE)
	t.expect_true(packed != null, "slice.tscn should load")
	if packed != null and parent != null:
		var scene = packed.instantiate()
		parent.add_child(scene)
		_settle(scene)

		var panel = scene.get_node_or_null("ExamineLayer/ExaminePanel")
		t.expect_true(panel != null, "the slice should build the Examine panel")

		if panel != null:
			t.test("examining a thing says what this character sees")
			# The signal is the real path: the controller emits it, the
			# panel listens.
			EventBus.object_examined.emit(&"rock", &"quixote")
			var text = panel.call("examination_text")
			t.expect_true(text.contains("rock"), "it names the thing, got '%s'" % text)
			t.expect_true(text.contains("grey stone"), "it describes how it looks, got '%s'" % text)
			t.expect_true(text.contains("heavier than a stone"), "it says what does not add up, got '%s'" % text)

			t.test("it does NOT give the truth table away")
			# This is the whole of the second playtest's note.
			t.expect_false(text.contains("Reality:"), "no truth table, got '%s'" % text)
			t.expect_false(text.contains("Book:"), "no truth table, got '%s'" % text)

			t.test("it does NOT give the other character's reading away")
			t.expect_false(text.contains("Sancho"), "the companion is not in the panel, got '%s'" % text)

			t.test("the reading follows the world")
			# The world turns over to the Book. Quixote reads the rock as a
			# book: it has a title, it has a page, and the page is heavier
			# than a book that size should be.
			TruthLayer.shift_to(TruthLayer.Layer.BOOK, true)
			_settle(scene)
			var moved = panel.call("examination_text")
			t.expect_true(moved.contains("book"), "Quixote reads a book, got '%s'" % moved)
			t.expect_true(moved.contains("Don Quixote of La Mancha"), "it has a title, got '%s'" % moved)
			t.expect_true(moved.contains("In a place in La Mancha"), "it has a page, got '%s'" % moved)
			t.expect_true(moved.contains("heavier than a book"), "and the seam, got '%s'" % moved)
			t.expect_false(moved.contains("grey stone"), "and not the Reality reading, got '%s'" % moved)

			t.test("a character who cannot see the Book still sees a stone")
			# Sancho has no second sight, so in a Book world he reads the
			# rock as a rock. The panel is his perception, not the world's.
			_close_panel(panel)
			EventBus.object_examined.emit(&"rock", &"sancho")
			var sancho_sees = panel.call("examination_text")
			t.expect_true(sancho_sees.contains("rock"), "Sancho sees a rock, got '%s'" % sancho_sees)
			t.expect_true(sancho_sees.contains("grey stone"), "and the stone's description, got '%s'" % sancho_sees)
			t.expect_false(sancho_sees.contains("Don Quixote of La Mancha"), "and no book title, got '%s'" % sancho_sees)

			t.test("a mad Quixote reads a rock as a book even in Reality")
			TruthLayer.shift_to(TruthLayer.Layer.REALITY, true)
			Locura.set_for(&"quixote", 60.0)
			_settle(scene)
			_close_panel(panel)
			EventBus.object_examined.emit(&"rock", &"quixote")
			var mad = panel.call("examination_text")
			t.expect_true(mad.contains("book"), "the Book is all he has ever seen, got '%s'" % mad)
			t.expect_true(mad.contains("heavier than a book"), "and the book's seam, got '%s'" % mad)

			t.test("the panel follows the character you are driving")
			# Swap, and the same object is described in the other reading.
			TruthLayer.shift_to(TruthLayer.Layer.BOOK, true)
			_settle(scene)
			_close_panel(panel)
			EventBus.object_examined.emit(&"rock", &"quixote")
			t.expect_true(str(panel.call("examination_text")).contains("book"),
				"Quixote is driving, so it is a book")
			EventBus.character_switched.emit(&"quixote", &"sancho")
			var swapped = panel.call("examination_text")
			t.expect_true(swapped.contains("rock"), "Sancho is driving, so the rock is a rock, got '%s'" % swapped)
			t.expect_false(swapped.contains("Don Quixote of La Mancha"), "and the title is gone, got '%s'" % swapped)

			t.test("the panel stays open until you close it")
			# The playtest: "the information dialog should remain open
			# until i close it with E again to read everything". A panel
			# that closes itself while you are reading it is a panel you
			# cannot read.
			_close_panel(panel)
			EventBus.object_examined.emit(&"rock", &"sancho")
			var box = panel.get_node_or_null("Panel")
			t.expect_true(box != null, "the panel has a box")
			if box != null:
				t.expect_true(box.visible, "it opens")
				# A hundred frames of nothing: it must still be there.
				for i in 100:
					panel.call("_process", 0.05)
				t.expect_true(box.visible, "and it does not close itself")

			t.test("and E again closes it")
			EventBus.object_examined.emit(&"rock", &"sancho")
			if box != null:
				t.expect_false(box.visible, "the second press closes it")
				t.expect_eq(str(panel.call("examination_text")), "", "and it is empty")

			t.test("the prompt appears when there is something in front of you")
			EventBus.examine_target_changed.emit(&"rock")
			var prompt = panel.get_node_or_null("Prompt")
			t.expect_true(prompt != null, "the panel has a prompt")
			if prompt != null:
				t.expect_true(prompt.visible, "the prompt shows")
				t.expect_true(prompt.text.contains("Examine"), "the prompt says what to do, got '%s'" % prompt.text)
			EventBus.examine_target_changed.emit(&"")
			if prompt != null:
				t.expect_false(prompt.visible, "the prompt goes away when there is nothing in front")

			t.test("walk up to it, press E, and the game answers")
			# The whole chain, with the real player controller: the pawn
			# stands next to the rock and faces it, the controller finds it,
			# and the key press is what the player's hands do.
			TruthLayer.shift_to(TruthLayer.Layer.REALITY, true)
			# Quixote is still mad from the test above. Let him go, or he
			# reads the rock as a book in a Reality world.
			Locura.set_for(&"quixote", 10.0)
			_settle(scene)
			var controller = scene.get_node_or_null("PlayerController")
			var quixote = scene.get_node_or_null("Characters/Quixote")
			t.expect_true(controller != null and quixote != null, "the slice has a player and a controller")
			if controller != null and quixote != null:
				quixote.global_position = Vector3(11.0, 0.0, -9.0)
				quixote.rotation.y = 0.0
				controller.call("_update_examine_target", 1.0)

				var press = InputEventAction.new()
				press.action = &"interact"
				press.pressed = true
				controller._unhandled_input(press)

				var said = panel.call("examination_text")
				t.expect_true(said.contains("rock"), "the game tells you what you see, got '%s'" % said)
				t.expect_true(said.contains("grey stone"), "and how it looks, got '%s'" % said)

		Locura.set_for(&"quixote", 10.0)
		TruthLayer.shift_to(TruthLayer.Layer.REALITY, true)
		TruthLayer.set_view_layer(-1)
		if scene != null:
			parent.remove_child(scene)
			scene.free()

	TranslationServer.set_locale(locale)

	for object in [ahead, behind, distant, sideways]:
		if parent != null:
			parent.remove_child(object)
		object.free()


## A TruthObject with two empty forms, so the test does not need the art.
func _make_object(id: StringName):
	var data = TruthObjectData.new_instance()
	data.id = id
	data.display_name_key = &"ui.object.molino"
	data.reality_face = _face(&"ui.form.molino", &"ui.face.windmill.reality.desc")
	data.book_face = _face(&"ui.form.gigante", &"ui.face.windmill.book.desc")
	data.reality_form = _pack_form()
	data.book_form = _pack_form()

	var object = TruthObject.new_instance()
	object.data = data
	object.setup(data)
	return object


## A face, with a name and a description.
func _face(name_key: StringName, description_key: StringName):
	var face = TruthFace.new_instance()
	face.name_key = name_key
	face.description_key = description_key
	face.tell_key = &"ui.face.windmill.reality.tell"
	return face


func _pack_form():
	var packed = PackedScene.new()
	var root = Node3D.new()
	root.name = "Form"
	packed.pack(root)
	# pack() copies; it does not take the node. Free it or it leaks.
	root.free()
	return packed


## Shut the panel, so the next examination opens it rather than closing it.
func _close_panel(panel: Control):
	if panel != null and panel.has_method("_close"):
		panel.call("_close")


## Two frames' worth of settling: the view fades to the new reading, and
## then the objects follow it.
func _settle(scene: Node):
	scene.call("_update_readings")
	TruthLayer.advance_blend(2.0)
	scene.call("_update_readings")
