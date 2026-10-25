class_name TruthObjectData
extends Resource
## An object that is two things at once.
##
## A windmill is a windmill in Reality and a giant in the Book. A rock is a
## rock in Reality and a book in the Book. Same object, two states — the
## whole game in one data shape.
##
## The enemies of GDD.md §7.4 have the same shape, one level up: a Venture
## has a Book form and a Reality form. The primitive and the boss are the
## same idea at two scales, and they share this resource.
##
## See GDD.md §4.

@export var id: StringName = &""
## The name of the object itself, for the Manuscript and the codex.
@export var display_name_key: StringName = &""

@export_group("Forms")
## What it really is.
@export var reality_form: PackedScene
## What the Book says it is.
@export var book_form: PackedScene
## The Book form hovers a little above the ground. Pure theatre, but it is
## what makes "a book in every rock" read at a glance.
@export var book_form_hovers: bool = false
## How high above the object the perception tag floats.
@export var tag_height: float = 3.0

@export_group("Readings")
## What a character makes of this object in the Reality truth: the name
## they give it, how it looks, and the one detail that does not add up.
@export var reality_face: TruthFace
## The same, in the Book truth. This is where the "book in every rock"
## lives: the Book face of the rock is a book, heavier than a book.
@export var book_face: TruthFace

@export_group("Anamorphosis")
## The id of the anamorphosis hidden in this object, if any.
##
## An anamorphosis is a detail that does not add up — visible only in
## Lectura mode. The rock weighs more than it should; the windmill's
## sails move like arms. Spotting it is the first step of Lectura.
@export var anamorphosis_id: StringName = &""
## The locale key for the tell of this anamorphosis: the detail that
## does not add up, shown when the player spots it in Lectura mode.
@export var anamorphosis_tell_key: StringName = &""
## How much evidence resolving this anamorphosis grants.
@export var anamorphosis_evidence: int = 1


## The face for a truth layer: what it is called, and what it looks like.
func face_for(layer: int) -> TruthFace:
	return book_face if layer == 1 else reality_face


## The name key for a truth layer.
func name_key_for(layer: int) -> StringName:
	var face := face_for(layer)
	return face.name_key if face != null else &""


## The name key of the object itself, which does not change with the truth.
func title_key() -> StringName:
	return display_name_key
