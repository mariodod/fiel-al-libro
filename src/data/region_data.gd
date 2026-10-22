class_name RegionData
extends Resource
## One region of the world map.
##
## The map is a hand-drawn portolan of Spain: five regions at their true
## compass positions, one dashed road from La Posada, and the places the
## game already has. The regions and their order are the world's spine
## (GDD.md §11.2): every chapter belongs to one region, and every region
## has exactly one Venture.

@export var id: StringName = &""
@export var name_key: StringName = &""
@export var chapter: int = 0
@export var fantasy: String = ""
@export var key_venture_id: StringName = &""
@export var fragment_id: StringName = &""

