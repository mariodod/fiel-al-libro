extends Node
const TestHarness = preload("res://tests/test_harness.gd")
## Performance test for min-spec hardware (GDD.md Phase 1 milestone).
##
## Loads the slice scene and measures frame rate over a window of time.
## Reports min/avg/max FPS to stdout.
##
## Usage: Included in test_runner as a suite.

const TEST_SCENE := "res://src/world/slice.tscn"
const TEST_DURATION_SECONDS := 10.0
const WARMUP_FRAMES := 60  # ~2 seconds at 30 FPS

var _scene: PackedScene = null
var _instance: Node = null

func suite(t):
	t.suite("Performance")
	
	# Get the scene tree (Engine.get_main_loop() works even before being added to tree)
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		print("ERROR: Could not get scene tree")
		return
	
	# Add self to tree so _process fires if needed
	tree.get_root().add_child(self)
	
	# Load and instantiate the slice scene
	_scene = load(TEST_SCENE)
	if _scene == null:
		print("ERROR: Could not load %s" % [TEST_SCENE])
		return
	
	_instance = _scene.instantiate()
	tree.get_root().add_child(_instance)
	
	print("=== Fiel al Libro — Performance Test ===")
	print("Scene: %s" % [TEST_SCENE])
	print("Duration: %d seconds" % [TEST_DURATION_SECONDS])
	print("")
	
	# Warmup: skip initial frames
	print("Warming up (%d frames)..." % [WARMUP_FRAMES])
	for i in range(WARMUP_FRAMES):
		await get_tree().idle_frame
	
	# Measure frame times over the test duration
	var start_ms := Time.get_ticks_msec()
	var frame_count := 0
	
	while Time.get_ticks_msec() - start_ms < TEST_DURATION_SECONDS * 1000:
		await get_tree().idle_frame
		frame_count += 1
	
	var elapsed_ms := Time.get_ticks_msec() - start_ms
	var elapsed_sec := elapsed_ms / 1000.0
	var avg_fps := frame_count / elapsed_sec
	
	print("")
	print("=== Results ===")
	print("Frames measured: %d" % [frame_count])
	print("Elapsed: %.2f s" % [elapsed_sec])
	print("Average FPS: %.1f" % [avg_fps])
	print("")
	print("Target: >= 30.0 FPS")
	
	var passed := avg_fps >= 30.0
	if passed:
		print("RESULT: PASS — %.1f FPS >= 30 FPS" % [avg_fps])
	else:
		print("RESULT: FAIL — %.1f FPS < 30 FPS" % [avg_fps])
	
	# Clean up
	if _instance != null:
		_instance.queue_free()
		_instance = null
		queue_free()
