extends Node
## RegionGraph — the chapter/region streaming autoload (Phase 3 Production).
##
## Manages which chapter is current, which chapters are unlocked, and loads
## chapter scenes on demand. The game starts at start_chapter and flows
## chapter → chapter as Ventures are resolved.
##
## Register as an autoload named "RegionGraph" in project.godot.

## Signal emitted when the current chapter changes.
signal chapter_changed(from_id: StringName, to_id: StringName)

## Signal emitted when a new chapter becomes unlocked.
signal chapter_unlocked(chapter_id: StringName)

## Signal emitted when a region is entered for the first time.
signal region_entered(region_id: StringName)

## The graph data.
@onready var graph := preload("res://src/data/region_graph.tres")

## Chapters the player has completed (Venture/case resolved).
var chapters_completed: Array[StringName] = []

## Chapters the player has unlocked (available to enter).
var chapters_unlocked: Array[StringName] = []

## The chapter currently loaded.
var current_chapter: StringName = &""

## The region of the current chapter.
var current_region: StringName = &""

func _ready() -> void:
	# Start with the first chapter unlocked.
	var start := graph.start_chapter
	chapters_unlocked = [start]
	current_chapter = start
	var ch := graph.get_chapter(start)
	current_region = ch.get("region_id", &"")
	EventBus.chapter_started.emit(start)
	EventBus.region_found.emit(current_region)

## ── Unlocking ────────────────────────────────────────────────────────────

## Mark a chapter as completed and unlock whatever it unlocks.
func complete_chapter(chapter_id: StringName) -> void:
	if not chapters_completed.has(chapter_id):
		chapters_completed.append(chapter_id)
		EventBus.chapter_completed.emit(chapter_id)

	var newly_unlocked := graph.unlocked_by(chapter_id)
	for next_id in newly_unlocked:
		if not chapters_unlocked.has(next_id):
			chapters_unlocked.append(next_id)
			EventBus.chapter_unlocked.emit(next_id)

## Is a chapter unlocked and available to play?
func is_chapter_unlocked(chapter_id: StringName) -> bool:
	return chapters_unlocked.has(chapter_id)

## Has a chapter been completed?
func is_chapter_completed(chapter_id: StringName) -> bool:
	return chapters_completed.has(chapter_id)

## ── Loading ──────────────────────────────────────────────────────────────

## Load a chapter scene, replacing the current one.
## Returns the loaded PackedScene (caller instantiates it).
func load_chapter(chapter_id: StringName) -> PackedScene:
	if not is_chapter_unlocked(chapter_id):
		printerr("[RegionGraph] Chapter %s is not unlocked" % chapter_id)
		return null

	var ch := graph.get_chapter(chapter_id)
	var scene_path := ch.get("scene_path", &"")
	if scene_path.is_empty():
		printerr("[RegionGraph] Chapter %s has no scene_path" % chapter_id)
		return null

	var scene := load(scene_path)
	if scene == null:
		printerr("[RegionGraph] Could not load scene %s" % scene_path)
		return null

	var previous := current_chapter
	current_chapter = chapter_id
	current_region = ch.get("region_id", &"")

	# Mark the region as entered if it is the first time.
	if not GameState.region_found(current_region):
		GameState.find_region(current_region)
		EventBus.region_entered.emit(current_region)

	EventBus.chapter_started.emit(chapter_id)
	signal chapter_changed.emit(previous, chapter_id)
	return scene

## ── Queries ──────────────────────────────────────────────────────────────

## The chapter that follows the given one (first unlock target).
func next_chapter(chapter_id: StringName) -> StringName:
	return graph.next_chapter(chapter_id)

## All chapters that unlock after completing the given one.
func unlocked_by(chapter_id: StringName) -> Array[StringName]:
	return graph.unlocked_by(chapter_id)

## All chapters in the graph.
func all_chapters() -> Array[StringName]:
	return graph.all_chapters()

## All regions in the graph.
func all_regions() -> Array[StringName]:
	return graph.all_regions()

## Get chapter data dictionary.
func get_chapter(chapter_id: StringName) -> Dictionary:
	return graph.get_chapter(chapter_id)

## Get region data dictionary.
func get_region(region_id: StringName) -> Dictionary:
	return graph.get_region(region_id)
