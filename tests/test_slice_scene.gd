extends RefCounted
## The Week 1–2 grey box must boot, and the mechanic must work.
##
## Nothing else in the suite loads the playable scene, so without this the
## slice could be broken in a way CI would never notice: a broken .tscn, a
## data resource that no longer loads, a pawn that lost its CharacterData.
##
## This is a smoke test, not a description of the design. The design is
## pinned down in test_perception.gd and test_truth_object.gd.

const SCENE := "res://src/world/slice.tscn"


func suite(t: TestHarness) -> void:
	t.suite("SliceScene")

	var madness := Locura.get_for(&"quixote")
	# The tag text is translated, so the assertions have to know the locale.
	var locale := TranslationServer.get_locale()
	TranslationServer.set_locale("en")

	t.test("the slice scene loads and instantiates")
	var packed: PackedScene = load(SCENE)
	t.expect_true(packed != null, "slice.tscn should load")
	if packed == null:
		return

	var scene: Node = packed.instantiate()
	var tree := Engine.get_main_loop() as SceneTree
	t.expect_true(tree != null, "there should be a scene tree")
	if tree == null:
		return
	# The scene has to go under an already-ready node, or it never gets its
	# _ready() and none of its children are built. The current scene (this
	# runner) is ready; the tree root is not, while the runner's own _ready
	# is still running.
	var parent: Node = tree.current_scene if tree.current_scene != null else tree.root
	parent.add_child(scene)

	t.test("both characters are in the scene with their data")
	var quixote: CharacterPawn = scene.get_node_or_null("Characters/Quixote")
	var sancho: CharacterPawn = scene.get_node_or_null("Characters/Sancho")
	t.expect_true(quixote != null, "Quixote should be in the scene")
	t.expect_true(sancho != null, "Sancho should be in the scene")
	if quixote == null or sancho == null:
		return
	t.expect_true(quixote.data != null, "Quixote should have his CharacterData")
	t.expect_true(sancho.data != null, "Sancho should have his CharacterData")
	t.expect_eq(quixote.character_id, &"quixote", "Quixote's id")
	t.expect_eq(sancho.character_id, &"sancho", "Sancho's id")
	t.expect_eq(quixote.data.truth_layer_affinity, 1, "Quixote is Book-affine")
	t.expect_eq(sancho.data.truth_layer_affinity, 0, "Sancho is Reality-affine")

	t.test("both primitives carry both forms")
	var windmill: TruthObject = scene.get_node_or_null("Windmill")
	var rock: TruthObject = scene.get_node_or_null("Rock")
	t.expect_true(windmill != null and rock != null, "the two primitives should be in the scene")
	if windmill == null or rock == null:
		return
	t.expect_true(windmill.data != null and rock.data != null, "the primitives should carry their data")
	t.expect_true(windmill.data.reality_form != null, "the windmill has a Reality form")
	t.expect_true(windmill.data.book_form != null, "the windmill has a Book form")
	t.expect_true(rock.data.reality_form != null, "the rock has a Reality form")
	t.expect_true(rock.data.book_form != null, "the rock has a Book form")

	t.test("the player drives Quixote and the AI drives Sancho")
	var controller: PlayerController = scene.get_node_or_null("PlayerController")
	t.expect_true(controller != null, "the player controller should be in the scene")
	if controller == null:
		return
	t.expect_eq(controller.active_pawn, quixote, "the player starts with Quixote")
	t.expect_eq(controller.other_pawn, sancho, "Sancho is the companion")

	t.test("the camera follows the character you are driving")
	var rig: CameraFollow = scene.get_node_or_null("CameraRig")
	t.expect_true(rig != null, "the camera rig should be in the scene")
	if rig != null:
		t.expect_eq(rig.target, quixote, "the camera starts on Quixote")

	t.test("a Reality world shows the Reality forms")
	TruthLayer.shift_to(TruthLayer.Layer.REALITY, true)
	Locura.set_for(&"quixote", 10.0)
	_settle(scene)
	t.expect_true(windmill.form_for(0).visible, "the windmill is a windmill")
	t.expect_false(windmill.form_for(1).visible, "and not a giant")
	t.expect_true(rock.form_for(0).visible, "the rock is a rock")
	t.expect_false(rock.form_for(1).visible, "and not a book")

	t.test("the tag says what the companion is looking at")
	# While you drive Quixote, the tag over the windmill says what Sancho
	# makes of it. In a Reality world he sees a windmill, like you.
	var tag: String = windmill.tag_text()
	t.expect_true(tag.contains("Sancho"), "the tag should name the companion, got '%s'" % tag)
	t.expect_true(tag.contains("windmill"), "the tag should say Sancho sees a windmill, got '%s'" % tag)

	t.test("a Book world shows the Book forms")
	TruthLayer.shift_to(TruthLayer.Layer.BOOK, true)
	_settle(scene)
	t.expect_true(windmill.form_for(1).visible, "the windmill is a giant")
	t.expect_true(rock.form_for(1).visible, "the rock is a book")

	t.test("swapping characters changes what you see")
	# This is the mechanic. Same world, two readings: looking through
	# Sancho's eyes, the giant is a windmill again. He has no second sight
	# in the slice, so he cannot see the Book at all.
	t.expect_false(sancho.second_sight, "Sancho starts without the second sight")
	controller.request_swap()
	_settle(scene)
	t.expect_eq(controller.active_pawn, sancho, "Sancho is being driven")
	t.expect_true(windmill.form_for(0).visible, "for Sancho the giant is a windmill")
	t.expect_false(windmill.form_for(1).visible, "and there is no giant to be seen")
	t.expect_true(rock.form_for(0).visible, "for Sancho the book is a rock")

	t.test("the tag says what the other one is looking at")
	# You are driving Sancho now, so the tag is about Quixote — and Quixote
	# still sees the giant, because the world is in the Book.
	var swapped_tag: String = windmill.tag_text()
	t.expect_true(swapped_tag.contains("Don Quixote"), "the tag should name Quixote, got '%s'" % swapped_tag)
	t.expect_true(swapped_tag.contains("giant"), "the tag should say Quixote sees a giant, got '%s'" % swapped_tag)

	t.test("the second sight makes them agree")
	sancho.second_sight = true
	_settle(scene)
	t.expect_true(windmill.form_for(1).visible, "with the lens Sancho sees the giant too")
	sancho.second_sight = false
	_settle(scene)

	t.test("the camera and the AI follow the swap")
	t.expect_eq(rig.target, sancho, "the camera moved to Sancho")
	var ai: CompanionAI = scene.get_node_or_null("CompanionAI")
	if ai != null:
		t.expect_eq(ai.pawn, quixote, "the AI drives Quixote now")

	# Leave the world as we found it.
	controller.request_swap()
	_settle(scene)
	TruthLayer.shift_to(TruthLayer.Layer.REALITY, true)
	Locura.set_for(&"quixote", madness)
	TruthLayer.set_view_layer(-1)
	TranslationServer.set_locale(locale)

	parent.remove_child(scene)
	scene.free()


## Two frames' worth of settling: the view fades to the new reading, and
## then the objects follow it. The real game gets this from _process.
func _settle(scene: Node) -> void:
	scene.call("_update_readings")
	TruthLayer.advance_blend(2.0)
	scene.call("_update_readings")
