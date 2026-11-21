extends RefCounted
const TestHarness = preload("res://tests/test_harness.gd")
## GDD §15.4: two OFL fonts — Noto Sans for UI, EB Garamond for the Book
## layer — with a system fallback for scripts they do not cover.

func suite(t):
	t.suite("Fonts")

	t.test("the theme autoload is registered")
	var autoloads: Variant = ProjectSettings.get_setting("autoload/ThemeApplier", "")
	t.expect_false(str(autoloads).is_empty(), "ThemeApplier autoload present")

	t.test("both OFL font files ship with their licenses")
	for name in ["NotoSans-Regular.ttf", "EBGaramond-Regular.ttf",
			"OFL-NotoSans.txt", "OFL-EBGaramond.txt"]:
		t.expect_true(FileAccess.file_exists("res://assets/fonts/" + name),
			"%s exists" % name)

	t.test("the theme wires the fonts into the UI types")
	var theme: Theme = load("res://assets/themes/default.tres")
	t.expect_true(theme != null, "theme loads")
	if theme == null:
		return
	var ui: Font = theme.default_font
	t.expect_true(ui != null, "default UI font set")
	t.expect_true(theme.has_font("font", "Label"), "Label font defined")
	t.expect_true(theme.has_font("font", "BookText"), "Book font defined")
	t.expect_true(theme.has_font("font", "SystemFallback"), "CJK/RTL fallback defined")

	t.test("the fonts render real glyphs")
	if ui != null:
		t.expect_gt(ui.get_string_size(" Lectura ").x, 0.0, "UI font has metrics")
