extends Control
## The Lectura HUD: shows the investigation mode state.
##
## Appears when Lectura mode is active (Q key), showing:
## - A "LECTURA" indicator
## - Evidence collected toward a Verdict
## - Anamorphoses spotted vs total available
##
## It sits on its own CanvasLayer so the truth-layer shader does not
## wash out the text.

@export var text_font_size: int = 24

var _label: Label = null
var _evidence_label: Label = null
var _is_visible: bool = false

func _ready() -> void:
	set_visible(false)

	EventBus.lectura_entered.connect(_on_entered)
	EventBus.lectura_exited.connect(_on_exited)
	EventBus.anamorphosis_spotted.connect(_refresh)
	EventBus.anamorphosis_resolved.connect(_refresh)
	EventBus.evidence_collected.connect(_refresh)

	_build_ui()
	_refresh()


func _on_entered() -> void:
	set_visible(true)
	_refresh()


func _on_exited() -> void:
	set_visible(false)


func set_visible(visible: bool) -> void:
	_is_visible = visible
	if _label != null:
		_label.visible = visible
	if _evidence_label != null:
		_evidence_label.visible = visible


func _refresh() -> void:
	if not Lectura.is_active():
		return
	var evidence := Lectura.total_evidence()
	var spotted := Lectura.spotted_count()
	var resolved := Lectura.resolved_count()
	var label_text := "LECTURA\n"
	label_text += "Evidence: %d/%d\n" % [evidence, Lectura.EVIDENCE_FOR_VERDICT]
	label_text += "Anamorphoses: %d spotted, %d resolved" % [spotted, resolved]
	_label.text = label_text
	_evidence_label.text = "Evidence: %d/%d" % [evidence, Lectura.EVIDENCE_FOR_VERDICT]


func _build_ui() -> void:
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	box.offset_left = 20.0
	box.offset_right = 20.0
	box.offset_top = 20.0
	box.add_theme_constant_override("separation", 8)
	add_child(box)

	_label = Label.new()
	_label.name = "LecturaLabel"
	_label.add_theme_font_size_override("font_size", text_font_size)
	_label.add_theme_color_override("font_color", Color(0.97, 0.93, 0.83, 1.0))
	_label.add_theme_color_override("font_outline_color", Color(0.09, 0.07, 0.05, 0.9))
	_label.add_theme_constant_override("outline_size", 3)
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_label)

	_evidence_label = Label.new()
	_evidence_label.name = "EvidenceLabel"
	_evidence_label.add_theme_font_size_override("font_size", 16)
	_evidence_label.add_theme_color_override("font_color", Color(0.90, 0.85, 0.72, 1.0))
	box.add_child(_evidence_label)

	_is_visible = false
	_label.visible = false
	_evidence_label.visible = false

	_refresh()
