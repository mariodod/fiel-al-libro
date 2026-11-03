extends Node
## Performance test runner for min-spec hardware (GDD.md Phase 1 milestone).
##
## Loads the slice scene and measures frame rate over a window of time.
## Reports min/avg/max FPS to stdout.
##
## Usage: godot --headless res://tests/test_performance.tscn

const TEST_SCENE := "res://src/world/slice.tscn"
const TEST_DURATION_SECONDS := 15.0
const WARMUP_SECONDS := 2.0

var _scene: PackedScene = null
var _instance: Node = null
var _frame_times: Array[float] = []
var _start_time: float = 0.0
var _test_done: bool = false

func _ready():
	print("=== Fiel al Libro — Performance Test ===")
	print("Scene: %s" % [TEST_SCENE])
	print("Duration: %d seconds" % [TEST_DURATION_SECONDS])
	print("")
	
	_scene = load(TEST_SCENE)
	if _scene == null:
		print("ERROR: Could not load %s" % [TEST_SCENE])
		get_tree().quit(1)
		return
	
	_instance = _scene.instantiate()
	add_child(_instance)
	
	_start_time = Time.get_ticks_msec() / 1000.0
	
	print("Performance test started... measuring %d seconds" % [TEST_DURATION_SECONDS])

func _process(_delta: float):
	if _test_done:
		return
	
	var now := Time.get_ticks_msec() / 1000.0
	var elapsed := now - _start_time
	
	if elapsed < WARMUP_SECONDS:
		return  # Skip warmup frames
	
	_frame_times.append(_delta)
	
	if elapsed >= WARMUP_SECONDS + TEST_DURATION_SECONDS:
		_finish_test()

func _finish_test():
	_test_done = true
	
	if _frame_times.is_empty():
		print("ERROR: No frames measured")
		get_tree().quit(1)
		return
	
	var total_time := 0.0
	var min_time := 999.0
	var max_time := 0.0
	for t in _frame_times:
		total_time += t
		if t < min_time:
			min_time = t
		if t > max_time:
			max_time = t
	
	var avg_time := total_time / _frame_times.size()
	var min_fps := 1.0 / max_time
	var max_fps := 1.0 / min_time
	var avg_fps := 1.0 / avg_time
	
	var target_fps := 30.0
	var passed := avg_fps >= target_fps
	
	print("")
	print("=== Results ===")
	print("Frames measured: %d" % [_frame_times.size()])
	print("Min frame time: %.3f ms (%.1f FPS)" % [min_time * 1000.0, max_fps])
	print("Avg frame time: %.3f ms (%.1f FPS)" % [avg_time * 1000.0, avg_fps])
	print("Max frame time: %.3f ms (%.1f FPS)" % [max_time * 1000.0, min_fps])
	print("")
	print("Target: >= %.0f FPS" % [target_fps])
	if passed:
		print("RESULT: PASS — %.1f FPS >= 30 FPS" % [avg_fps])
	else:
		print("RESULT: FAIL — %.1f FPS < 30 FPS" % [avg_fps])
	
	var below_target := 0
	for t in _frame_times:
		if 1.0 / t < target_fps:
			below_target += 1
	print("Frames below %.0f FPS: %d (%.1f%%)" % [target_fps, below_target, 100.0 * below_target / _frame_times.size()])
	
	get_tree().quit(0 if passed else 1)
