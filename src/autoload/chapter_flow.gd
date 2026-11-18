extends Node
## Campaign orchestration: makes every chapter reachable end to end.
##
## The chapter scenes and RegionGraph already exist, but nothing drove from
## one to the next — the main scene was the grey-box slice. This autoload:
##   - New Game: clears progress, plays the prologue, enters Chapter 1.
##   - Continue: restores the save and re-enters the current chapter.
##   - On EventBus.chapter_completed: a short "ride" transition, then the next
##     chapter in the unlock chain. The Ensayo completes two chapters at once,
##     so already-completed targets are skipped.
##   - When all chapters are complete, slice.gd switches to the ending scene;
##     this node only emits flow_finished.
##
## It is an autoload so it survives scene changes. The grey-box slice.tscn
## remains the development main scene; the title page's Begin button starts
## this flow explicitly.

signal flow_started
signal chapter_loaded(id: StringName)
signal flow_finished

const PROLOGUE_SCENE := "res://src/world/prologue.tscn"
const RIDE_SECONDS := 2.0

var active: bool = false
var transitioning: bool = false
var current_chapter: StringName = &""


func _ready() -> void:
	EventBus.chapter_completed.connect(_on_chapter_completed)


## Reset all progress to a fresh campaign without starting any scenes.
## Separated out so it can be verified in the headless suite.
func reset_campaign() -> void:
	Manuscrito.delete_save(0)
	GameState.reset_progress()
	RegionGraph.reset_progress()
	active = true


## Start a brand-new campaign: clear progress, then play the prologue.
func start_new_game() -> void:
	reset_campaign()
	flow_started.emit()
	_play_prologue()


## Restore the last save and re-enter the chapter that was being played.
func continue_game() -> void:
	if not Manuscrito.load_game(0):
		start_new_game()
		return
	active = true
	flow_started.emit()
	var id := GameState.current_chapter
	if id.is_empty():
		id = RegionGraph.start_chapter
	goto_chapter(id)


## Show the prologue over this node, await its last page, then enter Chapter 1.
func _play_prologue() -> void:
	var packed := load(PROLOGUE_SCENE) as PackedScene
	if packed == null:
		goto_chapter(RegionGraph.start_chapter)
		return
	var prologue := packed.instantiate()
	add_child(prologue)
	if prologue.has_method("show_prologue"):
		prologue.show_prologue()
	if prologue.has_signal("prologue_finished"):
		await prologue.prologue_finished
	prologue.queue_free()
	goto_chapter(RegionGraph.start_chapter)


## Load a chapter scene through RegionGraph (which validates that it is
## unlocked and marks its region entered). Returns false if it cannot load.
func goto_chapter(id: StringName) -> bool:
	var packed := RegionGraph.load_chapter(id)
	if packed == null:
		push_warning("[ChapterFlow] could not load chapter %s" % id)
		return false
	current_chapter = id
	GameState.set_current_chapter(id)
	get_tree().change_scene_to_packed(packed)
	chapter_loaded.emit(id)
	return true


## Advance after a chapter is completed. slice.gd has already marked it done
## in both GameState and RegionGraph by the time this signal fires.
func _on_chapter_completed(id: StringName) -> void:
	if not active or transitioning:
		return
	if GameState.chapters_completed_count() >= RegionGraph.all_chapters().size():
		# slice.gd performs the scene change to the ending. Do not race it.
		flow_finished.emit()
		return

	var next := next_playable_chapter(id)
	if next.is_empty():
		return
	_ride_then(next)


## The next chapter that still needs playing. The Ensayo completes ch_09 and
## ch_10 in one signal, so a completed unlock target must be skipped.
func next_playable_chapter(completed_id: StringName) -> StringName:
	var next := RegionGraph.next_chapter(completed_id)
	while not next.is_empty() and RegionGraph.is_chapter_completed(next):
		next = RegionGraph.next_chapter(next)
	return next


## A 2-second title card with the credits melody, then the next chapter.
func _ride_then(next: StringName) -> void:
	transitioning = true
	var card := _make_ride_card(next)
	add_child(card)
	await get_tree().create_timer(RIDE_SECONDS).timeout
	card.queue_free()
	goto_chapter(next)
	transitioning = false


func _make_ride_card(next: StringName) -> CanvasLayer:
	var layer := CanvasLayer.new()
	layer.layer = 100

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.09, 0.08, 0.07, 0.97)
	layer.add_child(bg)

	var label := Label.new()
	label.text = Loc.t(&"ui.chapter.ride")
	label.set_anchors_preset(Control.PRESET_CENTER)
	label.add_theme_font_size_override("font_size", 26)
	label.add_theme_color_override("font_color", Color(0.94, 0.9, 0.8, 1.0))
	layer.add_child(label)
	return layer
