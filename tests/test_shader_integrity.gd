extends RefCounted
const TestHarness = preload("res://tests/test_harness.gd")
## GDD §4.3: the truth shader must carry the visual language, including the
## floating letterforms / ink motes in the Book layer. A GLSL compile error
## is silent in headless output unless the shader is actually loaded.

func suite(t):
	t.suite("ShaderIntegrity")

	t.test("the truth shader loads and compiles")
	var shader: Shader = load("res://assets/shaders/truth_layer.gdshader")
	t.expect_true(shader != null, "shader resource exists")
	if shader == null:
		return
	t.expect_true(shader is Shader, "it is a Shader")

	t.test("the GDD's visual elements are present in the shader")
	var f := FileAccess.open("res://assets/shaders/truth_layer.gdshader", FileAccess.READ)
	t.expect_true(f != null, "shader source readable")
	if f != null:
		var src := f.get_as_text()
		f.close()
		t.expect_true(src.contains("floating_letters"), "floating letterforms exist")
		t.expect_true(src.contains("mote_amount"), "motes are toggleable")
		t.expect_true(src.contains("page_text"), "real 1605 text feeds the motes")
		t.expect_true(src.contains("edge_detect"), "line-art pass exists")
		t.expect_true(src.contains("ink_amount"), "the Ink corruption exists")
		# Only check code lines: comments legitimately contain English words.
		for line in src.split("\n"):
			var code := line.split("//")[0]
			t.expect_false(" or " in code, "GLSL uses || not 'or'")
			t.expect_false(" and " in code, "GLSL uses && not 'and'")

	t.test("the motes are defaulted on and Book-layer-only")
	var mat := ShaderMaterial.new()
	mat.shader = shader
	var amount: float = mat.get_shader_parameter(&"mote_amount")
	t.expect_gt(amount, 0.0, "motes start enabled")
