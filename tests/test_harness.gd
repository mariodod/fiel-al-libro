class_name TestHarness
extends RefCounted
## A tiny, dependency-free test harness.
##
## Deliberately not GUT: GUT is an addon you have to install, and this
## project must run its whole CI on a fresh clone with nothing but Godot
## and Python. If you outgrow this, swap in GUT — the suite files are
## written so that only the `suite()` signature changes.
##
## See TECH_STACK.md §6.

var failures: Array[String] = []
var assertions: int = 0
var _current_suite: String = ""
var _current_test: String = ""


func suite(name: String) -> void:
	_current_suite = name


func test(name: String) -> void:
	_current_test = name


func _record(ok: bool, message: String) -> void:
	assertions += 1
	if not ok:
		var where := "%s / %s" % [_current_suite, _current_test]
		failures.append("%s: %s" % [where, message])


func expect_true(condition: bool, message: String = "expected true") -> void:
	_record(condition, message)


func expect_false(condition: bool, message: String = "expected false") -> void:
	_record(not condition, message)


func expect_eq(actual: Variant, expected: Variant, message: String = "") -> void:
	var ok: bool = actual == expected
	var detail := message if not message.is_empty() else "expected %s, got %s" % [str(expected), str(actual)]
	_record(ok, detail)


func expect_ne(actual: Variant, unexpected: Variant, message: String = "") -> void:
	var ok: bool = actual != unexpected
	var detail := message if not message.is_empty() else "did not expect %s" % str(unexpected)
	_record(ok, detail)


func expect_almost_eq(actual: float, expected: float, tolerance: float = 0.001, message: String = "") -> void:
	var ok := absf(actual - expected) <= tolerance
	var detail := message if not message.is_empty() else "expected ~%f, got %f" % [expected, actual]
	_record(ok, detail)


func expect_gt(actual: float, threshold: float, message: String = "") -> void:
	var ok := actual > threshold
	var detail := message if not message.is_empty() else "expected > %f, got %f" % [threshold, actual]
	_record(ok, detail)


func expect_in_range(actual: float, low: float, high: float, message: String = "") -> void:
	var ok := actual >= low and actual <= high
	var detail := message if not message.is_empty() else "expected %f..%f, got %f" % [low, high, actual]
	_record(ok, detail)


func expect_has(collection: Array, item: Variant, message: String = "") -> void:
	var ok: bool = collection.has(item)
	var detail := message if not message.is_empty() else "expected collection to contain %s" % str(item)
	_record(ok, detail)


func expect_not_has(collection: Array, item: Variant, message: String = "") -> void:
	var ok: bool = not collection.has(item)
	var detail := message if not message.is_empty() else "expected collection NOT to contain %s" % str(item)
	_record(ok, detail)
