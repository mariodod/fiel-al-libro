extends RefCounted
const TestHarness = preload("res://tests/test_harness.gd")
## GDD §5.4: mounts are a chase system — ride, dismount to investigate;
## Dapple is obstinate and throwable. GDD §4.3: the Ink grows with progress.

const MOUNT_SCRIPT := preload("res://src/systems/mount_controller.gd")

func suite(t):
	t.suite("MountsAndInk")

	var tree := Engine.get_main_loop() as SceneTree
	var parent: Node = tree.current_scene
	var controller: Node = MOUNT_SCRIPT.new()
	parent.add_child(controller)

	var pawn := CharacterPawn.new()
	pawn.name = "ProbePawn"
	pawn.character_id = &"quixote"
	parent.add_child(pawn)

	t.test("a mount can be summoned and grants a speed bonus")
	var base := pawn.walk_speed()
	t.expect_true(controller.call("mount", pawn, Vector3.ZERO), "Rocinante summoned")
	t.expect_eq(str(controller.get("mount_id")), "rocinante", "Quixote rides Rocinante")
	t.expect_gt(pawn.walk_speed(), base, "mounted walking is faster")
	t.expect_true(pawn.mounted, "pawn knows it is mounted")

	t.test("dismounting restores normal speed")
	controller.call("dismount")
	t.expect_false(pawn.mounted, "pawn is on foot")
	t.expect_almost_eq(pawn.walk_speed(), base, 0.01, "speed restored")

	t.test("Dapple is obstinate but Rocinante is not")
	pawn.character_id = &"sancho"
	controller.call("mount", pawn, Vector3.ZERO)
	t.expect_eq(str(controller.get("mount_id")), "dapple", "Sancho rides Dapple")
	t.expect_true(controller.call("is_obstinate_at", Vector3(0, 0, -30)), "Dapple refuses")
	t.expect_true(controller.call("throw_dapple", Vector3.FORWARD), "Dapple can be thrown")
	t.expect_false(bool(controller.get("mounted")), "throwing dismounts")

	t.test("the Ink follows campaign progress and verdict insistence")
	var old_chapters := GameState.chapters_resolved.duplicate()
	GameState.chapters_resolved.clear()
	TruthLayer.set_ink(0.0)
	ChapterFlow.call("_refresh_ink")
	var early := TruthLayer.ink_amount()
	for i in range(RegionGraph.all_chapters().size()):
		GameState.chapter_started(StringName("probe_%d" % i))
		GameState.chapter_completed(StringName("probe_%d" % i))
	ChapterFlow.call("_refresh_ink")
	t.expect_gt(TruthLayer.ink_amount(), early, "the Ink spreads as pages are written")
	GameState.chapters_resolved = old_chapters
	TruthLayer.set_ink(0.0)

	parent.remove_child(pawn)
	pawn.free()
	parent.remove_child(controller)
	controller.free()
