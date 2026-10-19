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
## What each character calls it, in each truth.
@export var reality_name_key: StringName = &""
@export var book_name_key: StringName = &""
## The Book form hovers a little above the ground. Pure theatre, but it is
## what makes "a book in every rock" read at a glance.
@export var book_form_hovers: bool = false
## How high above the object the perception tag floats.
@export var tag_height: float = 3.0


## The name key for a truth layer.
func name_key_for(layer: int) -> StringName:
	return book_name_key if layer == 1 else reality_name_key


## The name key of the object itself, which does not change with the truth.
func title_key() -> StringName:
	return display_name_key
