extends CanvasLayer
## The ending scene — shows the ending text based on GameState.compute_ending().
##
## The ending is the "manuscript" itself — prose assembled from the player's
## actual choices throughout the game. See GDD.md §12.2.

@onready var _title_label: Label = $Panel/Title
@onready var _subtitle_label: Label = $Panel/Subtitle
@onready var _text_label: Label = $Panel/Text
@onready var _hint_label: Label = $Panel/Hint

## The ending id, set from GameState when the scene is instantiated.
var ending_id: StringName = &""

func _ready() -> void:
	visible = true
	_show_ending()
	AudioDirector.play_credits_song()

func _show_ending() -> void:
	var id := ending_id
	if id == &"":
		id = GameState.compute_ending()
		ending_id = id

	# Title
	var name_key := ""
	var desc_key := ""
	match id:
		&"el_manuscrito":
			name_key = &"ui.ending.el_manuscrito.name"
			desc_key = &"ui.ending.el_manuscrito.desc"
		&"la_locura_compartida":
			name_key = &"ui.ending.la_locura_compartida.name"
			desc_key = &"ui.ending.la_locura_compartida.desc"
		&"el_mundo_real":
			name_key = &"ui.ending.el_mundo_real.name"
			desc_key = &"ui.ending.el_mundo_real.desc"
		&"el_libro_gana":
			name_key = &"ui.ending.el_libro_gana.name"
			desc_key = &"ui.ending.el_libro_gana.desc"
		_:
			name_key = &"ui.ending.el_libro_gana.name"
			desc_key = &"ui.ending.el_libro_gana.desc"

	_title_label.text = Loc.t(name_key) if not name_key.is_empty() else str(id)
	_subtitle_label.text = Loc.t(desc_key) if not desc_key.is_empty() else ""

	# Prose
	_text_label.text = _prose_for(id)

func _prose_for(id: StringName) -> String:
	match id:
		&"el_manuscrito":
			return _prose_el_manuscrito()
		&"la_locura_compartida":
			return _prose_la_locura_compartida()
		&"el_mundo_real":
			return _prose_el_mundo_real()
		&"el_libro_gana":
			return _prose_el_libro_gana()
		_:
			return _prose_el_libro_gana()

## ── Prose texts ──────────────────────────────────────────────────────────

## El Manuscrito — the hidden ending.
## The player discovers they are the reader, and this playthrough
## is the second book being written.
func _prose_el_manuscrito() -> String:
	var books := Biblioteca.collected.size()
	var q := int(Locura.get_for(&"quixote"))
	var s := int(Locura.get_for(&"sancho"))
	return Loc.t(&"ui.ending.el_manuscrito.prose").format({"q": q, "s": s, "books": books})

## La Locura Compartida — Shared Madness.
## Both characters high Locura. The world is the book; they are both
## knights. The "happy" ending that is also the worse one.
func _prose_la_locura_compartida() -> String:
	var books := Biblioteca.collected.size()
	var q := int(Locura.get_for(&"quixote"))
	var s := int(Locura.get_for(&"sancho"))
	return Loc.t(&"ui.ending.la_locura_compartida.prose").format({"q": q, "s": s, "books": books})

## El Mundo Real — The Real World.
## Both cured, the book shelved. The saddest ending.
func _prose_el_mundo_real() -> String:
	var books := Biblioteca.collected.size()
	var q := int(Locura.get_for(&"quixote"))
	var s := int(Locura.get_for(&"sancho"))
	return Loc.t(&"ui.ending.el_mundo_real.prose").format({"q": q, "s": s, "books": books})

## El Libro Gana — The Book Wins.
## Middle ground: the book prevails, partly.
func _prose_el_libro_gana() -> String:
	var q := int(Locura.get_for(&"quixote"))
	var s := int(Locura.get_for(&"sancho"))
	var books := Biblioteca.collected.size()
	return Loc.t(&"ui.ending.el_libro_gana.prose").format({"q": q, "s": s, "books": books})

## ── Input handling ──────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel") or event.is_action_pressed("lectura"):
		AudioDirector.stop_music()
		get_tree().change_scene_to_packed(load("res://src/world/slice.tscn"))