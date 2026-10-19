extends Node3D
## WEEK 1–2 GREY BOX — the cheapest possible test of the core idea.
##
## NEXT_STEPS.md §2, tasks 2.1–2.4:
##
##   2.1  two primitives, same object, two states
##   2.2  one toggle that changes the world's truth
##   2.3  two characters reading the same world differently
##   2.4  play it twenty times, and write down what you feel
##
## Nothing in here is final. If the two-truths mechanic is not fun in this
## box it will not be fun in a real level, and we find out in week 12
## instead of month 24.
##
## ── The controls ───────────────────────────────────────────────────────
##   WASD / Shift   walk, run
##   TAB            swap character
##   T              the world's truth flips
##   V              Sancho's second sight. WITHOUT it he cannot see the Book
##                  at all, so the two readings disagree — which is the
##                  point. Turn it on and he sees what you see.
##   L              Quixote's Locura: Lucid <-> Lost
##   F1             this help
##
## ── What to look at ────────────────────────────────────────────────────
##   Press T. The windmill becomes a giant and the rock becomes a book.
##   Then press TAB: you are looking through Sancho's eyes now, and the
##   giant is a windmill again. Same world. Two readings.
##
##   That gap — between what the world is and what each of them makes of
##   it — is the entire game. Everything else is level design.

@onready var quixote: CharacterPawn = $Characters/Quixote
@onready var sancho: CharacterPawn = $Characters/Sancho
@onready var player: PlayerController = $PlayerController
@onready var ai: CompanionAI = $CompanionAI
@onready var camera_rig: CameraFollow = $CameraRig
@onready var hud: Label = $HudLayer/Hud
@onready var windmill: TruthObject = $Windmill
@onready var rock: TruthObject = $Rock

var _objects: Array[TruthObject] = []
var _show_help: bool = true
## Sancho's second sight.
##
## OFF by default, and that default is the whole point: without the lens
## Sancho cannot see the Book, so he reads the world differently from
## Quixote, and the disagreement is on screen from the first minute. Turn it
## on and he sees what you see — which is the other half of the mechanic.
var _second_sight: bool = false
## Quixote's madness, toggled between Lucid and Lost.
var _madness_high: bool = false

const LOCURA_LUCID := 10.0
const LOCURA_LOST := 60.0


func _ready() -> void:
	_objects = [windmill, rock]

	_build_environment()
	_build_characters()
	_build_post_process()

	EventBus.character_switched.connect(_on_character_switched)


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


func _build_post_process() -> void:
	var layer := CanvasLayer.new()
	layer.name = "PostProcessLayer"
	layer.layer = 10
	add_child(layer)

	var post := ColorRect.new()
	post.name = "PostProcess"
	post.set_script(load("res://src/ui/post_process.gd"))
	layer.add_child(post)


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


# ── Per frame ───────────────────────────────────────────────────────────

func _process(_delta: float) -> void:
	_update_readings()
	_update_hud()


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


## What the companion is looking at, written over the object.
func _tag_text_for(character: CharacterPawn, object: TruthObject) -> String:
	var who := _character_name(character)
	var form := Loc.t(object.name_key_for(character.perceived_layer))
	return Loc.tf(&"ui.perception.tag", [who, form])


func _character_name(character: CharacterPawn) -> String:
	if character != null and character.data != null:
		return Loc.t(character.data.display_name_key)
	return String(character.character_id) if character != null else ""


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

	lines.append("")
	for object in _objects:
		lines.append(Loc.tf(&"ui.slice.line.object", [
			Loc.t(object.data.title_key()),
			_character_name(driven),
			Loc.t(_form_name_key(driven, object)),
			_character_name(other),
			Loc.t(_form_name_key(other, object)),
		]))

	if _show_help:
		lines.append("")
		lines.append(Loc.t(&"ui.slice.help.1"))
		lines.append(Loc.t(&"ui.slice.help.2"))
		lines.append(Loc.t(&"ui.slice.help.3"))

	hud.text = "\n".join(lines)


func _form_name_key(character: CharacterPawn, object: TruthObject) -> StringName:
	return object.name_key_for(character.perceived_layer)


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
		camera_rig.target = player.active_pawn
	if ai != null and player != null:
		ai.pawn = player.other_pawn
		ai.leader = player.active_pawn
