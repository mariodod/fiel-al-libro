@tool
extends MeshInstance3D
class_name TatteredSail
## A canvas sail with a genuinely ragged edge, built from a deterministic grid.
##
## The grey-box sails were three boxes of decreasing length: ragged only from
## a distance. This builds a real mesh with missing cells, chipped edges and
## holes that widen toward the tip, so the tatter holds up close as well.
##
## The mesh lies in the local YZ plane (length along +Y, width along Z) and is
## flat in X, matching the thin profile the four-arm sail rig expects. The
## pattern is deterministic from `seed_value`, so it survives scene reloads.

@export var length: float = 2.3
@export var width: float = 1.05
@export var seed_value: int = 1
@export_range(4, 24) var segments: int = 12
@export_range(2, 12) var columns: int = 6
@export_range(0.0, 1.0) var tatter: float = 0.78

func _ready() -> void:
	if mesh == null:
		mesh = build_mesh()

func _h(i: int, j: int, salt: int) -> float:
	var n := i * 374761393 + j * 668265263 + (seed_value + salt) * 2246822519
	n = (n ^ (n >> 13)) * 1274126177
	return float((n ^ (n >> 16)) & 0xFFFFFFFF) / 4294967295.0

func _edge(t: float) -> float:
	return abs(t - 0.5) * 2.0

func _vertex(i: int, j: int) -> Vector3:
	var t := float(i) / float(segments)
	var u := float(j) / float(columns)
	# Ragged jitter grows toward either tip of the blade.
	var e := _edge(t)
	var jx := (_h(i, j, 1) - 0.5) * 0.06 * (0.4 + e)
	var jz := (_h(i, j, 2) - 0.5) * width * 0.09 * (0.35 + e)
	var jy := (_h(i, j, 3) - 0.5) * length * 0.03
	return Vector3(jx, t * length + jy, (u - 0.5) * width + jz)

func _survives(i: int, j: int) -> bool:
	var e := _edge(float(i) / float(segments))
	var edge := j == 0 or j == columns - 1
	var chance := (1.0 - e * tatter) * (0.62 if edge else 1.0)
	return _h(i, j, 4) < chance

func build_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(segments):
		for j in range(columns):
			if not _survives(i, j):
				continue
			var a := _vertex(i, j)
			var b := _vertex(i + 1, j)
			var c := _vertex(i + 1, j + 1)
			var d := _vertex(i, j + 1)
			var uv_a := Vector2(float(j) / columns, float(i) / segments)
			var uv_b := Vector2(float(j) / columns, float(i + 1) / segments)
			var uv_c := Vector2(float(j + 1) / columns, float(i + 1) / segments)
			var uv_d := Vector2(float(j + 1) / columns, float(i) / segments)
			st.set_uv(uv_a); st.add_vertex(a)
			st.set_uv(uv_b); st.add_vertex(b)
			st.set_uv(uv_c); st.add_vertex(c)
			st.set_uv(uv_a); st.add_vertex(a)
			st.set_uv(uv_c); st.add_vertex(c)
			st.set_uv(uv_d); st.add_vertex(d)
	st.generate_normals()
	return st.commit()
