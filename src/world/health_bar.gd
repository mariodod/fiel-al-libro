extends Node3D
## A bar over a thing's head: how much of it is left.
##
## The playtest: *"there is no feedback to how much hp the enemies have
## left, nor the main characters other than the debug numbers."* The
## debug numbers are the developer's readout and they are hidden with
## `H`, so a stranger had no way to know how close the thing was to
## dying. This is that feedback, and it is in the world, not in a menu.
##
## It is two quads: a dark ground and a fill that shrinks from the
## right. It turns to face the camera, because a bar you have to walk
## round to read is no use to anybody.

## The thing whose health this is. It needs `health` and `max_health`.
var target: Node = null
## How wide the bar is, in metres.
@export var width: float = 1.5
## How tall it is.
@export var height: float = 0.14
## How far above the thing's origin it floats.
@export var lift: float = 2.4
## The colour of the fill: the dried blood, a value above the palette's
## so that it reads against the ground.
@export var fill_color: Color = Color(0.62, 0.26, 0.19, 1.0)

var _fill: MeshInstance3D = null
var _background: MeshInstance3D = null


func _ready() -> void:
	_background = _make_quad(width, height, Color(0.12, 0.11, 0.1, 0.9))
	add_child(_background)
	_fill = _make_quad(width, height, fill_color)
	add_child(_fill)


## A flat quad that always faces the camera.
func _make_quad(w: float, h: float, color: Color) -> MeshInstance3D:
	var mesh := QuadMesh.new()
	mesh.size = Vector2(w, h)
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.no_depth_test = true
	material.render_priority = 4
	var quad := MeshInstance3D.new()
	quad.mesh = mesh
	quad.material_override = material
	quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return quad


func _process(_delta: float) -> void:
	_follow_target()
	_face_camera()
	_update_fill()


## The bar goes where the thing goes.
func _follow_target() -> void:
	if target == null or not is_instance_valid(target):
		return
	if target is Node3D:
		global_position = (target as Node3D).global_position + Vector3(0.0, lift, 0.0)


## Turn to face the camera, so the bar reads from every side.
func _face_camera() -> void:
	var camera := get_viewport().get_camera_3d() if get_viewport() != null else null
	if camera == null:
		return
	# A quad faces +Z, so the bar's +Z is turned towards the camera.
	# (look_at would point -Z at it, and the bar would be back-facing:
	# a bar nobody can see is the same as no bar at all.)
	var to_camera := camera.global_position - global_position
	to_camera.y = 0.0
	if to_camera.length_squared() < 0.0001:
		return
	rotation.y = atan2(to_camera.x, to_camera.z)


## The fill is the health, and it shrinks from the right.
func _update_fill() -> void:
	if _fill == null or target == null or not is_instance_valid(target):
		return
	var health := float(target.get("health")) if "health" in target else 0.0
	var maximum := float(target.get("max_health")) if "max_health" in target else 0.0
	var ratio := 0.0 if maximum <= 0.0 else clampf(health / maximum, 0.0, 1.0)
	_fill.scale.x = maxf(ratio, 0.0001)
	# Keep the fill's left edge still, so it empties towards the right.
	_fill.position.x = -width * 0.5 * (1.0 - ratio)


## Put the bar over a thing, and follow it.
func follow(node: Node, height_above: float = -1.0) -> void:
	target = node
	if height_above >= 0.0:
		lift = height_above
