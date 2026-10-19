class_name ChapterData
extends Resource
## A chapter. Ten to fifteen minutes: one Posada, one road, one Venture, and
## an optional case with two to four anamorphoses.
##
## GDD.md §11.3.

@export var id: StringName = &""
@export var display_name_key: StringName = &""
@export var region_id: StringName = &""
@export var chapter_number: int = 1

@export_group("Flow")
@export var posada_id: StringName = &""
@export var venture: VentureData
@export var scene_path: String = ""

@export_group("Case")
## The optional investigation attached to this chapter.
@export var case_id: StringName = &""
@export var anamorphosis_ids: Array[StringName] = []
## The Manifiesto fragments this chapter can yield.
@export var manifesto_fragments: Array[StringName] = []

@export_group("Fiction")
## The colophon: the author's voice between chapters. Six of these exist in
## the base game (D7).
@export var colophon_fragment: StringName = &""
