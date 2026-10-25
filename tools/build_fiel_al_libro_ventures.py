"""
build_fiel_al_libro_ventures.py

Headless Blender 5.x script for 'Fiel al Libro' (Godot 4.7 action RPG).
Builds the Venture of Montiel — the first boss — in its two forms:

  * The Mill  (Reality truth)  →  res://assets/models/venture_mill.glb
  * The Giant (Book truth)     →  res://assets/models/venture_giant.glb

Venture art second pass:
  * Tower gets a hand-painted masonry texture via triplanar-projected
    procedural stone, baked to vertex colour (docs/ANIMATION_BRIEF.md §2).
  * Sails get real tatter — ragged, torn canvas edges instead of plain boxes.

Each form is low-poly, flat, vertex-coloured, under 400 triangles, in the
game's one palette (docs/ANIMATION_BRIEF.md §2). No textures, no lighting
baked in — the truth-layer shader draws the ink outline.

Usage:
    .\tools\blender.ps1 -b --factory-startup -P tools\build_fiel_al_libro_ventures.py -- --out <dir>
"""

import sys
import os
import math
import random
import bpy
import bmesh
import mathutils
from mathutils import Vector, Quaternion, Euler, Matrix

FPS = 30
RANDOM_SEED = 42  # deterministic tatter and masonry


def set_scene_fps(fps=FPS):
    scene = bpy.context.scene
    scene.render.fps = fps
    scene.render.fps_base = 1.0
    return scene


# ---------------------------------------------------------------------------
# 1. PALETTE — the game's one palette (docs/ANIMATION_BRIEF.md §2)
# ---------------------------------------------------------------------------
OCHRE        = (0.753, 0.541, 0.243)   # #C08A3E
DARK_OCHRE   = (0.541, 0.353, 0.157)   # #8A5A28
BONE_WHITE   = (0.910, 0.863, 0.753)   # #E8DCC0
DIRTY_BONE   = (0.788, 0.722, 0.588)   # #C9B896
OLIVE        = (0.431, 0.451, 0.271)   # #6E7345
DARK_OLIVE   = (0.290, 0.306, 0.180)   # #4A4E2E
IRON_GREY    = (0.298, 0.290, 0.275)   # #4C4A46
BLACK_IRON   = (0.180, 0.173, 0.165)   # #2E2C2A
DRIED_BLOOD  = (0.478, 0.180, 0.133)   # #7A2E22
WOOD         = (0.420, 0.290, 0.173)   # #6B4A2C
STEEL        = (0.541, 0.549, 0.565)   # #8A8C90


def mat(colour, roughness=0.9, use_vertex_color=False):
    m = bpy.data.materials.new(name=f"mat_{colour[0]:.3f}_{colour[1]:.3f}_{colour[2]:.3f}")
    m.use_nodes = True
    m.node_tree.nodes.clear()
    m.node_tree.links.clear()
    out = m.node_tree.nodes.new('ShaderNodeOutputMaterial')
    out.location = (0, 0)
    diff = m.node_tree.nodes.new('ShaderNodeBsdfDiffuse')
    diff.location = (-200, 0)
    diff.inputs['Roughness'].default_value = roughness
    if use_vertex_color:
        vc = m.node_tree.nodes.new('ShaderNodeVertexColor')
        vc.location = (-400, 0)
        m.node_tree.links.new(vc.outputs['Color'], diff.inputs['Color'])
    else:
        diff.inputs['Color'].default_value = (*colour, 1.0)
    m.node_tree.links.new(diff.outputs['BSDF'], out.inputs['Surface'])
    return m


# ---------------------------------------------------------------------------
# 2. DETERMINISTIC NOISE
# ---------------------------------------------------------------------------
def stone_hash(x, y, z, seed=0):
    """Deterministic pseudo-random value in [0, 1) from coordinates."""
    n = int((x * 127.1 + y * 311.7 + z * 73.3 + float(seed)) * 1000)
    n = (n ^ (n >> 13)) * 16807
    n = (n ^ (n >> 13)) % 1000000
    return n / 1000000.0


def clamp_colour(colour):
    return tuple(minf(1.0, maxf(0.0, c)) for c in colour)


def minf(a, b):
    return a if a < b else b


def maxf(a, b):
    return a if a > b else b


# ---------------------------------------------------------------------------
# 3. GEOMETRY HELPERS
# ---------------------------------------------------------------------------
def new_mesh(name):
    m = bpy.data.meshes.new(name)
    o = bpy.data.objects.new(name, m)
    bpy.context.collection.objects.link(o)
    return o, m


def add_box_mesh(name, size, location, rotation=(0, 0, 0), material=None):
    import bmesh
    o, m = new_mesh(name)
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=2.0)
    bm.verts.ensure_lookup_table()
    for v in bm.verts:
        v.co.x *= size[0] / 2.0
        v.co.y *= size[1] / 2.0
        v.co.z *= size[2] / 2.0
    mat_rot = Matrix.Rotation(math.radians(rotation[0]), 4, 'X') @ \
              Matrix.Rotation(math.radians(rotation[1]), 4, 'Y') @ \
              Matrix.Rotation(math.radians(rotation[2]), 4, 'Z')
    for v in bm.verts:
        v.co = mat_rot @ v.co
    bm.to_mesh(m)
    bm.free()
    o.location = Vector(location)
    if material:
        o.data.materials.append(material)
    return o, m


def add_cyl_mesh(name, radius_top, radius_bottom, height, location,
                 rotation=(0, 0, 0), segments=8, material=None):
    import bpy
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=segments,
        radius=radius_bottom,
        depth=height,
        location=location,
        rotation=(math.radians(rotation[0]), math.radians(rotation[1]), math.radians(rotation[2])),
    )
    o = bpy.context.active_object
    o.name = name
    m = o.data

    if radius_top != radius_bottom:
        bm = bmesh.new()
        bm.from_mesh(m)
        bm.verts.ensure_lookup_table()
        for v in bm.verts:
            if abs(v.co.z - height / 2.0) < 0.01:
                v.co.x *= radius_top / radius_bottom
                v.co.y *= radius_top / radius_bottom
        bm.to_mesh(m)
        bm.free()

    if material:
        o.data.materials.append(material)
    return o, m


def add_sphere_mesh(name, radius, location, segments=10, rings=5, material=None):
    o, m = new_mesh(name)
    import bmesh
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=segments, v_segments=rings, radius=radius)
    bm.to_mesh(m)
    bm.free()
    o.location = Vector(location)
    if material:
        o.data.materials.append(material)
    return o, m


def vertex_colour(mesh, colour):
    if not mesh.vertex_colors:
        mesh.vertex_colors.new()
    col_layer = mesh.vertex_colors[0]
    c = (*colour, 1.0)
    for poly in mesh.polygons:
        for li in poly.loop_indices:
            col_layer.data[li].color = c


# ---------------------------------------------------------------------------
# 3b. MASONRY TOWER — hand-painted stone via triplanar projection, baked to
#     vertex colour. The tower is built from bmesh so every vertex carries
#     its own stone colour, creating a low-poly hand-painted masonry look.
# ---------------------------------------------------------------------------
def add_masonry_cylinder(name, radius_top, radius_bottom, height, location,
                         rotation=(0, 0, 0), segments=8, height_segments=6,
                         base_colour=OCHRE, mortar_colour=DARK_OCHRE, seed=0):
    """Build a cylinder with a hand-painted masonry pattern as vertex colours.

    Triplanar-projected stone: cylindrical unwrap around Y (angle + height)
    defines courses and stones; each stone gets a deterministic colour
    variation within the palette. Mortar lines run between courses and
    between stones around the circumference.

    Geometry is built in bmesh, converted to mesh, then vertex colours are
    set on the mesh directly — avoids BMVert lifetime issues in Blender 5.2.
    """
    import bmesh
    bm = bmesh.new()

    course_height = 0.8            # metres per stone course
    stone_angle = 0.85             # radians per stone around circumference
    mortar_width = 0.14            # fractional width of mortar lines

    # ── Build rings of vertices ────────────────────────────────────────
    n_rings = height_segments + 1
    n_verts = n_rings * segments
    ring_verts = []  # store vertex indices instead of references

    for ring in range(n_rings):
        y = -height / 2.0 + ring * (height / height_segments)
        radius = radius_bottom + (radius_top - radius_bottom) * (ring / height_segments)
        ring_v = []
        for seg in range(segments):
            angle = seg * (2.0 * math.pi / segments)
            x = radius * math.sin(angle)
            z = radius * math.cos(angle)
            ring_v.append(bm.verts.new((x, y, z)))
        ring_verts.append(ring_v)

    # ── Faces: side quads ──────────────────────────────────────────────
    for ring in range(n_rings - 1):
        for seg in range(segments):
            v1 = ring_verts[ring][seg]
            v2 = ring_verts[ring][(seg + 1) % segments]
            v3 = ring_verts[ring + 1][(seg + 1) % segments]
            v4 = ring_verts[ring + 1][seg]
            bm.faces.new((v1, v2, v3, v4))

    # ── Cap (top): fan ─────────────────────────────────────────────────
    if radius_top > 0.01:
        top_centre = bm.verts.new((0.0, height / 2.0, 0.0))
        for seg in range(segments):
            v1 = ring_verts[n_rings - 1][seg]
            v2 = ring_verts[n_rings - 1][(seg + 1) % segments]
            bm.faces.new((top_centre, v2, v1))
    else:
        # Pointed top: single apex
        apex = bm.verts.new((0.0, height / 2.0, 0.0))
        for seg in range(segments):
            v1 = ring_verts[n_rings - 1][seg]
            v2 = ring_verts[n_rings - 1][(seg + 1) % segments]
            bm.faces.new((apex, v1, v2))

    bm.normal_update()
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()

    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.location = Vector(location)
    obj.rotation_euler = Euler([math.radians(r) for r in rotation], 'XYZ')

    m = mat(base_colour, use_vertex_color=True)
    obj.data.materials.append(m)

    # ── Vertex colours: masonry pattern (set on mesh, not bmesh) ───────
    if not mesh.vertex_colors:
        mesh.vertex_colors.new()
    col_layer = mesh.vertex_colors[0]

    # Compute a colour per vertex index, then apply via polygon loops.
    vert_colour = {}
    for ring in range(n_rings):
        y = -height / 2.0 + ring * (height / height_segments)
        for seg in range(segments):
            vidx = ring * segments + seg
            angle = seg * (2.0 * math.pi / segments)
            angle_norm = (angle + 2.0 * math.pi) % (2.0 * math.pi)

            course = math.floor(y / course_height)
            stone = math.floor(angle_norm / stone_angle)

            # Mortar: between courses (vertical) and between stones (around)
            frac_y = (y / course_height) - course
            frac_a = (angle_norm / stone_angle) - stone
            in_mortar_y = frac_y < mortar_width or frac_y > 1.0 - mortar_width
            in_mortar_a = frac_a < mortar_width or frac_a > 1.0 - mortar_width

            if in_mortar_y or in_mortar_a:
                colour = mortar_colour
            else:
                # Stone body: deterministic variation within palette
                radius = radius_bottom + (radius_top - radius_bottom) * (ring / height_segments)
                x = radius * math.sin(angle)
                z = radius * math.cos(angle)
                h = stone_hash(x, y, z, seed)
                variation = 0.12 * (h - 0.5)
                colour = tuple(base_colour[i] * (1.0 + variation) for i in range(3))
                colour = clamp_colour(colour)

            vert_colour[vidx] = colour

    # Cap centre vertex gets mortar colour
    if radius_top > 0.01:
        vert_colour[n_verts] = mortar_colour

    # Apply via polygon loops
    for poly in mesh.polygons:
        for li in poly.loop_indices:
            vi = mesh.loops[li].vertex_index
            c = vert_colour.get(vi, base_colour)
            col_layer.data[li].color = (*c, 1.0)

    return obj, mesh


# ---------------------------------------------------------------------------
# 3c. TATTERED SAIL — ragged torn canvas edges instead of plain boxes
# ---------------------------------------------------------------------------
def add_tattered_sail(name, width, height, depth, location,
                      rotation=(0, 0, 0), material=None, seed=0):
    """Build a sail with ragged, torn edges.

    A grid of vertices (4 wide × 3 tall) with random displacement on the
    outer edge, plus a few missing edge faces to create canvas tears.
    """
    import bmesh
    bm = bmesh.new()

    cols = 4
    rows = 3
    rnd = random.Random(seed)

    # Grid of vertices
    grid = []
    for row in range(rows):
        row_v = []
        for col in range(cols):
            u = col / (cols - 1) - 0.5   # -0.5 to 0.5 across width
            v = row / (rows - 1) - 0.5   # -0.5 to 0.5 across height
            x = u * width
            y = v * height
            z = 0.0

            # Ragged displacement on outer edges only
            if col == 0 or col == cols - 1 or row == 0 or row == rows - 1:
                # Torn edge: push vertices off the perfect rectangle
                x += rnd.uniform(-0.08, 0.08) * width
                y += rnd.uniform(-0.08, 0.08) * height
                z += rnd.uniform(-0.04, 0.04) * depth

            row_v.append(bm.verts.new((x, y, z)))
        grid.append(row_v)

    # Faces: quads between grid points, with random edge tears
    for row in range(rows - 1):
        for col in range(cols - 1):
            # Randomly skip some edge faces to create canvas tears
            is_edge = (col == 0 or col == cols - 2 or row == 0 or row == rows - 2)
            if is_edge and rnd.random() < 0.25:
                continue  # torn hole in the canvas
            v1 = grid[row][col]
            v2 = grid[row][col + 1]
            v3 = grid[row + 1][col + 1]
            v4 = grid[row + 1][col]
            bm.faces.new((v1, v2, v3, v4))

    bm.normal_update()
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()

    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.location = Vector(location)
    obj.rotation_euler = Euler([math.radians(r) for r in rotation], 'XYZ')

    if material:
        obj.data.materials.append(material)
    return obj, mesh


# ---------------------------------------------------------------------------
# 4. BUILD THE MILL (Reality form)
# ---------------------------------------------------------------------------
def build_mill():
    objs = []

    # Tower: masonry stone with triplanar-projected pattern, baked to vertex colour
    o_tower, m_tower = add_masonry_cylinder(
        "Tower", radius_top=1.55, radius_bottom=1.95,
        height=8.0, location=(0, 0, 4.0),
        segments=8, height_segments=6,
        base_colour=OCHRE, mortar_colour=DARK_OCHRE, seed=RANDOM_SEED)
    objs.append(o_tower)

    # Cap: cone, dark tile
    o_cap, m_cap = add_cyl_mesh("Cap", radius_top=0.0, radius_bottom=2.4,
                                height=2.2, location=(0, 0, 9.1),
                                segments=8, material=mat(DARK_OCHRE))
    objs.append(o_cap)

    # Door: black, at base front
    o_door, m_door = add_box_mesh("Door", (1.0, 0.34, 1.95),
                                  (0.0, -1.72, 0.98), material=mat(BLACK_IRON))
    objs.append(o_door)

    # Lintel
    o_lintel, m_lintel = add_box_mesh("Lintel", (1.34, 0.44, 0.22),
                                      (0.0, -1.74, 2.05), material=mat(DARK_OLIVE))
    objs.append(o_lintel)

    # Sails: real tatter — ragged torn canvas edges, decreasing length
    sail_specs = [
        # (width, height, z_position, rotation_deg, seed_offset)
        (0.35, 2.3, 1.75, 0, 0),
        (0.35, 1.7, -0.15, 0, 1),
        (0.35, 1.1, -1.55, 0, 2),
        # Horizontal sails (rotated 90°)
        (2.3, 0.35, 1.75, 90, 3),
        (1.7, 0.35, -0.15, 90, 4),
        (1.1, 0.35, -1.55, 90, 5),
    ]

    for i, (w, h, z, rot, s_off) in enumerate(sail_specs):
        if rot == 0:
            # Vertical sail: hangs in Z plane
            o_sail, m_sail = add_tattered_sail(
                f"SailV{i}", w, h, 1.05, (0.0, z, 0.0),
                rotation=(0, 0, rot), material=mat(OCHRE), seed=RANDOM_SEED + s_off)
        else:
            # Horizontal sail: extends in Y, rotated to point along Z axis
            o_sail, m_sail = add_tattered_sail(
                f"SailH{i}", h, w, 1.05, (z, 0.0, 0.0),
                rotation=(0, 0, rot), material=mat(OCHRE), seed=RANDOM_SEED + s_off)
        objs.append(o_sail)
    o_hub, m_hub = add_sphere_mesh("Hub", 0.55, (0, 0, 7.4),
                                   segments=10, rings=5,
                                   material=mat(STEEL))
    objs.append(o_hub)

    return objs


# ---------------------------------------------------------------------------
# 5. BUILD THE GIANT (Book form)
# ---------------------------------------------------------------------------
def build_giant():
    objs = []

    # Legs - very thin, emaciated
    for side in [-1, 1]:
        o, m = add_box_mesh(f"Leg{side}", (0.5, 0.5, 2.2),
                            (side * 0.55, 3.2, 0), material=mat(OCHRE))
        objs.append(o)
        o, m = add_box_mesh(f"Shin{side}", (0.42, 0.42, 2.1),
                            (side * 0.52, 1.0, 0.06), material=mat(OCHRE))
        objs.append(o)
        o, m = add_box_mesh(f"Foot{side}", (0.55, 0.25, 1.15),
                            (side * 0.55, 0.15, -0.35), material=mat(OCHRE))
        objs.append(o)

    # Hips + belt
    o, m = add_box_mesh("Hips", (1.4, 0.9, 1.05), (0, 4.4, 0), material=mat(OCHRE))
    objs.append(o)
    o, m = add_box_mesh("Belt", (1.7, 0.5, 1.2), (0, 4.15, 0), material=mat(OLIVE))
    objs.append(o)

    # Torso + chest - very gaunt
    o, m = add_box_mesh("Torso", (1.5, 0.9, 2.1), (0, 5.9, 0), material=mat(OCHRE))
    objs.append(o)
    o, m = add_box_mesh("Chest", (1.8, 1.0, 1.1), (0, 6.9, -0.05), material=mat(OCHRE))
    objs.append(o)

    # Ribs - visible ribcage to show emaciation
    for i in range(4):
        rib_y = 6.3 + i * 0.35
        o_rib, m_rib = add_box_mesh(f"Rib{i}", (0.5, 0.08, 0.4),
                                    (0, rib_y, 0.15 + i * 0.2), material=mat(DARK_OLIVE))
        objs.append(o_rib)

    # Shoulders
    for side in [-1, 1]:
        o, m = add_box_mesh(f"Shoulder{side}", (0.65, 0.6, 0.68),
                            (side * 1.0, 7.15, 0), material=mat(OCHRE))
        objs.append(o)

        # Upper arm - very thin
        o, m = add_box_mesh(f"UpperArm{side}", (0.35, 0.35, 2.6),
                            (side * 1.25, 5.75, 0),
                            rotation=(0, 0, 90 if side > 0 else -90),
                            material=mat(OCHRE))
        objs.append(o)

        # Forearm
        o, m = add_box_mesh(f"Forearm{side}", (0.34, 0.34, 2.5),
                            (side * 1.18, 4.2, 0.05),
                            rotation=(0, 0, 90 if side > 0 else -90),
                            material=mat(OCHRE))
        objs.append(o)

        # Sail-hand - a strip of canvas instead of a hand
        o, m = add_box_mesh(f"SailHand{side}", (0.12, 2.2, 0.06),
                            (side * 1.32, 1.5, 0.05),
                            rotation=(0, 0, 90 if side > 0 else -90),
                            material=mat(OCHRE))
        objs.append(o)

        # Sail strip hanging down - torn canvas strip
        o, m = add_tattered_sail(f"SailStrip{side}", 0.07, 0.7, 0.08,
                                 (side * 0.68, -5.9, 0.1),
                                 rotation=(0, 0, 45 if side > 0 else -45),
                                 material=mat(DARK_OCHRE), seed=RANDOM_SEED + 10 + side)
        objs.append(o)

    # Neck + millstone head
    o, m = add_cyl_mesh("Neck", 0.25, 0.3, 0.5, (0, 7.72, 0),
                        material=mat(OCHRE))
    objs.append(o)

    o, m = add_cyl_mesh("Millstone", 1.0, 1.0, 0.5, (0, 8.35, -0.05),
                        rotation=(90, 0, 0), material=mat(IRON_GREY))
    objs.append(o)

    o, m = add_cyl_mesh("MillstoneHole", 0.24, 0.24, 0.56, (0, 8.35, -0.05),
                        rotation=(90, 0, 0), material=mat(BLACK_IRON))
    objs.append(o)

    return objs


# ---------------------------------------------------------------------------
# 6. MAIN
# ---------------------------------------------------------------------------
def main():
    out_dir = os.environ.get("FIEL_MODELS_OUT", "assets/models")
    os.makedirs(out_dir, exist_ok=True)

    set_scene_fps(FPS)

    # Clear scene
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)

    print("[Venture] Building the mill (Reality form)...")
    mill_objs = build_mill()
    mill_path = os.path.join(out_dir, "venture_mill.glb")
    bpy.ops.export_scene.gltf(filepath=mill_path, export_format='GLB',
                              use_selection=True)
    print(f"[Venture] Wrote {mill_path} ({len(mill_objs)} objects)")

    # Clear scene
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)

    print("[Venture] Building the giant (Book form)...")
    giant_objs = build_giant()
    giant_path = os.path.join(out_dir, "venture_giant.glb")
    bpy.ops.export_scene.gltf(filepath=giant_path, export_format='GLB',
                              use_selection=True)
    print(f"[Venture] Wrote {giant_path} ({len(giant_objs)} objects)")


if __name__ == "__main__":
    main()
