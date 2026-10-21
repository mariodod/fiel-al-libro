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
## ── The page turn ──────────────────────────────────────────────────────
## When the world's truth flips, a sheet of paper crosses the screen
## carrying a line of the 1605 original. See GDD.md §4.3: "Pages curl",
## and "the occasional line of the actual 1605 Spanish text, faint, as if
## the world is being written under your feet".
##
## The 1605 original is CONTENT: it is the same in every build, in every
## language, because it is a quotation and not a translation (GDD.md §20).
## The sheet is printed from the Manifiesto data, not from a translation.
##
## See assets/shaders/truth_layer.gdshader.

@export var shader_path: String = "res://assets/shaders/truth_layer.gdshader"

## The Manifiesto fragment the sheet is printed from.
##
## NOTE: it must not start with an underscore. Godot treats a file whose
## name starts with '_' as hidden, so it never enters the FileSystem and
## FileAccess cannot open it. A file the game reads has to be a file the
## game can see.
@export var page_source: String = "res://assets/manifiesto/bk.ch01.apertura.json"
## The field of that fragment holding the 1605 original.
@export var page_field: String = "original_1605"

## Seconds for the sheet to cross the screen. It has to keep up with the
## truth blend (0.3s) or the page and the world change feel like two
## different events.
@export var page_seconds: float = 0.42

var _material: ShaderMaterial = null
var _page_turn: float = 0.0
var _turning: bool = false
var _page_texture: ImageTexture = null
var _text_viewport: SubViewport = null
var _text_pending: bool = true


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
		_material = ShaderMaterial.new()
		_material.shader = shader
		material = _material
	else:
		push_warning("[PostProcess] Shader not found at '%s'." % shader_path)

	EventBus.truth_blend_started.connect(_on_truth_blend_started)


## Cover the whole visible area.
func _fit_to_viewport() -> void:
	var viewport := get_viewport()
	if viewport == null:
		return
	size = viewport.get_visible_rect().size


func _process(delta: float) -> void:
	if _text_pending:
		_text_pending = false
		_build_page_texture()
	if not _turning:
		return
	_page_turn = minf(1.0, _page_turn + delta / maxf(page_seconds, 0.05))
	if _page_turn >= 1.0:
		_turning = false
	if _material != null:
		_material.set_shader_parameter(&"page_turn", _page_turn)


## The world is turning a page.
func _on_truth_blend_started(_layer: int) -> void:
	_page_turn = 0.0
	_turning = true


# ── The printed sheet ──────────────────────────────────────────────────

## Print the 1605 original onto a sheet of paper.
##
## The text is drawn into a SubViewport once and kept as a texture, so the
## shader can scroll it across the screen with the sheet.
func _build_page_texture() -> void:
	var line := _load_1605_line()
	if line.is_empty():
		return

	_text_viewport = SubViewport.new()
	_text_viewport.name = "PageText"
	_text_viewport.size = Vector2i(1024, 576)
	_text_viewport.transparent_bg = true
	_text_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_text_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	add_child(_text_viewport)

	var label := Label.new()
	label.name = "Line"
	label.size = Vector2(928, 480)
	label.position = Vector2(48, 48)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color(0.17, 0.13, 0.10, 1.0))
	label.text = line
	_text_viewport.add_child(label)

	# The viewport has to be drawn once before its texture has anything in
	# it. This has to happen after the node is in the tree, so it is done
	# on the next frame.
	await RenderingServer.frame_post_draw
	if not is_instance_valid(_text_viewport):
		push_warning("[PostProcess] The page text viewport went away.")
		return
	var image := _text_viewport.get_texture().get_image()
	if image == null:
		push_warning("[PostProcess] Could not read the page text texture.")
		return
	_page_texture = ImageTexture.create_from_image(image)
	if _material != null:
		_material.set_shader_parameter(&"page_text", _page_texture)
		_material.set_shader_parameter(&"page_text_amount", 1.0)


## The 1605 original, out of the Manifiesto data.
##
## It is content, not translation: the same words in every build.
func _load_1605_line() -> String:
	if not FileAccess.file_exists(page_source):
		return ""
	var file := FileAccess.open(page_source, FileAccess.READ)
	if file == null:
		return ""
	var text := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return ""
	return str((parsed as Dictionary).get(page_field, ""))
