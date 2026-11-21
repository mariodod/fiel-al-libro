extends Control
## The player-facing Ensayo (GDD §6.5): stage a test, live through its rounds,
## then read the consequence. Added by chapters 9 and 10; it renders whichever
## phase Ensayo is currently in. The authored round text lives in
## assets/ensayo/ensayo_script.json — it is content, like the 1605 fragments.

signal finished

const GOLD := Color(0.75, 0.54, 0.24, 1.0)
const TEXT := Color(0.97, 0.93, 0.83, 1.0)
const HINT := Color(0.65, 0.60, 0.52, 1.0)

var _script: Dictionary = {}
var _box: VBoxContainer = null
var _selectors: Dictionary = {}
var _chosen_interventions: Dictionary = {}

const TYPES: Array[StringName] = [&"dialogue", &"warning", &"look", &"letter"]


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.05, 0.04, 0.03, 0.95)
	add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 64)
	margin.add_theme_constant_override("margin_right", 64)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 40)
	add_child(margin)
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(scroll)
	_box = VBoxContainer.new()
	_box.name = "EnsayoBox"
	_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_box.add_theme_constant_override("separation", 12)
	scroll.add_child(_box)

	_script = _load_script()
	_render()


## The JSON is parsed at runtime; the strict parser rejects the trailing-comma
## style some gettext-ish tools produce, so read it as text with a light clean.
func _load_script() -> Dictionary:
	var f := FileAccess.open("res://assets/ensayo/ensayo_script.json", FileAccess.READ)
	if f == null:
		return {}
	var text := f.get_as_text()
	f.close()
	# Strip trailing commas before ] or } so community edits remain readable.
	text = text.replace(",]", "]").replace(",}", "}")
	var parsed: Variant = JSON.parse_string(text)
	return parsed if parsed is Dictionary else {}


func _render() -> void:
	for child in _box.get_children():
		child.queue_free()
	_chosen_interventions.clear()
	match Ensayo.state:
		"setup": _render_setup()
		"simulation": _render_round()
		"consequence": _render_consequence()
		_: _render_setup()


func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(480, 0)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	_box.add_child(l)
	return l


func _button(text: String, callable: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(220, 40)
	b.pressed.connect(callable)
	_box.add_child(b)
	return b


## Phase 1 — four setup choices, no timer, no fail state.
func _render_setup() -> void:
	_label(Loc.t(&"ensayo.setup.title"), 28, GOLD)
	_label(Loc.t(&"ensayo.ui.setup_intro"), 15, HINT)
	_selectors.clear()
	var fields: Array = [
		[&"tested", &"ensayo.ui.field.tested", Ensayo.tested_options, "setup.tested."],
		[&"examiner", &"ensayo.ui.field.examiner", Ensayo.examiner_options, "setup.examiner."],
		[&"secret", &"ensayo.ui.field.secret", Ensayo.secret_options, "setup.secret."],
		[&"told", &"ensayo.ui.field.told", Ensayo.told_options, "setup.told."],
	]
	for spec in fields:
		var key: StringName = spec[0]
		_label(Loc.t(spec[1]), 15, TEXT)
		var option := OptionButton.new()
		option.name = "Select_%s" % key
		var source: Array = spec[2]
		# The wife's-name key is "wife", the value is "wife_name".
		for value in source:
			var suffix := str(value)
			if suffix == "wife_name":
				suffix = "wife"
			option.add_item(Loc.t(&"%s%s" % [spec[3], suffix]), source.find(value))
		option.selected = 0
		_box.add_child(option)
		_selectors[key] = option

	var row := HBoxContainer.new()
	_box.add_child(row)
	var begin := Button.new()
	begin.text = Loc.t(&"ensayo.ui.begin")
	begin.pressed.connect(_on_begin)
	row.add_child(begin)
	var refuse := Button.new()
	refuse.text = Loc.t(&"ensayo.ui.refuse")
	refuse.pressed.connect(_on_refuse)
	row.add_child(refuse)


func _current_setup() -> Dictionary:
	var out := {}
	for key in _selectors.keys():
		var option: OptionButton = _selectors[key]
		# Map the displayed index back to the exported option list.
		var options: Array = []
		match key:
			&"tested": options = Ensayo.tested_options
			&"examiner": options = Ensayo.examiner_options
			&"secret": options = Ensayo.secret_options
			&"told": options = Ensayo.told_options
		out[key] = options[clampi(option.selected, 0, options.size() - 1)]
	return out


func _on_begin() -> void:
	var chosen := _current_setup()
	Ensayo.start_setup(chosen.tested, chosen.examiner, chosen.secret, chosen.told)
	_go_to_resolution()


func _on_refuse() -> void:
	var chosen := _current_setup()
	Ensayo.start_setup(chosen.tested, chosen.examiner, chosen.secret, chosen.told)
	Ensayo.start_simulation(chosen.tested, chosen.examiner, chosen.secret, chosen.told)
	Ensayo.refuse()
	_render()


## Phase 2 — one screen per round. The player chooses up to three verbs.
func _render_round() -> void:
	var args := {"n": Ensayo.current_round, "total": Ensayo.max_rounds}
	_label(Loc.t(&"ensayo.ui.round").format(args), 24, GOLD)
	var rounds: Array = (_script.get("simulation", {}) as Dictionary).get("rounds", [])
	var index: int = clampi(Ensayo.current_round - 1, 0, rounds.size() - 1)
	var round_data: Dictionary = rounds[index] if rounds.size() > 0 else {}
	_label(str(round_data.get("context", "")), 16, HINT)

	# The non-player character acts on one of the six real motives.
	var motive: StringName = Ensayo.motive_options[(Ensayo.current_round - 1) % Ensayo.motive_options.size()]
	var motive_name := Loc.t(&"ensayo.ui.motive.%s" % motive)
	_label(Loc.t(&"ensayo.ui.motive").format({"motive": motive_name}), 15, TEXT)

	_label(Loc.t(&"ensayo.ui.choose"), 16, GOLD)
	var verbs: Dictionary = round_data.get("interventions", {})
	for type in TYPES:
		var check := CheckBox.new()
		check.name = "Intervention_%s" % type
		var info: Dictionary = verbs.get(str(type), {})
		check.text = "%s — %s" % [Loc.t(&"ensayo.ui.type.%s" % type), str(info.get("text", ""))]
		check.custom_minimum_size = Vector2(480, 0)
		if _chosen_interventions.has(type):
			check.button_pressed = true
		check.toggled.connect(_on_intervention_toggled.bind(type, info))
		_box.add_child(check)
	_button(Loc.t(&"ensayo.ui.next"), _on_next_round)


func _on_intervention_toggled(pressed: bool, type: StringName, info: Dictionary) -> void:
	if pressed:
		_chosen_interventions[type] = info
	else:
		_chosen_interventions.erase(type)


func _on_next_round() -> void:
	# GDD: 2–3 interventions per round. Silence is legal but recorded as none.
	for type in _chosen_interventions.keys():
		var info: Dictionary = _chosen_interventions[type]
		Ensayo.add_intervention(str(type), str(info.get("text", "")), &"")
	Ensayo.next_round()
	if Ensayo.state == "simulation":
		_render()
	else:
		_render()


## Phase 3 — the consequence, written from what the player actually did.
func _render_consequence() -> void:
	_label(Loc.t(&"ensayo.ui.consequence"), 28, GOLD)
	_label(Loc.t(Ensayo.outcome_name_key(Ensayo.current_outcome)), 22, GOLD)
	_label(Loc.t(Ensayo.outcome_desc_key(Ensayo.current_outcome)), 17, TEXT)
	_label(Loc.t(&"ensayo.ui.reasons"), 16, GOLD)
	for r in Ensayo._outcome_reasons():
		_label("- %s" % r, 14, HINT)
	_button(Loc.t(&"ensayo.ui.continue"), _on_done)


func _on_done() -> void:
	finished.emit()


## The two chapter scenes split one continuous experience. Load the resolution
## scene directly: RegionGraph unlocks it only after this chapter is complete.
func _go_to_resolution() -> void:
	var chapter: Dictionary = RegionGraph.chapters.get(&"ch_10_ensayo_resolution", {})
	var path := str(chapter.get("scene_path", ""))
	if path.is_empty():
		return
	GameState.set_current_chapter(&"ch_10_ensayo_resolution")
	RegionGraph.current_chapter = &"ch_10_ensayo_resolution"
	get_tree().change_scene_to_packed(load(path) as PackedScene)
