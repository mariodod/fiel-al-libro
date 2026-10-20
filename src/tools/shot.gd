extends Node
## The screenshot rig.
##
## The playtest runs on evidence, and the truth-layer shader cannot be
## judged from a log line. This loads the playable scene, poses it, presses
## the keys, and writes PNGs into artifacts/ so that a change can be seen
## rather than argued about.
##
##     tools\play.cmd res://src/tools/shot.tscn
##
## The PNGs land in artifacts/, which is gitignored: they are outputs, not
## sources.
##
## The shots it takes:
##   shot_reality.png    the grey box, the world in Reality
##   shot_book.png       the same, the world in the Book
##   shot_examine.png    the Examine panel, in the Book: a book in a rock
##   shot_examine_real.png  the same panel, in Reality: a stone
##   shot_yard.png       the practice yard, and the dummy in it
##
## See HANDOVER.md §4.

## Where the PNGs go.
const OUT_DIR := "res://artifacts/"

## The rock is at (11, 0, -11) in the slice. This is a spot next to it,
## facing it.
const SPOT := Vector3(11.0, 0.0, -8.0)

## The practice yard, and a spot inside it facing the dummy.
const YARD_SPOT := Vector3(-11.0, 0.0, -4.0)


func _ready() -> void:
	var scene: Node = load("res://src/world/slice.tscn").instantiate()
	add_child(scene)
	for i in 6:
		await get_tree().process_frame

	var quixote: CharacterPawn = scene.get_node("Characters/Quixote")
	quixote.global_position = SPOT
	quixote.rotation.y = 0.0

	await _shoot("shot_reality.png")

	# The world turns over to the Book. Quixote's reading changes and he
	# says so: the bark line is up in this shot.
	TruthLayer.shift_to(TruthLayer.Layer.BOOK, true)
	await _settle(scene)
	await _shoot("shot_book.png")

	# And the Examine verb, in the Book, where the two of them disagree.
	var controller: PlayerController = scene.get_node("PlayerController")
	controller.call("_update_examine_target", 1.0)
	var press := InputEventAction.new()
	press.action = &"interact"
	press.pressed = true
	controller._unhandled_input(press)
	await _settle(scene)
	await _shoot("shot_examine.png")

	# The same panel in Reality: the same object, read the other way.
	TruthLayer.shift_to(TruthLayer.Layer.REALITY, true)
	await _settle(scene)
	controller.call("_update_examine_target", 1.0)
	controller._unhandled_input(press)
	await _settle(scene)
	await _shoot("shot_examine_real.png")

	# And the yard: the walls, the dummy, and the space the dodge is
	# supposed to be judged in.
	quixote.global_position = YARD_SPOT
	quixote.rotation.y = PI * 0.5
	await _settle(scene)
	await _shoot("shot_yard.png")

	# Leave the world as we found it.
	TruthLayer.shift_to(TruthLayer.Layer.REALITY, true)
	Locura.set_for(&"quixote", 10.0)
	TruthLayer.set_view_layer(-1)
	get_tree().quit()


## Two frames' worth of settling: the view fades to the new reading, and
## then the objects follow it.
func _settle(scene: Node) -> void:
	scene.call("_update_readings")
	TruthLayer.advance_blend(2.0)
	scene.call("_update_readings")
	for i in 4:
		await get_tree().process_frame


## Write one PNG.
func _shoot(file_name: String) -> void:
	for i in 20:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	if image == null:
		push_warning("[Shot] Could not read the screen for '%s'." % file_name)
		return
	image.save_png(OUT_DIR + file_name)
	print("[shot] %s" % file_name)
