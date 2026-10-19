class_name BookData
extends Resource
## A collectible book. Real Spanish myths and literature, all public domain
## or pre-1900. See GDD.md §9 and the IP rules in §19.
##
## Books are not trophies. They are the game's build system: five of them
## are equipped at a time and each grants a passive.

@export var id: StringName = &""
@export var display_name_key: StringName = &""
@export var description_key: StringName = &""
@export var cover_texture: Texture2D

@export_group("Author")
## The real historical author or tradition, e.g. "Cervantes" or "Anonymous (13th c.)".
@export var author: String = ""
@export var year: String = ""

@export_group("Passive")
## The passive ability id granted while equipped.
@export var passive_id: StringName = &""
@export var passive_name_key: StringName = &""
@export var passive_description_key: StringName = &""

@export_group("Codex")
## The Manifiesto fragment this book unlocks, if any.
@export var manifesto_fragment: StringName = &""
@export var codex_note_key: StringName = &""


## True if this book is safe to ship. The IP checklist in GDD.md §19 says
## only pre-1900 / public-domain works belong here.
func is_verified_public_domain() -> bool:
	return not year.is_empty() and year.to_int() < 1900
