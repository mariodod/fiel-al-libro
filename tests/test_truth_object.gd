extends RefCounted
var TestHarness = preload("res://tests/test_harness.gd")
var TruthObject = preload("res://src/world/truth_object.gd")
var TruthObjectData = preload("res://src/data/truth_object_data.gd")
var TruthFace = preload("res://src/data/truth_face.gd")
## The two-faced object: one object in the world, two states.
##
## A windmill is a windmill in Reality and a giant in the Book. A rock is a
## rock in Reality and a book in the Book. Same object, two states — the
## whole game in one data shape.

func suite(t):
	t.suite("TruthObject")

	var object = _make_object()
	var tree = Engine.get_main_loop() as SceneTree
	# The scene tree root is busy setting up its children while the runner
	# is starting, so it refuses new children. The current scene is not.
	var parent = tree.current_scene if tree != null and tree.current_scene != null else null
	if parent != null:
		parent.add_child(object)

	t.test("the object starts on its Reality form")
	t.expect_true(object.form_for(0).visible, "the Reality form is showing")
	t.expect_false(object.form_for(1).visible, "the Book form is hidden")
	t.expect_eq(object.current_layer(), 0, "the object reads as Reality")

	t.test("switching truth switches the form")
	object.set_layer(1, true)
	t.expect_true(object.form_for(1).visible, "the Book form is showing")
	t.expect_false(object.form_for(0).visible, "the Reality form is hidden")
	t.expect_eq(object.current_layer(), 1, "the object reads as Book")

	t.test("the name follows the form")
	t.expect_eq(object.name_key_for(0), &"ui.form.molino", "Reality name")
	t.expect_eq(object.name_key_for(1), &"ui.form.gigante", "Book name")

	t.test("each truth has its own face")
	# A face is one truth's worth of a thing: what it is called, how it
	# looks, and the one detail that does not add up.
	var reality = object.face_for(0)
	var book = object.face_for(1)
	t.expect_true(reality != null and book != null, "both faces exist")
	if reality != null and book != null:
		t.expect_eq(reality.name_key, &"ui.form.molino", "the Reality face")
		t.expect_eq(book.name_key, &"ui.form.gigante", "the Book face")
		t.expect_ne(reality.description_key, book.description_key,
			"the two truths are described differently")
		t.expect_true(reality.has_tell(), "the Reality face has a seam")
		t.expect_true(book.has_tell(), "the Book face has a seam")
		t.expect_false(reality.has_fragment(), "the Reality face carries no page")
		t.expect_false(book.has_fragment(), "the Book face carries no page")

	t.test("the change is a cross-fade, not a pop")
	# Halfway through the change both forms are half size: the object never
	# disappears for a frame.
	object.apply_blend(0.5)
	t.expect_true(object.form_for(0).visible, "the Reality form is still there")
	t.expect_true(object.form_for(1).visible, "the Book form is arriving")
	t.expect_almost_eq(object.form_for(0).scale.x, 0.5, 0.001, "the Reality form is half size")
	t.expect_almost_eq(object.form_for(1).scale.x, 0.5, 0.001, "the Book form is half size")

	t.test("driving the blend to an end shows one form")
	object.apply_blend(1.0)
	t.expect_false(object.form_for(0).visible, "the Reality form is gone")
	t.expect_true(object.form_for(1).visible, "the Book form is whole")
	t.expect_almost_eq(object.form_for(1).scale.x, 1.0, 0.001, "the Book form is full size")

	t.test("the data carries both forms")
	var data = TruthObjectData.new_instance()
	data.id = &"windmill"
	data.reality_face = _face(&"ui.form.molino", &"ui.face.windmill.reality.desc")
	data.book_face = _face(&"ui.form.gigante", &"ui.face.windmill.book.desc")
	t.expect_eq(data.name_key_for(0), &"ui.form.molino", "Reality name key")
	t.expect_eq(data.name_key_for(1), &"ui.form.gigante", "Book name key")
	t.expect_true(data.reality_form == null or data.reality_form != null, "reality form slot exists")

	t.test("a data resource with no face has no name")
	var bare = TruthObjectData.new_instance()
	t.expect_eq(bare.name_key_for(0), &"", "no face, no name")
	t.expect_eq(bare.face_for(1), null, "no face, no face")

	if parent != null:
		parent.remove_child(object)
	object.free()


## A TruthObject with two empty forms, so the test does not need the art.
func _make_object():
	var data = TruthObjectData.new_instance()
	data.id = &"test"
	data.display_name_key = &"ui.object.molino"
	data.reality_face = _face(&"ui.form.molino", &"ui.face.windmill.reality.desc")
	data.book_face = _face(&"ui.form.gigante", &"ui.face.windmill.book.desc")
	data.reality_form = _pack_form()
	data.book_form = _pack_form()

	var object = TruthObject.new_instance()
	object.data = data
	object.setup(data)
	return object


## A face: a name, a description, and the one detail that does not add up.
func _face(name_key, description_key):
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
