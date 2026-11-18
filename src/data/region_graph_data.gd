class_name RegionGraphData
extends Resource
## The chapter/region graph: which chapter is in which region, which scenes
## to load, and which chapters unlock which. The single source of truth for
## chapter streaming in Phase 3 Production.

@export var chapters: Dictionary = {}
@export var regions: Dictionary = {}
@export var start_chapter: StringName = &""

## Get the data dictionary for a chapter.
func get_chapter(chapter_id: StringName) -> Dictionary:
	return chapters.get(chapter_id, {})

## Get the data dictionary for a region.
func get_region(region_id: StringName) -> Dictionary:
	return regions.get(region_id, {})

## List all chapter IDs. Dictionary.keys() is an untyped Array, so it must be
## converted before returning an Array[StringName].
func all_chapters() -> Array[StringName]:
	var result: Array[StringName] = []
	for key in chapters.keys():
		result.append(StringName(str(key)))
	return result

## List all region IDs.
func all_regions() -> Array[StringName]:
	var result: Array[StringName] = []
	for key in regions.keys():
		result.append(StringName(str(key)))
	return result

## The chapter that unlocks directly after completing this one (first in unlocks).
func next_chapter(chapter_id: StringName) -> StringName:
	var ch := get_chapter(chapter_id)
	var unlocks: Variant = ch.get("unlocks", [])
	return unlocks[0] if unlocks.size() > 0 else &""

## All chapters that become available after completing this one.
func unlocked_by(chapter_id: StringName) -> Array[StringName]:
	var result: Array[StringName] = []
	var ch := get_chapter(chapter_id)
	var unlocks: Variant = ch.get("unlocks", [])
	for id in unlocks:
		result.append(StringName(str(id)))
	return result
