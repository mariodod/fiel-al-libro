class_name VentureData
extends Resource
## A Venture — the novel's famous set-piece, turned into a boss.
##
## Every Venture has a Book form and a Reality form (different moves, drops
## the real loot) and usually a case attached: investigating the Venture's
## origin may unlock a third, hidden resolution.
##
## GDD.md §7.4.

enum Resolution {
	FORCED,    ## you killed it
	TRUTH,     ## you solved the case and the world obliged
	STAGED,    ## the player staged it (Ensayo only, D5)
	ABANDONED, ## you walked away
}

@export var id: StringName = &""
@export var display_name_key: StringName = &""
@export var source_reference: String = ""
## e.g. "I.7-8" — the chapter in the novel.
@export var novel_chapter: String = ""

@export_group("Combat")
@export var enemy: EnemyData
@export var arena_scene: String = ""
@export var is_non_combat: bool = false

@export_group("Resolutions")
@export var allows_truth_resolution: bool = true
@export var allows_staged_resolution: bool = false
@export var case_id: StringName = &""

@export_group("Fiction")
@export var manifesto_fragments: Array[StringName] = []
@export var rewards: Array[Resource] = []
