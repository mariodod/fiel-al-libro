extends RefCounted
const TestHarness = preload("res://tests/test_harness.gd")
## Resting at a Posada is the R key: heal both travellers, record the Posada,
## announce it and save — but only when standing at the checkpoint.

const SLICE := "res://src/world/slice.tscn"

func suite(t):
	t.suite("PosadaRest")

	# Preserve the real autosave and the global state this suite touches.
	var had_save := Manuscrito.has_save(Manuscrito.AUTOSAVE_SLOT)
	var backup := ""
	if had_save:
		var f := FileAccess.open(Manuscrito.slot_path(Manuscrito.AUTOSAVE_SLOT), FileAccess.READ)
		if f != null:
			backup = f.get_as_text()
			f.close()
	var old_region := GameState.current_region
	var old_posada := GameState.current_posada
	var old_humanity := GameState.humanity

	t.test("each region resolves to the Posada its chapter data names")
	for region in RegionGraph.regions.keys():
		t.expect_false(RegionGraph.posada_id_for(region).is_empty(),
			"%s has a Posada" % region)
	var data_dir := DirAccess.open("res://src/data/chapters/")
	for name in data_dir.get_files():
		if not name.ends_with(".tres"):
			continue
		var data: ChapterData = load("res://src/data/chapters/" + name)
		if data == null:
			continue
		t.expect_eq(RegionGraph.posada_id_for(data.region_id), data.posada_id,
			"%s agrees with its ChapterData" % name)

	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var packed := load(SLICE) as PackedScene
	t.expect_true(packed != null, "the slice loads")
	if packed == null:
		return
	var parent: Node = tree.current_scene if tree.current_scene != null else tree.root
	var scene := packed.instantiate()
	parent.add_child(scene)

	var player := scene.get_node_or_null("PlayerController")
	var checkpoint := scene.get_node_or_null("Checkpoint") as Area3D
	var quixote := scene.get_node_or_null("Characters/Quixote")
	var sancho := scene.get_node_or_null("Characters/Sancho")
	t.expect_true(player != null and checkpoint != null and quixote != null and sancho != null,
		"checkpoint and both travellers exist")
	if player == null or checkpoint == null or quixote == null or sancho == null:
		parent.remove_child(scene)
		scene.free()
		_restore(had_save, backup, old_region, old_posada, old_humanity)
		return

	GameState.current_region = &"camino_la_mancha"
	var entered: Array[StringName] = []
	var toasted: Array[StringName] = []
	var on_entered := func(id: StringName): entered.append(id)
	var on_toast := func(key: StringName, _args: Array): toasted.append(key)
	EventBus.posada_entered.connect(on_entered)
	EventBus.toast.connect(on_toast)

	t.test("R at the checkpoint rests, saves and enters the Posada")
	quixote.health = 10.0
	sancho.health = 10.0
	player.active_pawn.global_position = checkpoint.global_position
	var press := InputEventAction.new()
	press.action = &"rest"
	press.pressed = true
	scene.call("_unhandled_input", press)

	t.expect_almost_eq(quixote.health, quixote.max_health, 0.001, "Quixote is healed")
	t.expect_almost_eq(sancho.health, sancho.max_health, 0.001, "Sancho is healed")
	t.expect_eq(GameState.current_posada, &"villanueva", "the region's Posada is recorded")
	t.expect_has(entered, &"villanueva", "posada_entered was emitted")
	t.expect_has(toasted, &"ui.slice.rested", "the rest toast was shown")
	t.expect_true(Manuscrito.has_save(Manuscrito.AUTOSAVE_SLOT), "resting saves the game")
	t.expect_eq(GameState.humanity, old_humanity, "rest does not buy back Humanity")

	t.test("R away from the checkpoint does nothing")
	entered.clear()
	quixote.health = 10.0
	player.active_pawn.global_position = checkpoint.global_position + Vector3(100, 0, 0)
	scene.call("_unhandled_input", press)
	t.expect_almost_eq(quixote.health, 10.0, 0.001, "no healing away from the inn")
	t.expect_eq(entered.size(), 0, "no Posada entered away from the inn")

	EventBus.posada_entered.disconnect(on_entered)
	EventBus.toast.disconnect(on_toast)
	parent.remove_child(scene)
	scene.free()
	_restore(had_save, backup, old_region, old_posada, old_humanity)


func _restore(had_save: bool, backup: String, region: StringName,
		posada: StringName, humanity: int) -> void:
	GameState.current_region = region
	GameState.current_posada = posada
	GameState.humanity = humanity
	if had_save:
		var f := FileAccess.open(Manuscrito.slot_path(Manuscrito.AUTOSAVE_SLOT), FileAccess.WRITE)
		if f != null:
			f.store_string(backup)
			f.close()
	else:
		DirAccess.remove_absolute(
			ProjectSettings.globalize_path(Manuscrito.slot_path(Manuscrito.AUTOSAVE_SLOT)))
