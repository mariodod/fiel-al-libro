class_name Prologue
extends CanvasLayer
## The manuscript prologue — the opening page before Chapter 1.
##
## Displays the prologue content from res://src/data/prologue.tres in three
## readings: the framing text, the Reality variant, and the Book variant.
## The player presses a key to cycle through them, then to enter Chapter 1.
##
## See GDD.md §6 and the prologue locale keys (prologue.opening.*).

@onready var _text_label: Label = $Panel/Text
@onready var _variant_reality: Label = $Panel/VariantReality
@onready var _variant_book: Label = $Panel/VariantBook
@onready var _hint: Label = $Panel/Hint

var _data: Variant = {}
var _page: int = 0  # 0 = framing text, 1 = reality variant, 2 = book variant, 3 = done

func _ready() -> void:
	visible = false
	_data = preload("res://src/data/prologue.tres")
	_show_page(0)

func _show_page(page: int) -> void:
	_page = page
	match page:
		0:
			var tk: String = ""
			var raw: Variant := _data.get("text_key")
			if raw != null:
				tk = str(raw)
			_text_label.text = tk
			if _text_label.text != "":
				_text_label.text = Loc.t(_text_label.text)
			_variant_reality.visible = false
			_variant_book.visible = false
			_hint.text = "Press any key to turn the page."
		1:
			_text_label.text = ""
			var vr: String = ""
			var raw_vr: Variant := _data.get("variant_reality")
			if raw_vr != null:
				vr = str(raw_vr)
			_variant_reality.text = vr
			if _variant_reality.text != "":
				_variant_reality.text = Loc.t(_variant_reality.text)
			_variant_reality.visible = true
			_variant_book.visible = false
			_hint.text = "Press any key to turn the page."
		2:
			_text_label.text = ""
			_variant_reality.visible = false
			var vb: String = ""
			var raw_vb: Variant := _data.get("variant_book")
			if raw_vb != null:
				vb = str(raw_vb)
			_variant_book.text = vb
			if _variant_book.text != "":
				_variant_book.text = Loc.t(_variant_book.text)
			_variant_book.visible = true
			_hint.text = "Press any key to enter Chapter 1."
		3:
			queue_free()

func show_prologue() -> void:
	visible = true
	_show_page(0)

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel") or event.is_action_pressed("lectura"):
		_show_page(_page + 1)