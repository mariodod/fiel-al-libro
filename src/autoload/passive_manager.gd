extends Node
## PassiveManager — applies equipped-book passive modifiers to characters.
##
## The shelf IS your build (GDD.md §8.2). When the player equips or
## unequips a book, Biblioteca emits `shelf_changed`, and PassiveManager
## recomputes the combined modifier stack and applies it to every
## CharacterPawn on the map.
##
## Register as an autoload named "PassiveManager" in project.godot.

## Signal emitted whenever the active passive stack changes.
signal modifiers_changed()

## The modifier stack currently applied to all pawns.
var modifiers: Dictionary = {
	"health_bonus": 0.0,
	"health_percent": 1.0,
	"stamina_bonus": 0.0,
	"stamina_percent": 1.0,
	"poise_bonus": 0.0,
	"speed_percent": 1.0,
	"dodge_distance_percent": 1.0,
	"dodge_iframe_percent": 1.0,
	"damage_percent": 1.0,
	"block_ratio_percent": 1.0,
	"parry_window_bonus": 0.0,
	"locura_per_second": 0.0,
}

## PassiveData resources, loaded lazily from res://src/data/passives/.
var _registry: Dictionary = {}

## Currently active passive IDs (from Biblioteca's equipped shelf).
var active_ids: Array[StringName] = []

func _ready() -> void:
	var dir = DirAccess.open("res://src/data/passives/")
	if dir == null:
		push_warning("[PassiveManager] Could not open res://src/data/passives/")
		return
	for file_name in dir.get_files():
		if file_name.ends_with(".tres"):
			var res: Resource = load("res://src/data/passives/" + file_name)
			if res.get_class() == "PassiveData":
				register(res)
	EventBus.shelf_changed.connect(_on_shelf_changed)
	# Apply the current shelf immediately.
	_on_shelf_changed(Biblioteca.equipped_books())

func register(passive: Resource) -> void:
	if passive == null:
		return
	var id: StringName = passive.get("id")
	if id == null or id == &"":
		push_warning("[PassiveManager] Passive resource has no id; ignoring.")
		return
	_registry[id] = passive

func get_passive(id: StringName) -> Resource:
	return _registry.get(id, null)

## Recompute the combined modifier stack from Biblioteca's equipped books,
## then apply to all pawns.
func _on_shelf_changed(equipped: Array[StringName]) -> void:
	active_ids = equipped.duplicate()
	modifiers = _compute_modifiers(active_ids)
	modifiers_changed.emit()
	_apply_to_pawns()

func _compute_modifiers(ids: Array[StringName]) -> Dictionary:
	var m: Dictionary = {
		"health_bonus": 0.0,
		"health_percent": 1.0,
		"stamina_bonus": 0.0,
		"stamina_percent": 1.0,
		"poise_bonus": 0.0,
		"speed_percent": 1.0,
		"dodge_distance_percent": 1.0,
		"dodge_iframe_percent": 1.0,
		"damage_percent": 1.0,
		"block_ratio_percent": 1.0,
		"parry_window_bonus": 0.0,
		"locura_per_second": 0.0,
	}
	for id: StringName in ids:
		var p := get_passive(id)
		if p == null:
			continue
		m["health_bonus"] += float(p.get("health_bonus", 0.0))
		m["health_percent"] *= float(p.get("health_percent", 1.0))
		m["stamina_bonus"] += float(p.get("stamina_bonus", 0.0))
		m["stamina_percent"] *= float(p.get("stamina_percent", 1.0))
		m["poise_bonus"] += float(p.get("poise_bonus", 0.0))
		m["speed_percent"] *= float(p.get("speed_percent", 1.0))
		m["dodge_distance_percent"] *= float(p.get("dodge_distance_percent", 1.0))
		m["dodge_iframe_percent"] *= float(p.get("dodge_iframe_percent", 1.0))
		m["damage_percent"] *= float(p.get("damage_percent", 1.0))
		m["block_ratio_percent"] *= float(p.get("block_ratio_percent", 1.0))
		m["parry_window_bonus"] += float(p.get("parry_window_bonus", 0.0))
		m["locura_per_second"] += float(p.get("locura_per_second", 0.0))
	return m

## Apply the current modifier stack to every CharacterPawn on the map.
func _apply_to_pawns() -> void:
	for pawn in get_tree().get_nodes_in_group(&"pawns"):
		if pawn is CharacterPawn:
			pawn.apply_passive_modifiers(modifiers)

## Return the combined modifier for a given key, or the default if not present.
func get_modifier(key: String, default: Variant = null) -> Variant:
	return modifiers.get(key, default)

## The list of currently active passive IDs.
func get_active_ids() -> Array[StringName]:
	return active_ids.duplicate()
