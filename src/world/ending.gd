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
	return """You close the book.

The ink is still wet on the page. Your handwriting — though you do not
remember holding a pen. The adventures of Don Quixote and Sancho Panza,
the windmills and the giants, the inn and the enchanted Dulcinea, the
Cave of Montesinos and the Duke's castle: all of it written down, in
a hand that looks like yours but that you do not recognize.

You have read 1605. You have lived it. And now you understand:
there was never a world outside the book. There was only the reader,
and the reader's desire to see the truth.

Quixote's locura: {q}/100
Sancho's locura: {s}/100
Books collected: {books}/15

The game is the book. You are the reader. The story continues,
because a reader who finishes a book simply starts it again.
"""

## La Locura Compartida — Shared Madness.
## Both characters high Locura. The world is the book; they are both
## knights. The "happy" ending that is also the worse one.
func _prose_la_locura_compartida() -> String:
	var q := int(Locura.get_for(&"quixote"))
	var s := int(Locura.get_for(&"sancho"))
	return """You ride together, Quixote and Sancho, across a plain where
windmills stretch toward the horizon like giants at attention. The sun
is setting in Book gold, and there is no Reality left to contradict it.

Quixote adjusts his helmet, grinning. "Did you see that one, Sancho?
That one is a dragon!"

Sancho laughs, adjusting his own nonexistent armor. "A dragon, master!
We shall slay it!"

They ride off together, two knights errant chasing giants across a
plain that will never end. There is no Sancho to bring Quixote home,
no Quixote to ground Sancho in sense. The two of them have become
exactly what they set out to be: knights of the Book, forever.

Quixote's locura: {q}/100
Sancho's locura: {s}/100

The world is the book. The book is the world. And neither of them
will ever leave it.
"""

## El Mundo Real — The Real World.
## Both cured, the book shelved. The saddest ending.
func _prose_el_mundo_real() -> String:
	var q := int(Locura.get_for(&"quixote"))
	var s := int(Locura.get_for(&"sancho"))
	return """The book is closed. Shelved. Forgotten.

Quixote sits in his study in the village, aging quietly, reading
treatises on agriculture and husbandry. He no longer sees giants in
windmills. He no longer sees princesses in peasant girls. He is,
once more, simply Alonso Quixano the Good.

Sancho has returned to his wife Teresa and his children. He tells them
stories sometimes — of a knight, of a squire, of adventures that
never happened — but the children laugh and run off to play, and the
stories remain just stories.

The world is real again. It is smaller than they remembered. It is
quieter. It is, in the end, simply the world.

Quixote's locura: {q}/100
Sancho's locura: {s}/100

The book is shelved. The adventure is over. The real world remains,
and it is smaller than either of them remembered.
"""

## El Libro Gana — The Book Wins.
## Middle ground: the book prevails, partly.
func _prose_el_libro_gana() -> String:
	var q := int(Locura.get_for(&"quixote"))
	var s := int(Locura.get_for(&"sancho"))
	var books := Biblioteca.collected.size()
	return """The book wins. Not completely, but it wins.

Quixote is cured — mostly. He still reads, still enjoys a good tale,
but he no longer mistakes windmills for giants. He lives quietly,
occasionally glancing at the old books on his shelf with a mixture of
fondness and embarrassment.

Sancho is not cured — not entirely. He still looks at the horizon and
wonders what might be out there, beyond the village, beyond the road.
He does not believe in giants, but he wonders.

The book is shelved, but not forgotten. Sometimes, on quiet evenings,
Quixote opens it again. Just to read a page. Just to remember.

Quixote's locura: {q}/100
Sancho's locura: {s}/100
Books collected: {books}/15

The book wins. Not entirely. But it wins enough.
"""

## ── Input handling ──────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel") or event.is_action_pressed("lectura"):
		_get_tree().change_scene_to_packed(load("res://src/world/slice.tscn"))