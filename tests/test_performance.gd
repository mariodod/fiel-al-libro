extends Node
## Performance test — measures frame time by manually driving the scene tree.
##
## Run from the project root:
##   godot --headless res://tests/test_performance.tscn
##
## Exit code 0 = meets target, 1 = below target.

const TestHarness = preload("res://tests/test_harness.gd")

## Target FPS per NEXT_STEPS.md §2.23.
const TARGET_FPS := 30.0
## Ideal FPS per NEXT_STEPS.md §2.23.
const IDEAL_FPS := 60.0
## Number of frames to measure.
const FRAME_COUNT := 300


func _ready() -> void:
	var t = TestHarness.new()
	t.suite("Performance")

	# Load the slice scene — the main gameplay scene.
	var packed = load("res://src/world/slice.tscn")
	if packed == null:
		t.expect_true(false, "slice.tscn should load")
		_report(t)
		return

	var scene = packed.instantiate()
	# Root is busy during _ready — defer adding the child (HANDOVER §7.9).
	call_deferred("_run_performance_test", scene, t)


func _run_performance_test(scene: Node, t: TestHarness) -> void:
	var tree = get_tree()
	if tree != null:
		tree.root.add_child(scene)

	# Let things settle for a few frames.
	for i in range(10):
		await get_tree().process_frame

	# Measure frames — actually advancing the tree each frame.
	var _frame_times: Array[float] = []
	for i in range(FRAME_COUNT):
		var start: float = Time.get_ticks_msec() / 1000.0
		await get_tree().process_frame
		var elapsed: float = Time.get_ticks_msec() / 1000.0 - start
		_frame_times.append(elapsed)

	if _frame_times.is_empty():
		t.expect_true(false, "no frame times measured")
		_report(t)
		return

	var total_time: float = 0.0
	var min_time: float = _frame_times[0]
	var max_time: float = _frame_times[0]
	for ft in _frame_times:
		total_time += ft
		if ft < min_time:
			min_time = ft
		if ft > max_time:
			max_time = ft

	var avg_frame_time: float = total_time / _frame_times.size()
	var avg_fps: float = 1.0 / avg_frame_time if avg_frame_time > 0 else 0.0
	var min_fps: float = 1.0 / max_time if max_time > 0 else 0.0
	var max_fps: float = 1.0 / min_time if min_time > 0 else 0.0

	print("")
	print("─── Performance report ───")
	print("frames measured: %d" % _frame_times.size())
	print("avg fps: %.1f" % avg_fps)
	print("min fps: %.1f" % min_fps)
	print("max fps: %.1f" % max_fps)
	print("avg frame time: %.2f ms" % (avg_frame_time * 1000.0))
	print("min frame time: %.2f ms" % (min_time * 1000.0))
	print("max frame time: %.2f ms" % (max_time * 1000.0))
	print("target fps: %.0f (min), %.0f (ideal)" % [TARGET_FPS, IDEAL_FPS])
	print("─────────────────────────")

	t.expect_gt(avg_fps, TARGET_FPS * 0.9, "average FPS should be at least %.0f" % TARGET_FPS)
	t.expect_gt(min_fps, TARGET_FPS * 0.7, "minimum FPS should stay above %.0f" % (TARGET_FPS * 0.7))

	if avg_fps >= IDEAL_FPS:
		print("RESULT: EXCELLENT — meets ideal %.0f fps target" % IDEAL_FPS)
	elif avg_fps >= TARGET_FPS:
		print("RESULT: GOOD — meets minimum %.0f fps target" % TARGET_FPS)
	else:
		print("RESULT: POOR — below %.0f fps target" % TARGET_FPS)

	_report(t)
	get_tree().quit(0)


func _report(harness: TestHarness) -> void:
	print("")
	print("─── Fiel al Libro — test report ───")
	print("suites   : 1")
	print("asserts  : %d" % harness.assertions)
	print("failures : %d" % harness.failures.size())
	for failure: String in harness.failures:
		print("  ✗ %s" % failure)
	if harness.failures.is_empty():
		print("  ✓ all green")
	print("──────────────────────────────────")
	print("")

	var code := 1 if harness.failures.size() > 0 else 0
	get_tree().quit(code)
