extends SceneTree

## Quick validation: load every environment kit and report errors.
## Run: godot --headless --script res://src/tools/validate_kits.gd

const KITS := [
	"res://src/world/environment_kits/field_kit.tscn",
	"res://src/world/environment_kits/inn_kit.tscn",
	"res://src/world/environment_kits/road_kit.tscn",
	"res://src/world/environment_kits/mountain_kit.tscn",
	"res://src/world/environment_kits/cave_kit.tscn",
	"res://src/world/environment_kits/river_kit.tscn",
	"res://src/world/environment_kits/village_kit.tscn",
	"res://src/world/environment_kits/cliff_kit.tscn",
	"res://src/world/environment_kits/church_kit.tscn",
	"res://src/world/environment_kits/castle_kit.tscn",
	"res://src/world/environment_kits/theatre_kit.tscn",
	"res://src/world/environment_kits/windmill_kit.tscn",
	"res://src/world/environment_kits/fog_plane_kit.tscn",
	"res://src/world/environment_kits/bridge_kit.tscn",
	"res://src/world/environment_kits/inn_courtyard_kit.tscn",
]

func _init() -> void:
	var errors := 0
	for kit in KITS:
		var scene := load(kit)
		if scene == null:
			print("FAILED: %s — could not load" % kit)
			errors += 1
		else:
			print("OK: %s" % kit)
	print("")
	if errors == 0:
		print("All %d kits valid." % KITS.size())
		quit(0)
	else:
		print("%d kit(s) failed." % errors)
		quit(1)
