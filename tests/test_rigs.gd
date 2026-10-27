extends RefCounted
const TestHarness = preload("res://tests/test_harness.gd")
const CharacterData = preload("res://src/data/character_data.gd")
## The hero rigs: two skeletons, and the clips that have to cover the
## windows the combat code opens.
##
## These assets live in the repository now (assets/models/*.glb), so the
## suite pins them the way it pins everything else. The important check
## is the last one: **a clip must be at least as long as the gameplay
## window it covers.** A dodge animation that ends before the
## invulnerability does leaves the character rolling after the blow has
## already landed on them, and a hit reaction that ends early lets them
## swing back while the game still thinks they are reeling.

const QUIXOTE_GLB = "res://assets/models/quixote.glb"
const SANCHO_GLB = "res://assets/models/sancho.glb"

## The clips each character must have.
const QUIXOTE_CLIPS: Array[String] = [
	"block", "death", "heavy", "hit", "idle", "idle_lost", "interact",
	"light_1", "light_2", "light_3", "roll", "run", "stagger", "walk",
]
const SANCHO_CLIPS: Array[String] = [
	"block", "death", "desvelar", "heavy", "hit", "idle", "interact",
	"light_1", "light_2", "light_3", "parry", "roll", "run", "stagger", "walk",
]

## How long each clip should be, in seconds, and how much slack there is.
const EXPECTED_LENGTH: Dictionary = {
	"block": 0.20, "death": 1.20, "heavy": 0.90, "hit": 0.367,
	"idle": 2.00, "idle_lost": 2.00, "interact": 1.20,
	"light_1": 0.467, "light_2": 0.467, "light_3": 0.467,
	"roll": 0.267, "run": 0.633, "stagger": 1.30, "walk": 0.90,
	"parry": 0.20, "desvelar": 0.60,
}
## Sancho's clips are shorter than Quixote's in three cases: he reels
## faster, he rolls slower, and he is punished for longer.
const SANCHO_LENGTH_OVERRIDES: Dictionary = {
	"hit": 0.267, "roll": 0.40, "stagger": 1.50,
}

## One frame of slack, at 30 fps.
const SLACK = 0.05


func suite(t):
	t.suite("Rigs")

	var quixote = _load_rig(QUIXOTE_GLB)
	var sancho = _load_rig(SANCHO_GLB)

	t.test("both rigs load")
	t.expect_true(quixote != null, "Quixote's rig should load")
	t.expect_true(sancho != null, "Sancho's rig should load")
	if quixote == null or sancho == null:
		return

	t.test("and they carry every clip")
	_check_clips(t, quixote, QUIXOTE_CLIPS, "Quixote")
	_check_clips(t, sancho, SANCHO_CLIPS, "Sancho")

	t.test("the two characters do not share a clip")
	# Quixote cannot parry and Sancho cannot lose his mind. If they had
	# the same clip, one of those would be a lie.
	var quixote_player = _animation_player(quixote)
	var sancho_player = _animation_player(sancho)
	t.expect_false(quixote_player.has_animation("parry"), "Quixote has no parry")
	t.expect_false(sancho_player.has_animation("idle_lost"), "Sancho has no madness idle")
	t.expect_true(sancho_player.has_animation("desvelar"), "Sancho has the Desvelar")

	t.test("and the bone names are the same in both")
	# Same names, so the game code can drive them the same way.
	var quixote_bones = _bone_names(quixote)
	var sancho_bones = _bone_names(sancho)
	t.expect_eq(quixote_bones.size(), sancho_bones.size(), "the same number of bones")
	var same = true
	for bone in quixote_bones:
		if not sancho_bones.has(bone):
			same = false
	t.expect_true(same, "and the same names")

	t.test("the meshes are the size they should be")
	# 200-800 triangles per character (GDD.md §15.2).
	t.expect_in_range(_triangle_count(quixote), 200.0, 800.0, "Quixote's triangle count")
	t.expect_in_range(_triangle_count(sancho), 200.0, 800.0, "Sancho's triangle count")

	# ── The check that matters ─────────────────────────────────────────
	t.test("every clip covers the window the game opens")
	# The roll has to outlast the invulnerability, the hit reaction the
	# reel, the stagger the punishment, and the parry the window.
	var quixote_data = _character_data(&"quixote")
	var sancho_data = _character_data(&"sancho")
	if quixote_data == null or sancho_data == null:
		t.expect_true(false, "the character data should load")
		return

	_expect_covers(t, quixote, "roll", quixote_data.dodge.iframe_seconds, "Quixote's roll covers his invulnerability")
	_expect_covers(t, sancho, "roll", sancho_data.dodge.iframe_seconds, "Sancho's roll covers his invulnerability")
	_expect_covers(t, quixote, "hit", quixote_data.hit_reaction_seconds, "Quixote's hit reaction covers the reel")
	_expect_covers(t, sancho, "hit", sancho_data.hit_reaction_seconds, "Sancho's hit reaction covers the reel")
	_expect_covers(t, quixote, "stagger", quixote_data.stagger_seconds, "Quixote's stagger covers the punishment")
	_expect_covers(t, sancho, "stagger", sancho_data.stagger_seconds, "Sancho's stagger covers the punishment")
	_expect_covers(t, sancho, "parry", sancho_data.parry_window, "Sancho's parry covers its window")
	_expect_covers(t, sancho, "block", sancho_data.parry_window, "Sancho's guard covers the parry window")
	_expect_covers(t, quixote, "block", quixote_data.parry_window, "Quixote's guard covers the parry window")


## Every clip of a character, with the right length.
func _check_clips(t: TestHarness, rig: Node, clips: Array[String], label: String):
	var player = _animation_player(rig)
	if player == null:
		t.expect_true(false, "%s should have an AnimationPlayer" % label)
		return
	for clip in clips:
		if not player.has_animation(clip):
			t.expect_true(false, "%s should have a '%s' clip" % [label, clip])
			continue
		var expected = EXPECTED_LENGTH.get(clip, 0.0)
		if label == "Sancho" and SANCHO_LENGTH_OVERRIDES.has(clip):
			expected = SANCHO_LENGTH_OVERRIDES[clip]
		var actual = player.get_animation(clip).length
		t.expect_true(absf(actual - expected) <= SLACK,
			"%s's '%s' should be %.3f s, got %.3f s" % [label, clip, expected, actual])


## A clip has to be at least as long as the window it covers.
func _expect_covers(t: TestHarness, rig: Node, clip: String, window: float, message: String):
	var player = _animation_player(rig)
	if player == null or not player.has_animation(clip):
		t.expect_true(false, message)
		return
	var length = player.get_animation(clip).length
	t.expect_true(length >= window - SLACK, "%s (clip %.3f s, window %.3f s)" % [message, length, window])


## Load a rig from its glb.
func _load_rig(path: String):
	if not ResourceLoader.exists(path):
		return null
	var packed = load(path)
	if packed == null:
		return null
	var scene = packed.instantiate()
	# It needs a tree to be usable, but the test runner's scene is
	# already up: add it, read it, and take it out again.
	var tree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.current_scene == null:
		return scene
	tree.current_scene.add_child(scene)
	return scene


func _animation_player(rig: Node):
	if rig == null:
		return null
	for node in _descendants(rig):
		if node is AnimationPlayer:
			return node
	return null


func _bone_names(rig: Node) -> Array[String]:
	var out: Array[String] = []
	for node in _descendants(rig):
		if node is Skeleton3D:
			for bone in (node as Skeleton3D).get_bone_count():
				out.append((node as Skeleton3D).get_bone_name(bone))
	return out


func _triangle_count(rig: Node):
	var total = 0
	for node in _descendants(rig):
		if node is MeshInstance3D:
			var mesh = (node as MeshInstance3D).mesh
			if mesh != null:
				total += mesh.get_faces().size() / 3
	return total


func _descendants(node: Node):
	var out = [node]
	for child in node.get_children():
		out.append_array(_descendants(child))
	return out


## The character's data, for the numbers the clips have to cover.
func _character_data(character_id: StringName):
	var path = "res://src/data/characters/%s.tres" % character_id
	if not ResourceLoader.exists(path):
		return null
	return load(path) as CharacterData
