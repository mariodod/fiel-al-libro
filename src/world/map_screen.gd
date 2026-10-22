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

func _ready() -> void:
	_load_regions()
	_build_ui()
	EventBus.truth_layer_changed.connect(_on_truth_changed)
	EventBus.region_found.connect(_on_region_found)


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
	var map_panel := VBoxContainer.new()
	map_panel.custom_minimum_size = Vector2(700.0, 0.0)
	container.add_child(map_panel)

	var map_title := Label.new()
	map_title.text = "The world"
	map_title.add_theme_font_size_override("font_size", 20)
	map_title.add_theme_color_override("font_color", Color(0.94, 0.9, 0.8, 1.0))
	map_panel.add_child(map_title)

	var map_rect := TextureRect.new()
	if map_texture != null:
		map_rect.texture = map_texture
	map_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	map_rect.custom_minimum_size = Vector2(600.0, 400.0)
	map_rect.expand = true
	map_panel.add_child(map_rect)

	var map_hint := Label.new()
	map_hint.text = "B / T — turn the world over"
	map_hint.add_theme_font_size_override("font_size", 14)
	map_hint.add_theme_color_override("font_color", Color(0.75, 0.54, 0.24, 1.0))
	map_panel.add_child(map_hint)

	# ── Right: the regions ─────────────────────────────────────────
	var region_panel := VBoxContainer.new()
	region_panel.custom_minimum_size = Vector2(420.0, 0.0)
	container.add_child(region_panel)

	var regions_title := Label.new()
	regions_title.text = "Regions"
	regions_title.add_theme_font_size_override("font_size", 20)
	regions_title.add_theme_color_override("font_color", Color(0.94, 0.9, 0.8, 1.0))
	region_panel.add_child(regions_title)

	for res in regions:
		var row := _make_region_row(res)
		region_panel.add_child(row)
		region_rows[res.id] = row

	# ── Bottom: close hint ─────────────────────────────────────────
	var hint := Label.new()
	hint.text = "G — close the map"
	hint.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	hint.offset_right = -18.0
	hint.offset_bottom = -18.0
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.75, 0.54, 0.24, 1.0))
	add_child(hint)


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

	# The fantasy (what the region is).
	var fantasy := Label.new()
	fantasy.text = res.fantasy
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


## Refresh one row's found state.
func _refresh_row(row: Control, res: RegionData) -> void:
	var dot := row.get_child(0) as ColorRect
	var found := GameState.region_found(res.id)
	dot.color = Color(0.75, 0.54, 0.24, 1.0) if found else Color(0.75, 0.54, 0.24, 0.0)
	var label := row.get_child(1) as Label
	label.modulate = Color(1.0, 1.0, 1.0, 1.0) if found else Color(0.4, 0.4, 0.35, 0.5)


## Called when the world's truth turns over: nothing on the map changes
## (the map is the map), but we keep the connection for the future.
func _on_truth_changed(_old: int, _new: int) -> void:
	pass


## Called when the player finds a region.
func _on_region_found(id: StringName) -> void:
	var row: Control = region_rows.get(id, null) as Control
	if row != null:
		var idx := regions.find(func(r: RegionData) -> bool: return r.id == id)
		if idx >= 0:
			_refresh_row(row, regions[idx])


## Close the map.
func _close() -> void:
	queue_free()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"toggle_map") or event.is_action_pressed(&"ui_cancel"):
		_close()
