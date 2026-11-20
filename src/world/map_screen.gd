class_name MapScreen
extends CanvasLayer
## The world map screen.
##
## A hand-drawn portolan of Spain: five regions at their true compass
## positions, one dashed road from La Posada. It shows which regions the
## player has found and which fragments they carry, and it lets the player
## turn the world over (T) just as they can in the slice.
##
## Opened with G, closed with G or Escape.
##
## GDD.md §11.4: *"The 'libro' map screen. A hand-drawn map in the style of
## a 1605 map, with the 'Book' version and the 'Reality' version of each
## region side by side. Filling it in is a collectible."*

@export var map_texture: Texture2D

## The regions, sorted by chapter.
var regions: Array[RegionData] = []
## Region rows, keyed by region id.
var region_rows: Dictionary = {}
## Fragment markers, keyed by "<variant>|<fragment_id>" — dots on both maps.
var fragment_markers: Dictionary = {}

## Full-screen tint overlay: Book truth gilds the map, Reality chalkes it.
var truth_overlay: ColorRect = null

## The two map hosts, keyed by "reality" and "book". Both draw the same SVG
## through a different map_variant.gdshader material (GDD.md §11.4).
var map_containers: Dictionary = {}

## The source SVG is 1200x800; marker positions below are in a 600x400 space.
const MAP_SIZE := Vector2(600.0, 400.0)
const MAP_SCALE := 0.5


func _ready() -> void:
	_load_regions()
	_build_ui()
	EventBus.truth_layer_changed.connect(_on_truth_changed)
	EventBus.region_found.connect(_on_region_found)
	EventBus.codex_page_found.connect(_on_codex_page_found)
	# Set the initial overlay and passages from the current truth layer.
	_update_truth_overlay()
	_update_fantasy_labels()


## Load every region .tres in src/data/regions/.
func _load_regions() -> void:
	var dir := DirAccess.open("res://src/data/regions/")
	if dir == null:
		return
	for name in dir.get_files():
		if not name.ends_with(".tres"):
			continue
		var res: RegionData = load("res://src/data/regions/" + name)
		if res != null:
			regions.append(res)
	# Sort regions by chapter number (insertion sort — sort_custom
	# isn't reliable in this Godot build).
	for i in range(1, regions.size()):
		var key := regions[i]
		var j := i - 1
		while j >= 0 and regions[j].chapter > key.chapter:
			regions[j + 1] = regions[j]
			j -= 1
		regions[j + 1] = key


## Build the UI: map on the left, region list on the right.
func _build_ui() -> void:
	# Background: dry parchment.
	var bg := ColorRect.new()
	bg.color = Color(0.09, 0.08, 0.07, 0.96)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var container := HSplitContainer.new()
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(container)

	# ── Left: the map ──────────────────────────────────────────────
	var map_panel_vb := VBoxContainer.new()
	map_panel_vb.custom_minimum_size = Vector2(700.0, 0.0)
	container.add_child(map_panel_vb)

	var map_title := Label.new()
	map_title.text = "The world — two readings"
	map_title.add_theme_font_size_override("font_size", 20)
	map_title.add_theme_color_override("font_color", Color(0.94, 0.9, 0.8, 1.0))
	map_panel_vb.add_child(map_title)

	# Two maps, side by side. GDD.md §11.4: the Book and Reality versions of
	# each region are a collectible; one SVG, two shader grades.
	var map_host := HBoxContainer.new()
	map_host.name = "MapContainer"
	map_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_panel_vb.add_child(map_host)
	_build_variant_map(map_host, "reality", "Reality",
		Color(0.94, 0.95, 0.93, 1.0), 0.45, 1.06)
	_build_variant_map(map_host, "book", "Book",
		Color(1.0, 0.86, 0.62, 1.0), 1.35, 1.0)

	var map_hint := Label.new()
	map_hint.text = "One map, two readings — fill both in"
	map_hint.add_theme_font_size_override("font_size", 14)
	map_hint.add_theme_color_override("font_color", Color(0.75, 0.54, 0.24, 1.0))
	map_panel_vb.add_child(map_hint)

	# ── Right: the regions ─────────────────────────────────────────
	var region_panel := VBoxContainer.new()
	region_panel.custom_minimum_size = Vector2(420.0, 0.0)
	container.add_child(region_panel)

	var regions_title := Label.new()
	regions_title.text = Loc.t(&"ui.map.regions")
	regions_title.add_theme_font_size_override("font_size", 20)
	regions_title.add_theme_color_override("font_color", Color(0.94, 0.9, 0.8, 1.0))
	region_panel.add_child(regions_title)

	for res in regions:
		var row: Control = _make_region_row(res)
		region_panel.add_child(row)
		region_rows[res.id] = row

	# ── Truth overlay: full screen, changes with the truth layer ─────
	truth_overlay = ColorRect.new()
	truth_overlay.name = "TruthOverlay"
	truth_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(truth_overlay)

	# ── Bottom: close hint ─────────────────────────────────────────
	var hint := Label.new()
	hint.text = "G — close the map"
	hint.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	hint.offset_right = -18.0
	hint.offset_bottom = -18.0
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.75, 0.54, 0.24, 1.0))
	add_child(hint)

	# ── Fragment markers on both maps ────────────────────────────────
	_build_fragment_markers(map_host, null)


## Make one row in the region list.
func _make_region_row(res: RegionData) -> Control:
	var row := HBoxContainer.new()
	row.name = "RegionRow_" + str(res.id)
	row.add_theme_constant_override("separation", 8)

	# The found marker: a filled dot once the player has found it.
	var dot := ColorRect.new()
	dot.custom_minimum_size = Vector2(10.0, 10.0)
	dot.color = Color(0.75, 0.54, 0.24, 0.0)
	row.add_child(dot)

	# The name.
	var name := Label.new()
	name.text = Loc.t(res.name_key)
	name.custom_minimum_size = Vector2(150.0, 0.0)
	name.add_theme_font_size_override("font_size", 15)
	name.add_theme_color_override("font_color", Color(0.94, 0.9, 0.8, 1.0))
	row.add_child(name)

	# The passage for the current truth: GDD.md §11.4 wants two reads of
	# every region, not one. T swaps which one is shown.
	var fantasy := Label.new()
	fantasy.name = "Fantasy"
	fantasy.add_theme_font_size_override("font_size", 12)
	fantasy.add_theme_color_override("font_color", Color(0.75, 0.54, 0.24, 1.0))
	row.add_child(fantasy)

	# The fragment, if any.
	if not res.fragment_id.is_empty():
		var frag := Label.new()
		frag.text = "[fragment: " + str(res.fragment_id) + "]"
		frag.add_theme_font_size_override("font_size", 11)
		frag.add_theme_color_override("font_color", Color(0.94, 0.9, 0.8, 0.6))
		row.add_child(frag)

	row.add_child(Control.new())  # spacer

	_refresh_row(row, res)
	return row


## Build one of the two side-by-side maps. The grade is entirely in the
## shader material; both maps share the same SVG texture.
func _build_variant_map(host: HBoxContainer, variant: String, title: String,
		tint: Color, saturation: float, brightness: float) -> void:
	var column := VBoxContainer.new()
	column.name = title + "Map"
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host.add_child(column)

	var label := Label.new()
	label.text = title
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", tint)
	column.add_child(label)

	var holder := Control.new()
	holder.name = title + "Host"
	holder.custom_minimum_size = MAP_SIZE * MAP_SCALE
	column.add_child(holder)
	map_containers[variant] = holder

	var rect := TextureRect.new()
	rect.name = title + "Rect"
	if map_texture != null:
		rect.texture = map_texture
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.custom_minimum_size = MAP_SIZE * MAP_SCALE
	rect.expand = true
	var shader := load("res://assets/shaders/map_variant.gdshader") as Shader
	if shader != null:
		var mat := ShaderMaterial.new()
		mat.shader = shader
		mat.set_shader_parameter("tint", tint)
		mat.set_shader_parameter("saturation", saturation)
		mat.set_shader_parameter("brightness", brightness)
		rect.material = mat
	holder.add_child(rect)


## Build the fragment markers on both maps. A dot appears when that region's
## page is in the codex; the collectible is filling in both readings.
func _build_fragment_markers(_container: Control, _map_rect: TextureRect) -> void:
	# Region centres in the 600x400 space, scaled to each small map.
	var positions: Dictionary = {
		"camino_la_mancha": Vector2(310.0, 180.0),
		"sierra_morena": Vector2(305.0, 216.0),
		"el_toboso": Vector2(250.0, 199.0),
		"los_riscos": Vector2(422.0, 126.0),
		"el_castillo_del_duque": Vector2(436.0, 161.0),
	}

	for res in regions:
		if res.fragment_id.is_empty():
			continue
		for variant in map_containers.keys():
			var host: Control = map_containers[variant]
			var dot := ColorRect.new()
			dot.name = "Marker_%s_%s" % [variant, str(res.fragment_id)]
			dot.custom_minimum_size = Vector2(8.0, 8.0)
			dot.color = Color(0.75, 0.54, 0.24, 0.0)
			dot.set_position(positions.get(res.id, Vector2(300.0, 200.0)) * MAP_SCALE)
			host.add_child(dot)
			fragment_markers[_marker_key(variant, res.fragment_id)] = dot
			_show_fragment_marker_for(variant, res.fragment_id,
				GameState.codex_pages.has(res.fragment_id))


func _marker_key(variant: String, fragment_id: StringName) -> String:
	return variant + "|" + str(fragment_id)


## Refresh one row's found state.
func _refresh_row(row: Control, res: RegionData) -> void:
	var dot := row.get_child(0) as ColorRect
	var found := GameState.region_found(res.id)
	dot.color = Color(0.75, 0.54, 0.24, 1.0) if found else Color(0.75, 0.54, 0.24, 0.0)
	var label := row.get_child(1) as Label
	label.modulate = Color(1.0, 1.0, 1.0, 1.0) if found else Color(0.4, 0.4, 0.35, 0.5)


## Called when the world's truth turns over: the map overlay tints
## differently in Book and Reality — gilded vs chalky.
func _on_truth_changed(_old: int, _new: int) -> void:
	_update_truth_overlay()
	_update_fantasy_labels()


## Show the Book or Reality passage for each region, depending on the truth.
func _update_fantasy_labels() -> void:
	for id in region_rows.keys():
		var row := region_rows[id] as Control
		var label := row.get_node_or_null("Fantasy") as Label
		if label == null:
			continue
		var res: RegionData = null
		for candidate in regions:
			if candidate.id == id:
				res = candidate
				break
		if res == null:
			continue
		var key := res.book_fantasy_key if TruthLayer.is_book() else res.reality_fantasy_key
		if key.is_empty():
			label.text = res.fantasy
		else:
			label.text = Loc.t(key)


## Update the full-screen tint based on the current truth layer.
func _update_truth_overlay() -> void:
	if truth_overlay == null:
		return
	if TruthLayer.is_book():
		# Book truth: gilded, warm ochre.
		truth_overlay.color = Color(0.75, 0.54, 0.24, 0.22)
	else:
		# Reality truth: desaturated chalk, cool grey.
		truth_overlay.color = Color(0.30, 0.29, 0.27, 0.18)


## Called when the player finds a region.
func _on_region_found(id: StringName) -> void:
	var row: Control = region_rows.get(id, null) as Control
	if row != null:
		# A plain loop, not find() with a Callable: TypedArray::find with a
		# lambda is unreliable in this Godot build (see also the sort note).
		for res in regions:
			if res.id == id:
				_refresh_row(row, res)
				break


## Called when a Manifiesto fragment is found — light its dot on both maps.
func _on_codex_page_found(id: StringName) -> void:
	for variant in map_containers.keys():
		_show_fragment_marker_for(variant, id, true)


func _show_fragment_marker_for(variant: String, fragment_id: StringName, found: bool) -> void:
	var marker: ColorRect = fragment_markers.get(_marker_key(variant, fragment_id), null) as ColorRect
	if marker != null:
		marker.color = Color(0.75, 0.54, 0.24, 1.0) if found else Color(0.75, 0.54, 0.24, 0.0)


## Close the map.
func _close() -> void:
	var host := get_parent()
	if host != null and host.has_method("clear_map_screen"):
		host.call("clear_map_screen")
	queue_free()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"toggle_map") or event.is_action_pressed(&"ui_cancel"):
		_close()
