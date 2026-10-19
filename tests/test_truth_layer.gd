extends RefCounted
## D2: the truth layer is global, and it round-trips through the save file.

func suite(t: TestHarness) -> void:
	t.suite("TruthLayer")

	t.test("starts in Reality")
	TruthLayer.shift_to(TruthLayer.Layer.REALITY, true)
	t.expect_true(TruthLayer.is_reality(), "should be in Reality")
	t.expect_false(TruthLayer.is_book(), "should not be in Book")

	t.test("shifts to Book instantly")
	TruthLayer.shift_to(TruthLayer.Layer.BOOK, true)
	t.expect_true(TruthLayer.is_book(), "should be in Book")
	t.expect_eq(TruthLayer.layer(), TruthLayer.Layer.BOOK, "layer() should report BOOK")

	t.test("toggle flips the layer")
	# toggle() starts a CROSS-FADE, not a snap — the blend is the point.
	# So the target changes immediately and the visible layer catches up.
	TruthLayer.toggle()
	t.expect_eq(TruthLayer.target_layer(), TruthLayer.Layer.REALITY, "target should be Reality")
	t.expect_eq(TruthLayer.layer(), TruthLayer.Layer.BOOK, "visible layer is still fading")
	TruthLayer.toggle()
	t.expect_eq(TruthLayer.target_layer(), TruthLayer.Layer.BOOK, "target should be Book")

	t.test("an instant shift snaps both")
	TruthLayer.shift_to(TruthLayer.Layer.REALITY, true)
	t.expect_eq(TruthLayer.layer(), TruthLayer.Layer.REALITY, "snapped to Reality")
	t.expect_eq(TruthLayer.target_layer(), TruthLayer.Layer.REALITY, "target followed")

	t.test("save/load round-trips the layer")
	TruthLayer.shift_to(TruthLayer.Layer.BOOK, true)
	var saved: Dictionary = TruthLayer.save_state()
	TruthLayer.shift_to(TruthLayer.Layer.REALITY, true)
	t.expect_eq(TruthLayer.layer(), TruthLayer.Layer.REALITY, "moved away before loading")
	TruthLayer.load_state(saved)
	t.expect_eq(TruthLayer.layer(), TruthLayer.Layer.BOOK, "layer should survive a save/load")
	t.expect_eq(TruthLayer.target_layer(), TruthLayer.Layer.BOOK, "target should survive too")

	t.test("ink amount is clamped")
	TruthLayer.set_ink(2.5)
	t.expect_almost_eq(TruthLayer.ink_amount(), 1.0, 0.0001, "ink should clamp to 1.0")
	TruthLayer.set_ink(-1.0)
	t.expect_almost_eq(TruthLayer.ink_amount(), 0.0, 0.0001, "ink should clamp to 0.0")
	TruthLayer.set_ink(0.0)

	t.test("the camera can be filtered to a truth of its own")
	# The world's truth is global and never moves because of this. But a
	# camera is a person's eyes: look through Sancho's while the world is
	# in Book Truth, and the picture is filtered the way Sancho filters it.
	TruthLayer.shift_to(TruthLayer.Layer.REALITY, true)
	TruthLayer.set_view_layer(TruthLayer.Layer.BOOK)
	TruthLayer.advance_blend(2.0)
	t.expect_almost_eq(TruthLayer.view_blend(), 1.0, 0.0001, "the view fades to the Book")
	t.expect_eq(TruthLayer.layer(), TruthLayer.Layer.REALITY, "the world's truth has not moved")

	t.test("releasing the view follows the world again")
	TruthLayer.set_view_layer(-1)
	TruthLayer.advance_blend(2.0)
	t.expect_almost_eq(TruthLayer.view_blend(), 0.0, 0.0001, "the view falls back to the world")
	t.expect_eq(TruthLayer.layer(), TruthLayer.Layer.REALITY, "the world's truth is still Reality")

	# Leave the world in a known state for the next suite.
	TruthLayer.shift_to(TruthLayer.Layer.REALITY, true)
