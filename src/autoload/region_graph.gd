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

## ── Chapter/region graph data ────────────────────────────────────────────

var chapters: Dictionary = {
	"ch_01_windmills": {
		"region_id": "camino_la_mancha",
		"chapter_number": 1,
		"scene_path": "res://src/world/chapters/ch_01_windmills.tscn",
		"venture_id": "venture_montiel",
		"case_id": "",
		"unlocks": ["ch_02_basque"],
	},
	"ch_02_basque": {
		"region_id": "camino_la_mancha",
		"chapter_number": 2,
		"scene_path": "res://src/world/chapters/ch_02_basque.tscn",
		"venture_id": "venture_basque",
		"case_id": "",
		"unlocks": ["ch_03_canting_sea"],
	},
	"ch_03_canting_sea": {
		"region_id": "camino_la_mancha",
		"chapter_number": 3,
		"scene_path": "res://src/world/chapters/ch_03_canting_sea.tscn",
		"venture_id": "venture_canting_sea",
		"case_id": "",
		"unlocks": ["ch_04_encinados"],
	},
	"ch_04_encinados": {
		"region_id": "sierra_morena",
		"chapter_number": 4,
		"scene_path": "res://src/world/chapters/ch_04_encinados.tscn",
		"venture_id": "venture_encinados",
		"case_id": "",
		"unlocks": ["ch_05_montesinos"],
	},
	"ch_05_montesinos": {
		"region_id": "sierra_morena",
		"chapter_number": 5,
		"scene_path": "res://src/world/chapters/ch_05_montesinos.tscn",
		"venture_id": "venture_montesinos",
		"case_id": "",
		"unlocks": ["ch_06_bridge"],
	},
	"ch_06_bridge": {
		"region_id": "sierra_morena",
		"chapter_number": 6,
		"scene_path": "res://src/world/chapters/ch_06_bridge.tscn",
		"venture_id": "venture_bridge",
		"case_id": "",
		"unlocks": ["ch_07_dulcinea"],
	},
	"ch_07_dulcinea": {
		"region_id": "el_toboso",
		"chapter_number": 7,
		"scene_path": "res://src/world/chapters/ch_07_dulcinea.tscn",
		"venture_id": "venture_dulcinea",
		"case_id": "",
		"unlocks": ["ch_08_celestina"],
	},
	"ch_08_celestina": {
		"region_id": "el_toboso",
		"chapter_number": 8,
		"scene_path": "res://src/world/chapters/ch_08_celestina.tscn",
		"venture_id": "",
		"case_id": "galimatias",
		"unlocks": ["ch_09_ensayo_setup"],
	},
	"ch_09_ensayo_setup": {
		"region_id": "los_riscos",
		"chapter_number": 9,
		"scene_path": "res://src/world/chapters/ch_09_ensayo_setup.tscn",
		"venture_id": "",
		"case_id": "ensayo_setup",
		"unlocks": ["ch_10_ensayo_resolution"],
	},
	"ch_10_ensayo_resolution": {
		"region_id": "los_riscos",
		"chapter_number": 10,
		"scene_path": "res://src/world/chapters/ch_10_ensayo_resolution.tscn",
		"venture_id": "",
		"case_id": "ensayo_resolution",
		"unlocks": ["ch_11_mirrors"],
	},
	"ch_11_mirrors": {
		"region_id": "el_castillo_del_duque",
		"chapter_number": 11,
		"scene_path": "res://src/world/chapters/ch_11_mirrors.tscn",
		"venture_id": "venture_mirrors",
		"case_id": "",
		"unlocks": ["ch_12_magician"],
	},
	"ch_12_magician": {
		"region_id": "el_castillo_del_duque",
		"chapter_number": 12,
		"scene_path": "res://src/world/chapters/ch_12_magician.tscn",
		"venture_id": "venture_magician",
		"case_id": "",
		"unlocks": ["ch_13_duke"],
	},
	"ch_13_duke": {
		"region_id": "el_castillo_del_duque",
		"chapter_number": 13,
		"scene_path": "res://src/world/chapters/ch_13_duke.tscn",
		"venture_id": "venture_duke",
		"case_id": "",
		"unlocks": [],
	},
}

## Region metadata.
var regions: Dictionary = {
	"camino_la_mancha": {
		"name_key": "ui.region.camino_la_mancha.name",
		"fantasy": "Open wheat plains, a few windmills, the first inn",
		"chapter_ids": ["ch_01_windmills", "ch_02_basque", "ch_03_canting_sea"],
	},
	"sierra_morena": {
		"name_key": "ui.region.sierra_morena.name",
		"fantasy": "Dry mountain, bandits, the Cave of Montesinos",
		"chapter_ids": ["ch_04_encinados", "ch_05_montesinos", "ch_06_bridge"],
	},
	"el_toboso": {
		"name_key": "ui.region.el_toboso.name",
		"fantasy": "Slow river country, the enchanted village",
		"chapter_ids": ["ch_07_dulcinea", "ch_08_celestina"],
	},
	"los_riscos": {
		"name_key": "ui.region.los_riscos.name",
		"fantasy": "Sheer cliffs, a Gothic church, fog",
		"chapter_ids": ["ch_09_ensayo_setup", "ch_10_ensayo_resolution"],
	},
	"el_castillo_del_duque": {
		"name_key": "ui.region.el_castillo_del_duque.name",
		"fantasy": "False chivalry, silk, mirrors, theatre",
		"chapter_ids": ["ch_11_mirrors", "ch_12_magician", "ch_13_duke"],
	},
}

## The starting chapter.
var start_chapter: StringName = "ch_01_windmills"

## ── Runtime state ────────────────────────────────────────────────────────

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
	chapters_unlocked = [start_chapter]
	current_chapter = start_chapter
	var ch = chapters.get(start_chapter)
	current_region = ch.get("region_id")
	EventBus.chapter_started.emit(start_chapter)
	EventBus.region_found.emit(current_region)

## ── Unlocking ────────────────────────────────────────────────────────────

## Mark a chapter as completed and unlock whatever it unlocks.
func complete_chapter(chapter_id: StringName) -> void:
	if not chapters_completed.has(chapter_id):
		chapters_completed.append(chapter_id)
		EventBus.chapter_completed.emit(chapter_id)

	var newly_unlocked = chapters.get(chapter_id).get("unlocks")
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

	var ch = chapters.get(chapter_id)
	var scene_path = ch.get("scene_path")
	if scene_path == null:
		printerr("[RegionGraph] Chapter %s has no scene_path" % chapter_id)
		return null

	var scene = load(scene_path)
	if scene == null:
		printerr("[RegionGraph] Could not load scene %s" % scene_path)
		return null

	var previous = current_chapter
	current_chapter = chapter_id
	current_region = ch.get("region_id")

	# Mark the region as entered if it is the first time.
	if not GameState.region_found(current_region):
		GameState.find_region(current_region)
		EventBus.region_entered.emit(current_region)

	EventBus.chapter_started.emit(chapter_id)
	chapter_changed.emit(previous, chapter_id)
	return scene

## ── Queries ──────────────────────────────────────────────────────────────

## The chapter that follows the given one (first unlock target).
func next_chapter(chapter_id: StringName) -> StringName:
	var unlocks = chapters.get(chapter_id).get("unlocks")
	if unlocks != null and unlocks.size() > 0:
		return unlocks[0]
	return &""

## All chapters that unlock after completing the given one.
func unlocked_by(chapter_id: StringName) -> Array[StringName]:
	return chapters.get(chapter_id).get("unlocks")

## All chapters in the graph.
func all_chapters() -> Array[StringName]:
	return chapters.keys()

## All regions in the graph.
func all_regions() -> Array[StringName]:
	return regions.keys()

## Get chapter data dictionary.
func get_chapter(chapter_id: StringName) -> Dictionary:
	return chapters.get(chapter_id, {})

## Get region data dictionary.
func get_region(region_id: StringName) -> Dictionary:
	return regions.get(region_id, {})
