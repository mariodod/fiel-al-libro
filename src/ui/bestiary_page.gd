extends Control
## The Bestiary (GDD §10): the creatures met on the road, with their two
## readings. Entries stay blank until encountered, so it is a record of the
## journey rather than a spoiler list.

signal back_pressed

const GOLD := Color(0.75, 0.54, 0.24, 1.0)
const TEXT := Color(0.97, 0.93, 0.83, 1.0)
const HINT := Color(0.65, 0.60, 0.52, 1.0)

var _list: VBoxContainer = null
var _detail: VBoxContainer = null
var _enemies: Array[EnemyData] = []


func _ready() -> void:
	_load_enemies()
	_build_ui()
	_refresh()
	if not EventBus.enemy_met.is_connected(_refresh):
		EventBus.enemy_met.connect(_refresh)


func _load_enemies() -> void:
	var dir := DirAccess.open("res://src/data/enemies/")
	if dir == null:
		return
	for name in dir.get_files():
		if not name.ends_with(".tres"):
			continue
		var data := load("res://src/data/enemies/" + name)
		if data is EnemyData:
			_enemies.append(data)


func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	# The scene supplies the background ColorRect; do not duplicate it here.
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 48)
	margin.add_theme_constant_override("margin_right", 48)
	margin.add_theme_constant_override("margin_top", 32)
	margin.add_theme_constant_override("margin_bottom", 32)
	add_child(margin)
	var columns := HSplitContainer.new()
	columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(columns)

	var left := ScrollContainer.new()
	left.custom_minimum_size = Vector2(300, 0)
	columns.add_child(left)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 4)
	left.add_child(_list)

	var right := ScrollContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(right)
	_detail = VBoxContainer.new()
	_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail.add_theme_constant_override("separation", 8)
	right.add_child(_detail)

	var back := Button.new()
	back.name = "BestiaryBack"
	back.text = Loc.t(&"ui.settings.back")
	back.custom_minimum_size = Vector2(160, 40)
	back.pressed.connect(func(): back_pressed.emit())
	add_child(back)
	back.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	back.offset_left = -180
	back.offset_top = -56
	back.offset_right = -20
	back.offset_bottom = -16


func _refresh() -> void:
	for child in _list.get_children():
		_list.remove_child(child)
		child.free()
	for child in _detail.get_children():
		_detail.remove_child(child)
		child.free()
	var met_count := 0
	for enemy in _enemies:
		if GameState.has_met_enemy(enemy.id):
			met_count += 1
	var header := Label.new()
	header.text = Loc.tf(&"ui.bestiary.progress", [met_count, _enemies.size()])
	header.add_theme_font_size_override("font_size", 16)
	header.add_theme_color_override("font_color", GOLD)
	_list.add_child(header)

	for enemy in _enemies:
		var known := GameState.has_met_enemy(enemy.id)
		var button := Button.new()
		button.text = enemy.display_name_key if known else Loc.t(&"ui.bestiary.locked")
		if known and not Loc.t(enemy.display_name_key).is_empty():
			button.text = Loc.t(enemy.display_name_key)
		button.add_theme_color_override("font_color", TEXT if known else HINT)
		button.pressed.connect(_on_select.bind(enemy, known))
		_list.add_child(button)
	_make_intro()

	_show_detail(_enemies[0] if _enemies.size() > 0 else null,
		_enemies.size() > 0 and GameState.has_met_enemy(_enemies[0].id))


func _make_intro() -> void:
	var title := Label.new()
	title.text = Loc.t(&"ui.bestiary.title")
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", GOLD)
	_detail.add_child(title)
	var hint := Label.new()
	hint.text = Loc.t(&"ui.bestiary.hint")
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.custom_minimum_size = Vector2(360, 0)
	hint.add_theme_color_override("font_color", HINT)
	_detail.add_child(hint)


func _on_select(enemy: EnemyData, known: bool) -> void:
	_show_detail(enemy, known)


func _show_detail(enemy: EnemyData, known: bool) -> void:
	for child in _detail.get_children():
		_detail.remove_child(child)
		child.free()
	_make_intro()
	if enemy == null:
		return
	if not known:
		var locked := Label.new()
		locked.text = Loc.t(&"ui.bestiary.locked_detail")
		locked.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		locked.add_theme_color_override("font_color", HINT)
		_detail.add_child(locked)
		return
	var name_label := Label.new()
	name_label.text = Loc.t(enemy.display_name_key)
	name_label.add_theme_font_size_override("font_size", 22)
	name_label.add_theme_color_override("font_color", TEXT)
	_detail.add_child(name_label)
	var stats := Label.new()
	stats.text = Loc.tf(&"ui.bestiary.stats", [int(enemy.max_health), int(enemy.poise)])
	stats.add_theme_color_override("font_color", HINT)
	_detail.add_child(stats)
	for form in [enemy.reality_form, enemy.book_form]:
		if form == null:
			continue
		var layer := "book" if form.truth_layer == 1 else "reality"
		var head := Label.new()
		head.text = "%s — %s" % [Loc.t(&"ui.bestiary.%s" % layer), Loc.t(form.display_name_key)]
		head.add_theme_font_size_override("font_size", 17)
		head.add_theme_color_override("font_color", GOLD)
		_detail.add_child(head)
		if not form.codex_note_key.is_empty():
			var note := Label.new()
			note.text = Loc.t(form.codex_note_key)
			note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			note.custom_minimum_size = Vector2(360, 0)
			note.add_theme_color_override("font_color", TEXT)
			_detail.add_child(note)
