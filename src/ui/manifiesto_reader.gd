extends Control
## The Manifiesto reader: shows collected fragments in full.
##
## Opens from the Biblioteca shelf or with a dedicated key. Each fragment
## shows its modern rendering (localised), the 1605 original, and its
## Reality/Book variants — the two truths of the same passage.
##
## See GDD.md §6 and §9.

var _container: CanvasItem = null
var _list: ItemList = null
var _detail: Control = null
var _title: Label = null
var _modern: Label = null
var _original: Label = null
var _reality: Label = null
var _book: Label = null
var _chapter_label: Label = null
var _source_label: Label = null

var _selected: StringName = &""


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	visible = false
	# Child nodes are found lazily on first use (see _find_child_by_name)
	# because nested scene instantiation can delay their availability.
	EventBus.shelf_changed.connect(_refresh_list)
	EventBus.toggle_manifiesto.connect(_toggle)


## Recursively find a descendant node by name.
func _find_child_by_name(name: String, from: Node = null) -> Node:
	var search_from: Node = from if from != null else self
	for i in range(search_from.get_child_count()):
		var child = search_from.get_child(i)
		if child.name == name:
			return child
		var found = _find_child_by_name(name, child)
		if found != null:
			return found
	return null


## Ensure the list node is found (lazily).
func _ensure_list() -> void:
	if _list != null:
		return
	_list = _find_child_by_name("List") as ItemList
	if _list != null:
		_list.item_selected.connect(_on_item_selected)


## Ensure the container is found (lazily).
func _ensure_container() -> void:
	if _container != null:
		return
	_container = _find_child_by_name("Container") as CanvasItem


## Ensure the detail panel labels are found (lazily).
##
## Chapter and Source labels are created dynamically if they are not
## present in the scene, so the reader works with any chapter scene
## without needing scene edits.
func _ensure_detail() -> void:
	if _detail != null:
		return
	_detail = _find_child_by_name("Detail") as Control
	if _detail == null:
		return
	_title = _find_child_by_name("Title", _detail) as Label
	_modern = _find_child_by_name("Modern", _detail) as Label
	_original = _find_child_by_name("Original", _detail) as Label
	_reality = _find_child_by_name("Reality", _detail) as Label
	_book = _find_child_by_name("Book", _detail) as Label

	# Chapter label: created dynamically if missing from the scene.
	if _chapter_label == null:
		var chapter_label := Label.new()
		chapter_label.set_name("Chapter")
		chapter_label.anchors_preset = Control.PRESET_TOP_LEFT
		chapter_label.position = Vector2(200, 70)
		chapter_label.add_theme_font_size_override("font_size", 14)
		chapter_label.add_theme_color_override("font_color", Color(0.82, 0.80, 0.72, 1.0))
		chapter_label.autowrap_mode = 2
		_detail.add_child(chapter_label)
		_chapter_label = chapter_label

	# Source label: created dynamically if missing from the scene.
	if _source_label == null:
		var source_label := Label.new()
		source_label.set_name("Source")
		source_label.anchors_preset = Control.PRESET_TOP_LEFT
		source_label.position = Vector2(200, 95)
		source_label.add_theme_font_size_override("font_size", 12)
		source_label.add_theme_color_override("font_color", Color(0.75, 0.54, 0.24, 1.0))
		source_label.autowrap_mode = 2
		_detail.add_child(source_label)
		_source_label = source_label


## Open / close the reader.
func _toggle() -> void:
	visible = not visible
	_ensure_container()
	if _container != null:
		_container.visible = visible
	if visible:
		_refresh_list()
		if _list != null and _list.get_item_count() > 0 and _list.get_selected_items().size() == 0:
			_list.select(0)
			_on_item_selected(0)


## Rebuild the fragment list from Biblioteca's collected books.
func _refresh_list() -> void:
	_ensure_list()
	if _list == null:
		return
	_list.clear()
	var collected := Biblioteca.collected
	if collected.is_empty():
		var item := _list.add_item(Loc.t(&"ui.manifiesto.empty"))
		_list.set_item_disabled(0, true)
		return
	for i in range(collected.size()):
		var id: StringName = collected[i]
		var title_key := ManifiestoFragment.title_key_for(id)
		var title := Loc.t(title_key) if not title_key.is_empty() else str(id)
		_list.add_item(title)
		_list.set_item_metadata(i, id)


## Show the selected fragment's full content.
func _on_item_selected(index: int) -> void:
	if index < 0:
		return
	_ensure_list()
	if _list == null:
		return
	var id: StringName = _list.get_item_metadata(index)
	_selected = id
	var data := ManifiestoFragment.load_data(id)
	if data.is_empty():
		return

	# Title.
	var title_key := str(data.get("title_key", ""))
	_ensure_detail()
	if _title != null:
		_title.text = Loc.t(title_key) if not title_key.is_empty() else str(id)

	# Chapter and part.
	var chapter := int(data.get("chapter", 0))
	var part := int(data.get("part", 0))
	if _chapter_label != null and chapter > 0:
		_chapter_label.text = "%s %d — Part %d" % [Loc.t(&"bk.chapter"), chapter, part]
	elif _chapter_label != null:
		_chapter_label.text = ""

	# Source / provenance.
	var source: Variant = data.get("source", {})
	if _source_label != null and source is Dictionary:
		var work := str(source.get("work", ""))
		var edition := str(source.get("edition", ""))
		var provenance := work
		if not edition.is_empty():
			provenance += " — " + edition
		_source_label.text = "%s %s" % [Loc.t(&"ui.codex.source"), provenance]
	elif _source_label != null:
		_source_label.text = ""

	# Modern rendering (localised), falling back to the 1605 original.
	var language := TranslationServer.get_locale()
	var rendered := ManifiestoFragment.text_for(id, language)
	if _modern != null:
		_modern.text = rendered

	# 1605 original.
	var original := str(data.get("original_1605", ""))
	if _original != null:
		_original.text = original

	# Variants.
	var variants: Dictionary = data.get("variants", {})
	if _reality != null:
		_reality.text = str(variants.get("reality", ""))
	if _book != null:
		_book.text = str(variants.get("book", ""))

	# Show the detail panel.
	if _detail != null:
		_detail.visible = true


## Toggle key binding is handled by the Manuscript UI shell via slice.gd.
## The reader responds to EventBus.toggle_manifiesto instead.
