class_name LockOn
extends RefCounted
## The soft lock-on: `M` picks a target, and the character and the camera
## both keep it in view.
##
## GDD.md §7.1: *"Lock-on — Souls-like soft lock, with a 'Verdict'
## modifier."* The Verdict modifier is weeks away; the lock itself is
## what a target is finally for.
##
## It is **soft**: the target is the one you are LOOKING at, not the one
## that happens to be nearest, and it is given up when it dies or gets
## too far. A lock that grabs the closest enemy is a targeting system,
## not a camera — and the camera is the point, because a fight you
## cannot see is not a fight.
##
## The group of things that can be locked onto. A target that is out of
## the fight leaves the group, and the lock goes with it.
const GROUP := &"lockable"

## How far away a target can be and still be locked.
const MAX_DISTANCE := 16.0

## How far off your line of sight it can be and still be locked.
const MAX_ANGLE_DEGREES := 70.0


## The target you are looking at, or null.
##
## The one you are looking at most DIRECTLY wins, and distance only
## breaks ties — the same rule the Examine verb uses, and for the same
## reason: the player is looking at the big thing, not the small one
## that happens to be nearer.
static func find_target(candidates: Array, origin: Vector3, facing: Vector3) -> Node3D:
	var flat_facing := Vector3(facing.x, 0.0, facing.z)
	if flat_facing.length_squared() < 0.0001:
		return null
	flat_facing = flat_facing.normalized()

	var best: Node3D = null
	var best_angle := 0.0
	var best_distance := 0.0

	for node in candidates:
		var candidate := node as Node3D
		if candidate == null:
			continue
		var to_candidate := candidate.global_position - origin
		to_candidate.y = 0.0
		var distance := to_candidate.length()
		if distance > MAX_DISTANCE or distance < 0.001:
			continue
		var angle := rad_to_deg(flat_facing.angle_to(to_candidate / distance))
		if angle > MAX_ANGLE_DEGREES:
			continue
		if best == null or angle < best_angle - 3.0 or (absf(angle - best_angle) <= 3.0 and distance < best_distance):
			best = candidate
			best_angle = angle
			best_distance = distance

	return best


## Is this still a target? Alive, in the fight, and near enough.
static func is_valid(target: Node3D, origin: Vector3) -> bool:
	if target == null or not is_instance_valid(target):
		return false
	if not target.is_in_group(GROUP):
		return false
	var to_target := target.global_position - origin
	to_target.y = 0.0
	return to_target.length() <= MAX_DISTANCE * 1.5
