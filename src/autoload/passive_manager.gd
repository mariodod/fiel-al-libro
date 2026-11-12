extends Node
## PassiveManager — applies equipped-book passive modifiers to characters.
signal modifiers_changed()
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
var _registry: Dictionary = {}
var active_ids: Array[StringName] = []

func _ready() -> void:
	EventBus.shelf_changed.connect(_on_shelf_changed)
	_on_shelf_changed(Biblioteca.equipped_books())

func register(passive: Resource) -> void:
	if passive == null:
		return
	var id: StringName = passive.get("id")
	if id == null or id == &"":
		return
	_registry[id] = passive

func get_passive(id: StringName) -> Resource:
	return _registry.get(id, null)

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
		m["health_bonus"] += float(_pd_get(p, "health_bonus", 0.0))
		m["health_percent"] *= float(_pd_get(p, "health_percent", 1.0))
		m["stamina_bonus"] += float(_pd_get(p, "stamina_bonus", 0.0))
		m["stamina_percent"] *= float(_pd_get(p, "stamina_percent", 1.0))
		m["poise_bonus"] += float(_pd_get(p, "poise_bonus", 0.0))
		m["speed_percent"] *= float(_pd_get(p, "speed_percent", 1.0))
		m["dodge_distance_percent"] *= float(_pd_get(p, "dodge_distance_percent", 1.0))
		m["dodge_iframe_percent"] *= float(_pd_get(p, "dodge_iframe_percent", 1.0))
		m["damage_percent"] *= float(_pd_get(p, "damage_percent", 1.0))
		m["block_ratio_percent"] *= float(_pd_get(p, "block_ratio_percent", 1.0))
		m["parry_window_bonus"] += float(_pd_get(p, "parry_window_bonus", 0.0))
		m["locura_per_second"] += float(_pd_get(p, "locura_per_second", 0.0))
	return m

func _pd_get(d: Dictionary, key: String, default: Variant) -> Variant:
	var v := d.get(key)
	return v if v != null else default

func _apply_to_pawns() -> void:
	for pawn in get_tree().get_nodes_in_group(&"pawns"):
		if pawn is CharacterPawn:
			pawn.apply_passive_modifiers(modifiers)

func get_modifier(key: String, default: Variant = null) -> Variant:
	var v := modifiers.get(key)
	return v if v != null else default

func get_active_ids() -> Array[StringName]:
	return active_ids.duplicate()