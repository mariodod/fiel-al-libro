extends ColorRect
## The post-process pass.
##
## A full-rect ColorRect on a high CanvasLayer, running the truth-layer
## shader over the rendered frame. The ColorRect MUST cover the whole
## viewport (full-rect anchors) because the shader samples the screen
## texture in screen space.
##
## See assets/shaders/truth_layer.gdshader.

@export var shader_path: String = "res://assets/shaders/truth_layer.gdshader"


func _ready() -> void:
	# Full-rect anchors, and ignore mouse input so it never eats clicks.
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	color = Color(1, 1, 1, 1)

	if shader_path != "" and ResourceLoader.exists(shader_path):
		var shader: Shader = load(shader_path)
		var mat := ShaderMaterial.new()
		mat.shader = shader
		material = mat
	else:
		push_warning("[PostProcess] Shader not found at '%s'." % shader_path)
