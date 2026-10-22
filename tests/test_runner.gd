extends Node
## Headless test runner.
##
## Run from the project root:
##   godot --headless res://tests/test_runner.tscn
##
## The suite is run as a SCENE, not via `--script`, so that Godot's
## autoloads (EventBus, TruthLayer, Locura, Manuscrito, ...) exist exactly
## as they do in a real run. This is the same command CI uses.
##
## Exit code 0 = all green, 1 = at least one failure.

const SUITES: Array[String] = [
	"res://tests/test_truth_layer.gd",
	"res://tests/test_perception.gd",
	"res://tests/test_truth_object.gd",
	"res://tests/test_locura.gd",
	"res://tests/test_memoria.gd",
	"res://tests/test_biblioteca.gd",
	"res://tests/test_manuscrito.gd",
	"res://tests/test_ending.gd",
	"res://tests/test_locales.gd",
	"res://tests/test_translations.gd",
	"res://tests/test_slice_scene.gd",
	"res://tests/test_examine.gd",
	"res://tests/test_reaction.gd",
	"res://tests/test_verbs.gd",
	"res://tests/test_training_dummy.gd",
	"res://tests/test_lock_on.gd",
	"res://tests/test_chatter.gd",
	"res://tests/test_asymmetry.gd",
	"res://tests/test_rigs.gd",
	"res://tests/test_animation.gd",
	"res://tests/test_companion.gd",
	"res://tests/test_manifiesto_content.gd",
	"res://tests/test_playtest_fixes.gd",
	"res://tests/test_venture.gd",
	"res://tests/test_map_screen.gd",
]

var harness := TestHarness.new()


func _ready() -> void:
	for suite_path: String in SUITES:
		if not ResourceLoader.exists(suite_path):
			push_error("[TestRunner] Missing suite: %s" % suite_path)
			harness.failures.append("[TestRunner] Missing suite: %s" % suite_path)
			continue
		var script: Script = load(suite_path)
		# A suite with a parse error still loads as a GDScript object, but
		# it cannot be instantiated. Catching that HERE matters: otherwise
		# the runner dies mid-_ready, never calls quit(), and CI hangs
		# forever instead of failing. A broken suite is a failure, not a
		# hang.
		if script == null or not script.can_instantiate():
			push_error("[TestRunner] %s failed to load" % suite_path)
			harness.failures.append("[TestRunner] %s failed to load" % suite_path)
			continue
		var instance: Object = script.new()
		if instance == null or not instance.has_method("suite"):
			push_error("[TestRunner] %s has no suite() method" % suite_path)
			harness.failures.append("[TestRunner] %s has no suite() method" % suite_path)
			continue
		instance.call("suite", harness)

	_report()
	# In Godot 4 the exit code is passed to quit(); there is no
	# OS.set_exit_code().
	var code := 1 if harness.failures.size() > 0 else 0
	get_tree().quit(code)


func _report() -> void:
	print("")
	print("─── Fiel al Libro — test report ───")
	print("suites   : %d" % SUITES.size())
	print("asserts  : %d" % harness.assertions)
	print("failures : %d" % harness.failures.size())
	for failure: String in harness.failures:
		print("  ✗ %s" % failure)
	if harness.failures.is_empty():
		print("  ✓ all green")
	print("──────────────────────────────────")
	print("")
