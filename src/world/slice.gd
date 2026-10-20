extends Node3D
## THE GREY BOX — the cheapest possible test of the core idea, and then
## the cheapest possible test of the dodge.
##
## NEXT_STEPS.md §2, tasks 2.1–2.4:
##
##   2.1  two primitives, same object, two states
##   2.2  one toggle that changes the world's truth
##   2.3  two characters reading the same world differently
##   2.4  play it twenty times, and write down what you feel
##
## And, from week 3–4, the practice yard (2.6b): something to fight, and
## somewhere you cannot run.
##
## Nothing in here is final. If the two-truths mechanic is not fun in this
## box it will not be fun in a real level, and we find out in week 12
## instead of month 24.
##
## ── The controls ───────────────────────────────────────────────────────
##   WASD / Shift   walk, run
##   TAB            swap character
##   T              the world's truth flips
##   E              examine the thing in front of you
##   V              Sancho's second sight. WITHOUT it he cannot see the Book
##                  at all, so the two readings disagree — which is the
##                  point. Turn it on and he sees what you see.
##   L              Quixote's Locura: Lucid <-> Lost
##   Space          dodge
##   LMB / RMB      light attack / heavy attack
##   M              lock on: the target you are looking at
##   K              reset the yard (the dummy and anyone who fell)
##   F1             this help
##   F2             the floating perception tags
##   H              the HUD — the developer's readout. Turn it off before
##                  you hand the build to somebody.
##
## ── What to look at ────────────────────────────────────────────────────
##   Press T. The windmill becomes a giant and the rock becomes a book.
##   Then press TAB: you are looking through Sancho's eyes now, and the
##   giant is a windmill again. Same world. Two readings.
##
##   That gap — between what the world is and what each of them makes of
##   it — is the entire game. Everything else is level design.
##
## ── Where to go ────────────────────────────────────────────────────────
##   To the west is a walled yard with a training dummy in it. The
##   dummy swings on a rhythm and it hurts. The walls mean there is
##   nowhere to run. That is the rig the dodge needs: a dodge with no
##   enemy and no walls is a dash, and you cannot tell a good one from a
##   bad one.

@onready var quixote: CharacterPawn = $Characters/Quixote
@onready var sancho: CharacterPawn = $Characters/Sancho
@onready var player: PlayerController = $PlayerController
@onready var ai: CompanionAI = $CompanionAI
@onready var camera_rig: CameraFollow = $CameraRig
@onready var hud: Label = $HudLayer/Hud
@onready var windmill: TruthObject = $Windmill
@onready var rock: TruthObject = $Rock

## The practice yard: a bounded space with something in it to fight.
##
## The second playtest, in one line: *"For the dodge it is difficult to
## assess if it's fine at this stage without any enemies or space
## limitations."* This is the answer — four walls, a gate, and a dummy
## that swings on a rhythm.
const YARD_CENTER := Vector3(-16.0, 0.0, -4.0)
## How far the yard is from its centre to each wall.
const YARD_HALF := 9.0
const WALL_HEIGHT := 2.5
const WALL_THICKNESS := 0.8
## How wide the gate in the east wall is.
const GATE_HALF := 3.0

var _objects: Array[TruthObject] = []
var _show_help: bool = true
## The developer's readout. A stranger must not have it: it spells out
## both readings, which is the whole mechanic, handed over.
var _show_hud: bool = true
## The floating tags that say what the companion is looking at.
##
## The first playtest: "Text showing what the other sees feels like too
## handholding, the layer should change characters to see the whole world".
## That is right — in the finished game the disagreement has to be carried
## by barks and VFX, not by a label. The tag stays here as a test
## affordance, and F2 turns it off.
##
## For the stranger test (runs 18-19 of the playtest), turn it OFF: a
## stranger should find the second reading by swapping, not by reading it.
var _show_tags: bool = true
## Sancho's second sight.
##
## OFF by default, and that default is the whole point: without the lens
## Sancho cannot see the Book, so he reads the world differently from
## Quixote, and the disagreement is on screen from the first minute. Turn it
## on and he sees what you see — which is the other half of the mechanic.
var _second_sight: bool = false
## Quixote's madness, toggled between Lucid and Lost.
var _madness_high: bool = false
## The reading each character had last frame, so we can tell when it moves.
var _last_reading: Dictionary = {}
## The dummy in the yard.
var _dummy: TrainingDummy = null
## The marker over the locked target.
var _lock_marker: Label3D = null

const LOCURA_LUCID := 10.0
const LOCURA_LOST := 60.0


func _ready() -> void:
	_objects = [windmill, rock]

	_build_environment()
	_build_yard()
	_build_characters()
	_build_post_process()
	_build_examine_panel()
	_build_bark_line()
	_build_lock_marker()

	EventBus.character_switched.connect(_on_character_switched)
	EventBus.character_died.connect(_on_character_died)
	EventBus.character_parried.connect(_on_character_parried)


# ── World ───────────────────────────────────────────────────────────────

## The sky and the sun, in code: the environment is a look, not content,
## and the enum values are easier to read here than in a scene file.
func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.42, 0.50, 0.62)
	sky_material.sky_horizon_color = Color(0.78, 0.71, 0.56)
	sky_material.ground_bottom_color = Color(0.30, 0.26, 0.20)
	sky_material.ground_horizon_color = Color(0.62, 0.56, 0.42)
	sky_material.sun_angle_max = 8.0
	sky.sky_material = sky_material
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	# The La Mancha plain: long shadows, dry air, a lot of distance.
	env.fog_enabled = true
	env.fog_density = 0.006
	env.fog_light_color = Color(0.80, 0.74, 0.60)
	env.fog_sun_scatter = 0.15

	var we := WorldEnvironment.new()
	we.name = "WorldEnvironment"
	we.environment = env
	add_child(we)

	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-42.0, 128.0, 0.0)
	sun.light_energy = 1.35
	sun.light_color = Color(1.0, 0.93, 0.80)
	sun.shadow_enabled = true
	add_child(sun)


## The practice yard: four walls, a gate, and a dummy.
##
## A dodge on an open plain is a dash. You cannot tell a good one from a
## bad one, because there is nothing to dodge and nowhere you cannot go.
## The walls are the space limit and the dummy is the thing to dodge
## against; between them they are the rig the dodge has been missing.
func _build_yard() -> void:
	var yard := Node3D.new()
	yard.name = "Yard"
	add_child(yard)

	# North, south and west are solid.
	_add_wall(yard,
		Vector3(YARD_CENTER.x, WALL_HEIGHT * 0.5, YARD_CENTER.z - YARD_HALF),
		Vector3(YARD_HALF * 2.0, WALL_HEIGHT, WALL_THICKNESS))
	_add_wall(yard,
		Vector3(YARD_CENTER.x, WALL_HEIGHT * 0.5, YARD_CENTER.z + YARD_HALF),
		Vector3(YARD_HALF * 2.0, WALL_HEIGHT, WALL_THICKNESS))
	_add_wall(yard,
		Vector3(YARD_CENTER.x - YARD_HALF, WALL_HEIGHT * 0.5, YARD_CENTER.z),
		Vector3(WALL_THICKNESS, WALL_HEIGHT, YARD_HALF * 2.0))

	# The east wall has the gate in it, so the yard can be entered.
	var gate_length := YARD_HALF - GATE_HALF
	var gate_offset := (YARD_HALF + GATE_HALF) * 0.5
	_add_wall(yard,
		Vector3(YARD_CENTER.x + YARD_HALF, WALL_HEIGHT * 0.5, YARD_CENTER.z - gate_offset),
		Vector3(WALL_THICKNESS, WALL_HEIGHT, gate_length))
	_add_wall(yard,
		Vector3(YARD_CENTER.x + YARD_HALF, WALL_HEIGHT * 0.5, YARD_CENTER.z + gate_offset),
		Vector3(WALL_THICKNESS, WALL_HEIGHT, gate_length))

	# The dummy stands in the middle of it, facing the gate.
	_dummy = TrainingDummy.new()
	_dummy.name = "TrainingDummy"
	_dummy.position = YARD_CENTER
	# The dummy faces -Z, like everything else in this build. Turn it to
	# face east, towards the way in.
	_dummy.rotation.y = -PI * 0.5
	yard.add_child(_dummy)


## One wall: a box you cannot walk through.
func _add_wall(parent: Node3D, position: Vector3, size: Vector3) -> void:
	var wall := StaticBody3D.new()
	wall.name = "Wall"
	wall.position = position
	wall.collision_layer = 1
	wall.collision_mask = 1

	var collider := CollisionShape3D.new()
	collider.name = "Shape"
	var shape := BoxShape3D.new()
	shape.size = size
	collider.shape = shape
	wall.add_child(collider)

	var mesh := MeshInstance3D.new()
	mesh.name = "Mesh"
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.44, 0.38, 0.30, 1.0)
	material.roughness = 0.95
	mesh.material_override = material
	wall.add_child(mesh)

	parent.add_child(wall)


func _build_post_process() -> void:
	var layer := CanvasLayer.new()
	layer.name = "PostProcessLayer"
	layer.layer = 10
	add_child(layer)

	var post := ColorRect.new()
	post.name = "PostProcess"
	post.set_script(load("res://src/ui/post_process.gd"))
	layer.add_child(post)


## The Examine panel.
##
## Its own layer, between the post-process and the HUD, so the truth
## shader does not wash out the text but the HUD still sits on top.
func _build_examine_panel() -> void:
	var layer := CanvasLayer.new()
	layer.name = "ExamineLayer"
	layer.layer = 15
	add_child(layer)

	var panel := Control.new()
	panel.name = "ExaminePanel"
	panel.set_script(load("res://src/ui/examine_panel.gd"))
	layer.add_child(panel)


## The line somebody said.
##
## Its own layer with the Examine panel, above the post-process so the
## truth shader does not wash the words out.
func _build_bark_line() -> void:
	var layer := CanvasLayer.new()
	layer.name = "BarkLayer"
	layer.layer = 15
	add_child(layer)

	var bark := Control.new()
	bark.name = "BarkLine"
	bark.set_script(load("res://src/ui/bark_line.gd"))
	layer.add_child(bark)


## The marker over the locked target.
##
## A soft lock you cannot see is not a lock. The marker says what you
## are locked onto, and it goes away when the lock does.
func _build_lock_marker() -> void:
	_lock_marker = Label3D.new()
	_lock_marker.name = "LockMarker"
	_lock_marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_lock_marker.no_depth_test = true
	_lock_marker.double_sided = true
	_lock_marker.font_size = 48
	_lock_marker.pixel_size = 0.014
	_lock_marker.outline_size = 0
	_lock_marker.modulate = Color(0.95, 0.85, 0.65)
	_lock_marker.text = ""
	_lock_marker.visible = false
	add_child(_lock_marker)


# ── Characters ──────────────────────────────────────────────────────────

func _build_characters() -> void:
	quixote.companion = sancho
	sancho.companion = quixote

	player.active_pawn = quixote
	player.other_pawn = sancho

	ai.pawn = sancho
	ai.leader = quixote

	# The camera looks at whoever you are driving. Set in code, not in the
	# scene file: an exported NodePath in a .tscn does not resolve the way
	# you would hope, and a camera pointed at nothing is a silent failure.
	camera_rig.target = quixote

	# Quixote starts Lucid on purpose. The slice has to show the truth
	# toggle doing something, and a mad Quixote no longer sees Reality, so
	# the toggle would look broken. Press L to push him over the edge and
	# watch the toggle stop mattering to him.
	Locura.set_for(&"quixote", LOCURA_LUCID)
	sancho.second_sight = _second_sight


# ── Input ───────────────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"toggle_truth"):
		# The world's truth. This is what a Verdict does.
		TruthLayer.toggle()
	elif event.is_action_pressed(&"toggle_help"):
		_show_help = not _show_help
	elif event.is_action_pressed(&"toggle_second_sight"):
		_second_sight = not _second_sight
		sancho.second_sight = _second_sight
	elif event.is_action_pressed(&"toggle_madness"):
		_madness_high = not _madness_high
		Locura.set_for(&"quixote", LOCURA_LOST if _madness_high else LOCURA_LUCID)
	elif event.is_action_pressed(&"toggle_tags"):
		_show_tags = not _show_tags
		for object in _objects:
			object.show_tag = _show_tags
	elif event.is_action_pressed(&"toggle_hud"):
		_show_hud = not _show_hud
		if hud != null:
			hud.visible = _show_hud
	elif event.is_action_pressed(&"reset_dummy"):
		_reset_yard()


## Put the yard back: the dummy stands up, and anyone who fell gets up.
func _reset_yard() -> void:
	if _dummy != null:
		_dummy.reset()
	for pawn in [player.active_pawn, player.other_pawn]:
		if pawn != null and pawn.is_dead:
			pawn.revive()


# ── Per frame ───────────────────────────────────────────────────────────

func _process(_delta: float) -> void:
	_update_readings()
	_update_lock()
	_update_hud()


## Keep the camera and the marker on the locked target.
##
## The lock belongs to the character the player is driving, so it is
## re-read every frame: swap characters and the lock goes with them.
func _update_lock() -> void:
	var driven: CharacterPawn = player.active_pawn
	var locked: Node3D = driven.lock_target if driven != null else null
	if camera_rig != null:
		camera_rig.lock_target = locked
	if _lock_marker == null:
		return
	if locked == null or not is_instance_valid(locked):
		_lock_marker.visible = false
		_lock_marker.text = ""
		return
	_lock_marker.visible = true
	_lock_marker.global_position = locked.global_position + Vector3(0.0, 2.6, 0.0)
	_lock_marker.text = Loc.t(&"ui.lockon.marker")


## Work out what each character is reading, and show it.
func _update_readings() -> void:
	var driven: CharacterPawn = player.active_pawn
	var other: CharacterPawn = player.other_pawn
	if driven == null or other == null:
		return

	var world_layer := TruthLayer.layer()
	driven.refresh_perception(world_layer)
	other.refresh_perception(world_layer)

	# The camera is a person's eyes: the picture is filtered the way the
	# character you are driving filters it. The world's truth is still
	# global; this only changes what you are shown.
	TruthLayer.set_view_layer(driven.perceived_layer)

	var blend := TruthLayer.view_blend()
	for object in _objects:
		object.apply_blend(blend)
		object.set_tag_text(_tag_text_for(other, object))

	_check_reactions(driven, other)


## B5: when a character's reading changes, they say something.
##
## *"When quixote goes back to seeing reality some reaction from his side
## should happen."* A filter change is invisible. A character who says so
## is a character, and it is the only way the player finds out that the
## world they are in is not the world they were in.
##
## The reading changes when the world's truth turns over, and when the
## madness lets go and Reality comes back to Quixote.
func _check_reactions(driven: CharacterPawn, other: CharacterPawn) -> void:
	for character in [driven, other]:
		if character == null:
			continue
		var previous: int = int(_last_reading.get(character.character_id, -1))
		var current: int = character.perceived_layer
		_last_reading[character.character_id] = current
		if previous < 0 or previous == current:
			continue
		_react(character, current)


## The line, and the thing it is about.
func _react(character: CharacterPawn, layer: int) -> void:
	var target: TruthObject = player.examine_target
	if target == null or target.data == null:
		return
	var key := Reaction.bark_key(character.character_id, target.data.id, layer)
	if key.is_empty():
		return
	EventBus.character_spoke.emit(character.character_id, key, [])


## What the companion is looking at, written over the object.
func _tag_text_for(character: CharacterPawn, object: TruthObject) -> String:
	var who := _character_name(character)
	var form := Loc.t(object.name_key_for(character.perceived_layer))
	return Loc.tf(&"ui.perception.tag", [who, form])


func _character_name(character: CharacterPawn) -> String:
	if character == null:
		return ""
	return character.display_name()


func _update_hud() -> void:
	if hud == null:
		return
	var driven: CharacterPawn = player.active_pawn
	var other: CharacterPawn = player.other_pawn
	if driven == null or other == null:
		return

	var lines: Array[String] = []
	lines.append(Loc.t(&"ui.slice.title"))
	lines.append(Loc.tf(&"ui.slice.line.world", [_layer_name(TruthLayer.layer())]))
	lines.append(Loc.tf(&"ui.slice.line.you", [
		_character_name(driven),
		Loc.t(_form_name_key(driven, windmill)),
	]))
	lines.append(Loc.tf(&"ui.slice.line.companion", [
		_character_name(other),
		Loc.t(_form_name_key(other, windmill)),
	]))
	lines.append(Loc.tf(&"ui.slice.line.second_sight", [
		Loc.t(&"ui.on") if _second_sight else Loc.t(&"ui.off"),
	]))
	lines.append(Loc.tf(&"ui.slice.line.locura", [
		int(Locura.get_for(&"quixote")),
		Loc.t(&"ui.locura.%s" % _locura_band()),
	]))
	lines.append(Loc.tf(&"ui.slice.line.vitals", [
		_character_name(driven),
		int(driven.health),
		int(driven.stamina),
		int(driven.poise),
		int(driven.max_poise),
	]))

	lines.append("")
	for object in _objects:
		lines.append(Loc.tf(&"ui.slice.line.object", [
			Loc.t(object.data.title_key()),
			_character_name(driven),
			Loc.t(_form_name_key(driven, object)),
			_character_name(other),
			Loc.t(_form_name_key(other, object)),
		]))

	if _dummy != null:
		lines.append(Loc.tf(&"ui.slice.line.dummy", [
			int(_dummy.health), int(_dummy.max_health),
		]))

	if driven.is_locked():
		lines.append(Loc.tf(&"ui.slice.line.locked", [
			_lock_target_name(driven.lock_target),
		]))

	if _show_help:
		lines.append("")
		lines.append(Loc.t(&"ui.slice.help.1"))
		lines.append(Loc.t(&"ui.slice.help.2"))
		lines.append(Loc.t(&"ui.slice.help.3"))
		lines.append(Loc.t(&"ui.slice.help.4"))
		lines.append(Loc.t(&"ui.slice.help.5"))

	hud.text = "\n".join(lines)


func _form_name_key(character: CharacterPawn, object: TruthObject) -> StringName:
	return Examine.reading_key(object, character)


## The name of a locked target, if it has one.
func _lock_target_name(target: Node3D) -> String:
	if target != null and target.has_method("display_name"):
		return str(target.call("display_name"))
	return ""


func _layer_name(layer: int) -> String:
	return Loc.t(&"ui.layer.book") if layer == 1 else Loc.t(&"ui.layer.reality")


func _locura_band() -> String:
	match Locura.threshold_for(&"quixote"):
		Locura.Threshold.LUCID:
			return "lucid"
		Locura.Threshold.DISPLACED:
			return "displaced"
		Locura.Threshold.LOST:
			return "lost"
		_:
			return "absorbed"


# ── Signals ─────────────────────────────────────────────────────────────

func _on_character_switched(_from_id: StringName, _to_id: StringName) -> void:
	# Move the camera to whoever we are now driving, and hand the other
	# one to the companion AI.
	if camera_rig != null and player != null and player.active_pawn != null:
		# Cut, do not drift. The first playtest: "not sure about the
		# transition when swapping... in the objects morphing rather than a
		# direct view switch". A cut reads as a page turn; a slide reads as
		# a camera that lost track of the player.
		camera_rig.snap()
		camera_rig.target = player.active_pawn
	if ai != null and player != null:
		ai.pawn = player.other_pawn
		ai.leader = player.active_pawn


## Somebody went down in the yard.
##
## There is no death screen in the grey box — that is a whole system
## (GDD.md §7.3, the unwritten page). But a character who cannot get up
## and is not told how is a stuck build, so the yard says so.
func _on_character_died(character_id: StringName) -> void:
	EventBus.toast.emit(&"ui.slice.down", [])


## A blow was caught on the guard.
##
## The parry is Sancho's and not Quixote's, and it is the biggest moment
## in a fight, so somebody says something about it.
func _on_character_parried(character_id: StringName) -> void:
	EventBus.character_spoke.emit(character_id, Chatter.key_for(character_id, &"parry"), [])
