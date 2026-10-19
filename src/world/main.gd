extends Node3D
## PHASE 0 GREY-BOX SCENE
##
## The Phase 0 milestone in ROADMAP.md §5: "a grey-box scene where you can
## walk around, switch characters, and see the world flip between Reality
## and Book. Ugly is fine."
##
## Everything below is placeholder geometry built in code so that the
## project opens, runs and demonstrates the two core systems (the swap and
## the truth layer) without a single hand-authored .tscn. Replace it with
## real scenes during Phase 1.

var player: PlayerController
var quixote: CharacterPawn
var sancho: CharacterPawn
var camera_rig: CameraFollow
var hud: Label

var _show_help: bool = true


func _ready() -> void:
	_build_environment()
	_build_world()
	_build_characters()
	_build_camera()
	_build_post_process()
	_build_hud()
	_connect_signals()


# ── World ───────────────────────────────────────────────────────────────

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
	we.environment = env
	add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-42.0, 128.0, 0.0)
	sun.light_energy = 1.35
	sun.light_color = Color(1.0, 0.93, 0.80)
	sun.shadow_enabled = true
	add_child(sun)


func _build_world() -> void:
	# Ground: a big dry plain.
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(200.0, 200.0)
	ground.mesh = plane
	var ground_mat := StandardMaterial3D.new()
	ground_mat.albedo_color = Color(0.55, 0.47, 0.31)
	ground_mat.roughness = 0.95
	ground_mat.metallic = 0.0
	ground.material_override = ground_mat
	ground.position = Vector3(0.0, 0.0, 0.0)
	add_child(ground)

	# The windmill — the first Venture of the game. A placeholder tower.
	var mill := _make_box(Vector3(3.0, 8.0, 3.0), Vector3(0.0, 4.0, -14.0), Color(0.44, 0.36, 0.26))
	mill.name = "Windmill"
	add_child(mill)

	# Four sails, which will be the boss in the vertical slice.
	for i in range(4):
		var angle := TAU * float(i) / 4.0
		var sail := _make_box(Vector3(0.4, 5.0, 1.2), Vector3.ZERO, Color(0.72, 0.65, 0.50))
		sail.position = Vector3(0.0, 8.0, -14.0)
		sail.rotation = Vector3(0.0, 0.0, angle)
		sail.position += Vector3(sin(angle), cos(angle), 0.0) * 2.5
		add_child(sail)

	# A few landmark blocks to navigate by.
	add_child(_make_box(Vector3(6.0, 4.0, 6.0), Vector3(-12.0, 2.0, -8.0), Color(0.62, 0.56, 0.44)))
	add_child(_make_box(Vector3(4.0, 3.0, 4.0), Vector3(14.0, 1.5, -6.0), Color(0.50, 0.40, 0.30)))
	add_child(_make_box(Vector3(2.0, 6.0, 2.0), Vector3(8.0, 3.0, 8.0), Color(0.40, 0.34, 0.28)))


func _make_box(size: Vector3, pos: Vector3, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	mi.material_override = mat
	mi.position = pos
	return mi


# ── Characters ──────────────────────────────────────────────────────────

func _build_characters() -> void:
	quixote = _make_pawn(&"quixote", Color(0.42, 0.34, 0.28), Vector3(0.0, 0.0, 0.0))
	sancho = _make_pawn(&"sancho", Color(0.36, 0.42, 0.34), Vector3(2.0, 0.0, 2.0))
	add_child(quixote)
	add_child(sancho)

	quixote.companion = sancho
	sancho.companion = quixote

	player = PlayerController.new()
	player.name = "PlayerController"
	player.active_pawn = quixote
	player.other_pawn = sancho
	add_child(player)

	# The companion drives whichever pawn the player is not.
	var ai := CompanionAI.new()
	ai.name = "CompanionAI"
	ai.pawn = sancho
	ai.leader = quixote
	add_child(ai)


func _make_pawn(id: StringName, color: Color, pos: Vector3) -> CharacterPawn:
	var pawn := CharacterPawn.new()
	pawn.name = String(id).capitalize()
	pawn.character_id = id
	pawn.position = pos

	var data := CharacterData.new()
	data.id = id
	data.display_name_key = id
	data.max_stamina = 100.0 if id == &"quixote" else 120.0
	data.poise = 34.0 if id == &"quixote" else 24.0
	# Quixote reads the Book. Sancho reads Reality. (GDD.md §4.2)
	data.truth_layer_affinity = 1 if id == &"quixote" else 0
	data.companion_aggression = 1.0 if id == &"quixote" else 0.3
	pawn.data = data

	var mesh := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.42
	capsule.height = 1.75
	mesh.mesh = capsule
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.8
	mesh.material_override = mat
	mesh.position = Vector3(0.0, 0.88, 0.0)
	pawn.add_child(mesh)

	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.42
	shape.height = 1.75
	collision.shape = shape
	collision.position = Vector3(0.0, 0.88, 0.0)
	pawn.add_child(collision)

	return pawn


# ── Camera, post-process, HUD ───────────────────────────────────────────

func _build_camera() -> void:
	camera_rig = CameraFollow.new()
	camera_rig.name = "CameraRig"
	camera_rig.target = quixote
	camera_rig.distance = 8.0
	camera_rig.height = 3.6
	add_child(camera_rig)

	var cam := Camera3D.new()
	cam.fov = 62.0
	cam.current = true
	camera_rig.add_child(cam)


func _build_post_process() -> void:
	var layer := CanvasLayer.new()
	layer.name = "PostProcessLayer"
	layer.layer = 10
	add_child(layer)

	var post := ColorRect.new()
	post.name = "PostProcess"
	post.set_script(load("res://src/ui/post_process.gd"))
	post.size = Vector2(1152, 648)
	layer.add_child(post)


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = "HudLayer"
	layer.layer = 20
	add_child(layer)

	hud = Label.new()
	hud.name = "Hud"
	hud.set_anchors_preset(Control.PRESET_TOP_LEFT)
	hud.position = Vector2(16, 16)
	hud.add_theme_font_size_override("font_size", 16)
	hud.add_theme_color_override("font_color", Color(0.94, 0.90, 0.80))
	hud.text = ""
	layer.add_child(hud)


func _connect_signals() -> void:
	EventBus.character_switched.connect(_on_switched)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"toggle_truth"):
		TruthLayer.toggle()
	if event.is_action_pressed(&"toggle_help"):
		_show_help = not _show_help


func _process(_delta: float) -> void:
	if hud == null:
		return
	var lines: Array[String] = []
	lines.append("FIEL AL LIBRO — grey-box (Phase 0)")
	lines.append("Truth layer : %s" % ("BOOK" if TruthLayer.is_book() else "REALITY"))
	lines.append("Driving     : %s" % (quixote.character_id if player.active_pawn == quixote else sancho.character_id))
	lines.append("Quixote Loc : %d" % int(Locura.get_for(&"quixote")))
	lines.append("Sancho Loc  : %d" % int(Locura.get_for(&"sancho")))
	lines.append("Humanity    : %d" % GameState.humanity)
	lines.append("Recuerdos Q : %d" % Memoria.get_for(&"quixote"))
	if _show_help:
		lines.append("")
		lines.append("WASD move · Shift sprint · Space dodge · LMB light · RMB heavy")
		lines.append("TAB swap character · T toggle truth · F1 toggle this help")
	hud.text = "\n".join(lines)


func _on_switched(from_id: StringName, to_id: StringName) -> void:
	# Move the camera to whoever we are now driving.
	if camera_rig != null and player != null and player.active_pawn != null:
		camera_rig.target = player.active_pawn
	# The companion AI now drives the other one.
	for child: Node in get_children():
		if child is CompanionAI:
			(child as CompanionAI).pawn = player.other_pawn
			(child as CompanionAI).leader = player.active_pawn
