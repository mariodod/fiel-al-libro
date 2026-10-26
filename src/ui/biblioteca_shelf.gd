extends Control
## The Biblioteca shelf UI.
##
## Shows all collected books and equipped books with their passives.
## Opens with key I.
##
## Equipped books grant passives; collected-but-unequipped books sit on
## the shelf waiting to be equipped.

var _books: Array[Dictionary] = []
var _equipped: Array[StringName] = []
var _collected: Array[StringName] = []

var _books_container: VBoxContainer = null
var _equipped_container: VBoxContainer = null

func _ready() -> void:
    set_anchors_preset(Control.PRESET_FULL_RECT)
    visible = false
    _build_ui()
    Biblioteca.shelf_changed.connect(_refresh)

func _build_ui() -> void:
    var root = VBoxContainer.new()
    root.anchors_preset = Control.PRESET_FULL_RECT
    root.add_theme_constant_override("separation", 16)
    root.add_theme_constant_override("margin_left", 40)
    root.add_theme_constant_override("margin_right", 40)
    root.add_theme_constant_override("margin_top", 40)
    root.add_theme_constant_override("margin_bottom", 40)
    add_child(root)

    var title = Label.new()
    title.text = "Biblioteca"
    title.add_theme_font_size_override("font_size", 32)
    title.add_theme_color_override("font_color", Color(0.97, 0.93, 0.83, 1.0))
    root.add_child(title)

    var split = HBoxContainer.new()
    split.add_theme_constant_override("separation", 24)
    root.add_child(split)

    var left = VBoxContainer.new()
    left.add_theme_constant_override("separation", 8)
    split.add_child(left)

    var equipped_label = Label.new()
    equipped_label.text = "Equipped"
    equipped_label.add_theme_font_size_override("font_size", 20)
    equipped_label.add_theme_color_override("font_color", Color(0.75, 0.54, 0.24, 1.0))
    left.add_child(equipped_label)

    _equipped_container = VBoxContainer.new()
    _equipped_container.add_theme_constant_override("separation", 6)
    left.add_child(_equipped_container)

    var right = VBoxContainer.new()
    right.add_theme_constant_override("separation", 8)
    split.add_child(right)

    var collected_label = Label.new()
    collected_label.text = "Collected"
    collected_label.add_theme_font_size_override("font_size", 20)
    collected_label.add_theme_color_override("font_color", Color(0.43, 0.45, 0.27, 1.0))
    right.add_child(collected_label)

    _books_container = VBoxContainer.new()
    _books_container.add_theme_constant_override("separation", 6)
    right.add_child(_books_container)

    var hint = Label.new()
    hint.text = "Click a collected book to equip. Equipped books grant passives."
    hint.add_theme_font_size_override("font_size", 14)
    hint.add_theme_color_override("font_color", Color(0.6, 0.55, 0.45, 1.0))
    root.add_child(hint)

    _refresh()

func _refresh() -> void:
    if _books_container == null or _equipped_container == null:
        return
    _books.clear()
    _equipped.clear()
    _collected.clear()

    _equipped.clear_children()
    _books_container.clear_children()

    _collected = Biblioteca.collected()
    _equipped = Biblioteca.equipped_books()

    if _equipped.is_empty():
        var empty = Label.new()
        empty.text = "(none equipped)"
        empty.add_theme_color_override("font_color", Color(0.6, 0.55, 0.45, 1.0))
        _equipped_container.add_child(empty)

    for id: StringName in _equipped:
        var book = Biblioteca.get_book(id)
        if book == null:
            continue
        _books.append({"id": id, "book": book, "equipped": true})
        _add_book_row(id, book, _equipped_container, true)

    for id: StringName in _collected:
        if _equipped.has(id):
            continue
        var book = Biblioteca.get_book(id)
        if book == null:
            continue
        _books.append({"id": id, "book": book, "equipped": false})
        _add_book_row(id, book, _books_container, false)

func _add_book_row(id: StringName, book: Resource, container: VBoxContainer, equipped: bool) -> void:
    var row = HBoxContainer.new()
    row.add_theme_constant_override("separation", 8)
    container.add_child(row)

    var name_label = Label.new()
    name_label.custom_minimum_size = Vector2(200, 0)
    name_label.add_theme_font_size_override("font_size", 16)
    name_label.add_theme_color_override("font_color", Color(0.97, 0.93, 0.83, 1.0))
    name_label.text = Biblioteca.book_name(id)
    row.add_child(name_label)

    var passive_label = Label.new()
    passive_label.add_theme_font_size_override("font_size", 14)
    passive_label.add_theme_color_override("font_color", Color(0.75, 0.54, 0.24, 1.0))
    var passive_name = Biblioteca.passive_name(id)
    if passive_name != "":
        passive_label.text = passive_name
    else:
        passive_label.text = "(no passive)"
    row.add_child(passive_label)

    var equip_btn = Button.new()
    equip_btn.text = equipped ? "Unequip" : "Equip"
    equip_btn.add_theme_font_size_override("font_size", 14)
    equip_btn.pressed.connect(func():
        if equipped:
            Biblioteca.unequip(id)
        else:
            Biblioteca.equip(id)
    )
    row.add_child(equip_btn)

func _close() -> void:
    visible = false
    get_tree().call_group("player_controller", "_unhandled_input", InputEventKey.new())
