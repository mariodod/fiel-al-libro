extends ColorRect
## The post-process pass.
##
## A full-rect ColorRect on a high CanvasLayer, running the truth-layer
## shader over the rendered frame. The ColorRect MUST cover the whole
## viewport because the shader samples the screen texture in screen space.
##
## ── Gotcha, learned the hard way ───────────────────────────────────────
## A Control under a CanvasLayer has no Control parent. That means:
##   - the anchor preset alone does not give it a size (it stays 0x0), and
##   - it is not told when the window is resized.
## A 0x0 ColorRect is invisible, and the shader never runs — the game
## looks flat and nobody notices, because "flat" is what a grey box looks
## like. Drive the size from the viewport instead.
##
## See assets/shaders/truth_layer.gdshader.

@export var shader_path: String = "res://assets/shaders/truth_layer.gdshader"


func _ready() -> void:
	# Ignore mouse input so it never eats clicks.
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	color = Color(1, 1, 1, 1)

	set_anchors_preset(Control.PRESET_TOP_LEFT)
	position = Vector2.ZERO
	_fit_to_viewport()

	var viewport := get_viewport()
	if viewport != null and not viewport.size_changed.is_connected(_fit_to_viewport):
		viewport.size_changed.connect(_fit_to_viewport)

	if shader_path != "" and ResourceLoader.exists(shader_path):
		var shader: Shader = load(shader_path)
		var mat := ShaderMaterial.new()
		mat.shader = shader
		material = mat
	else:
		push_warning("[PostProcess] Shader not found at '%s'." % shader_path)


## Cover the whole visible area.
func _fit_to_viewport() -> void:
	var viewport := get_viewport()
	if viewport == null:
		return
	size = viewport.get_visible_rect().size
