extends Node3D
## The windmill's sails turn.
##
## That is the whole point of a windmill, and it is the difference between
## "a box on a tower" and "a thing that is doing something". It also gives
## the eye a moving element to lock onto when the world flips, which is
## when you most need to know what you are looking at.

## Degrees per second. Slow: this is La Mancha, not a wind tunnel.
@export var degrees_per_second: float = 9.0


func _process(delta: float) -> void:
	# The axle points at the viewer, so the sails turn in the screen plane.
	rotate_z(deg_to_rad(degrees_per_second) * delta)
