extends CanvasLayer
## The colophon — the author's voice between chapters (GDD.md §12.1).
##
## This is ORIGINAL GAME WRITING, not a 1605 quotation. The Manifiesto
## fragments are verbatim Cervantes; these passages are the game's own author
## voice addressing "you, reader". They agree with the player in Book truth,
## correct them in Reality truth, and are deliberately a little wrong on
## purpose at the end of Region IV.
##
## ChapterFlow instances this during the between-chapter ride and awaits
## colophon_finished before entering the next chapter.

signal colophon_finished

@onready var _title: Label = $Panel/Title
@onready var _text: Label = $Panel/Text
@onready var _hint: Label = $Panel/Hint

var _region: StringName = &""
var _auto_advance: float = 0.0


func _ready() -> void:
	layer = 60


## Show the colophon for a region, in the current truth's voice.
func show_colophon(region_id: StringName, auto_advance_seconds: float = 0.0) -> void:
	_region = region_id
	_auto_advance = auto_advance_seconds
	visible = true

	var region_name := Loc.t(&"ui.region.%s.name" % region_id)
	_title.text = tr(&"ui.colofon.title") % region_name

	var key := &"ui.colofon.%s.%s" % [region_id,
		"book" if TruthLayer.is_book() else "reality"]
	_text.text = Loc.t(key)
	_hint.text = tr(&"ui.colofon.hint")

	if _auto_advance > 0.0:
		var timer := Timer.new()
		timer.one_shot = true
		timer.wait_time = _auto_advance
		add_child(timer)
		timer.timeout.connect(_finish)


func _finish() -> void:
	if not visible:
		return
	visible = false
	colophon_finished.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		_finish()
	elif event is InputEventMouseButton and event.pressed:
		_finish()
