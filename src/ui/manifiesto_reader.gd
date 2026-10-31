extends Control
## The Manifiesto reader: shows collected fragments in full.
##
## Opens from the Biblioteca shelf or with a dedicated key. Each fragment
## shows its modern rendering (localised), the 1605 original, and its
## Reality/Book variants — the two truths of the same passage.
##
## See GDD.md §6 and §9.

@onready var _container: VBoxContainer = $Container
@onready var _list: ItemList = $Container/HSplit/List
@onready var _detail: Control = $Container/HSplit/Detail
@onready var _title: Label = $Container/HSplit/Detail/Title
@onready var _modern: Label = $Container/HSplit/Detail/Modern
@onready var _original: Label = $Container/HSplit/Detail/Original
@onready var _reality: Label = $Container/HSplit/Detail/Reality
@onready var _book: Label = $Container/HSplit/Detail/Book

var _selected: StringName = &""

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	visible = false
	_container.visible = false
	_list.item_selected.connect(_on_item_selected)

	# Build the list from Biblioteca's collected books.
	_refresh_list()
	Biblioteca.shelf_changed.connect(_refresh_list)

	EventBus.toggle_manifiesto.connect(_toggle)


## Open / close the reader.
func _toggle() -> void:
	visible = not visible
	_container.visible = visible
	if visible:
		_refresh_list()
		if _list.get_item_count() > 0 and _list.get_selected_items().size() == 0:
			_list.select(0)
			_on_item_selected(0)


## Rebuild the fragment list from Biblioteca's collected books.
func _refresh_list() -> void:
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
	var id: StringName = _list.get_item_metadata(index)
	_selected = id
	var data := ManifiestoFragment.load_data(id)
	if data.is_empty():
		return

	# Title.
	var title_key := str(data.get("title_key", ""))
	_title.text = Loc.t(title_key) if not title_key.is_empty() else str(id)

	# Modern rendering (localised).
	var modern: Dictionary = data.get("modern", {})
	var language := TranslationServer.get_locale()
	var rendered := str(modern.get(language, ""))
	if rendered.is_empty():
		rendered = str(modern.get("es", ""))  # fallback to Spanish original
	_modern.text = rendered

	# 1605 original.
	var original := str(data.get("original_1605", ""))
	_original.text = original

	# Variants.
	var variants: Dictionary = data.get("variants", {})
	_reality.text = str(variants.get("reality", ""))
	_book.text = str(variants.get("book", ""))

	# Show the detail panel.
	_detail.visible = true


## Toggle key binding.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"manifiesto"):
		_toggle()
