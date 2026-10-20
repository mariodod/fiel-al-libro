extends RefCounted
## The lock-on: `M` picks a target, and the camera frames it.
##
## The plan wanted a lock-on and there was nothing to lock onto: 2.5
## wants "the lock-on target the dummy finally provides", and 2.6 wants
## a fight you can see. Both are the same thing.
##
## It is a SOFT lock: the target is the one you are looking at, the
## character turns towards it and walks around it, and the lock is given
## up when the target leaves the fight.

const SCENE := "res://src/world/slice.tscn"


func suite(t: TestHarness) -> void:
	t.suite("LockOn")

	var tree := Engine.get_main_loop() as SceneTree
	var parent: Node = tree.current_scene if tree != null and tree.current_scene != null else null
	var packed: PackedScene = load(SCENE)
	t.expect_true(packed != null, "slice.tscn should load")
	if packed == null or parent == null:
		return

	var scene: Node = packed.instantiate()
	parent.add_child(scene)

	var controller: PlayerController = scene.get_node_or_null("PlayerController")
	var quixote: CharacterPawn = scene.get_node_or_null("Characters/Quixote")
	var dummy: TrainingDummy = scene.get_node_or_null("Yard/TrainingDummy")
	var camera_rig: CameraFollow = scene.get_node_or_null("CameraRig")
	t.expect_true(controller != null and quixote != null, "the slice has a player and a character")
	t.expect_true(dummy != null, "the yard has a dummy in it")
	t.expect_true(camera_rig != null, "the slice has a camera")
	if controller == null or quixote == null or dummy == null or camera_rig == null:
		parent.remove_child(scene)
		scene.free()
		return

	# Put the character in front of the dummy, looking at it.
	quixote.global_position = dummy.global_position + Vector3(4.0, 0.0, 0.0)
	quixote.rotation.y = PI * 0.5

	# ── Choosing the target ────────────────────────────────────────────
	t.test("the target you are looking at is the one you lock onto")
	# The dummy is east of the character, and the character is looking
	# east.
	var found := LockOn.find_target(
		[dummy], quixote.global_position, -quixote.global_transform.basis.z)
	t.expect_eq(found, dummy, "the dummy is the target")

	t.test("a target behind you is not a target")
	var behind := Node3D.new()
	behind.add_to_group(LockOn.GROUP)
	parent.add_child(behind)
	# The character is looking west, at the dummy, so east is behind.
	behind.global_position = quixote.global_position + Vector3(4.0, 0.0, 0.0)
	t.expect_eq(LockOn.find_target([behind], quixote.global_position, -quixote.global_transform.basis.z), null,
		"nothing behind you is locked")

	t.test("a target too far away is not a target")
	var far := Node3D.new()
	far.add_to_group(LockOn.GROUP)
	parent.add_child(far)
	far.global_position = quixote.global_position + Vector3(40.0, 0.0, 0.0)
	t.expect_eq(LockOn.find_target([far], quixote.global_position, -quixote.global_transform.basis.z), null,
		"nothing out of reach is locked")

	# They were only ever there to be looked at. A target left in the
	# group is a target the player can lock onto, and the next test needs
	# there to be none.
	parent.remove_child(behind)
	behind.free()
	parent.remove_child(far)
	far.free()

	# ── Locking on ─────────────────────────────────────────────────────
	t.test("M locks the character onto the target")
	var press := InputEventAction.new()
	press.action = &"lock_on"
	press.pressed = true
	controller._unhandled_input(press)
	t.expect_true(quixote.is_locked(), "the character is locked on")
	t.expect_eq(quixote.lock_target, dummy, "and it is the dummy")

	t.test("M again lets go")
	controller._unhandled_input(press)
	t.expect_false(quixote.is_locked(), "the lock is released")

	t.test("a lock with nothing to lock is nothing")
	# Far from the yard, and facing away from it.
	quixote.global_position = Vector3(30.0, 0.0, 30.0)
	quixote.rotation.y = 0.0
	controller._unhandled_input(press)
	t.expect_false(quixote.is_locked(), "there is nothing to lock onto out here")

	# Back to the yard.
	quixote.global_position = dummy.global_position + Vector3(4.0, 0.0, 0.0)
	quixote.rotation.y = PI * 0.5
	controller._unhandled_input(press)
	t.expect_true(quixote.is_locked(), "locked on again")

	# ── The frame of the fight ─────────────────────────────────────────
	t.test("with a target locked, forward means towards the target")
	var forward: Vector2 = controller.call("_in_lock_frame", Vector2(0.0, 1.0))
	var to_target := dummy.global_position - quixote.global_position
	to_target.y = 0.0
	var wanted := Vector2(to_target.x, to_target.z).normalized()
	t.expect_gt(forward.dot(wanted), 0.99, "W closes the distance, got %s" % str(forward))

	t.test("and sideways means sideways")
	var right: Vector2 = controller.call("_in_lock_frame", Vector2(1.0, 0.0))
	t.expect_almost_eq(right.dot(wanted), 0.0, 0.01, "D walks around the target")

	# ── The camera ─────────────────────────────────────────────────────
	t.test("the camera frames the target as well as the character")
	camera_rig.lock_target = quixote.lock_target
	for i in 40:
		camera_rig.call("_process", 0.05)
	var camera_forward := -camera_rig.global_transform.basis.z
	var to_dummy := dummy.global_position - camera_rig.global_position
	var angle := rad_to_deg(camera_forward.angle_to(to_dummy.normalized()))
	t.expect_true(angle < 35.0, "the target is in the picture, got %.1f degrees" % angle)

	t.test("and it stands behind the character, between it and the fight")
	var camera_to_character := camera_rig.global_position - quixote.global_position
	var character_to_dummy := dummy.global_position - quixote.global_position
	camera_to_character.y = 0.0
	character_to_dummy.y = 0.0
	t.expect_true(camera_to_character.normalized().dot(character_to_dummy.normalized()) < 0.0,
		"the camera is on the far side of the character, away from the target")

	# ── Losing the lock ────────────────────────────────────────────────
	t.test("a target that goes down is not a target")
	dummy.take_damage(dummy.max_health * 2.0)
	t.expect_true(dummy.is_down(), "the dummy is down")
	controller.call("_update_lock", 0.1)
	t.expect_false(quixote.is_locked(), "the lock is given up")

	t.test("and the lock comes back when it stands up")
	dummy.reset()
	controller._unhandled_input(press)
	t.expect_true(quixote.is_locked(), "it can be locked on again")

	# ── Swapping ───────────────────────────────────────────────────────
	t.test("swapping characters drops the lock")
	controller.request_swap()
	t.expect_false(quixote.is_locked(), "the lock belonged to the character that took it")

	parent.remove_child(scene)
	scene.free()
