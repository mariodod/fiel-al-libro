"""
build_fiel_al_libro_ventures.py

Headless Blender 5.x script for 'Fiel al Libro' (Godot 4.7 action RPG).
Builds the Venture of Montiel — the first boss — in its two forms:

  * The Mill  (Reality truth)  →  res://assets/models/venture_mill.glb
  * The Giant (Book truth)     →  res://assets/models/venture_giant.glb

Each form is low-poly, flat, vertex-coloured, under 400 triangles, in the
game's one palette (docs/ANIMATION_BRIEF.md §2). No textures, no lighting
baked in — the truth-layer shader draws the ink outline.

Usage:
    .\tools\blender.ps1 -b --factory-startup -P tools\build_fiel_al_libro_ventures.py -- --out <dir>
"""

import sys
import os
import math
import bpy
import bmesh
import mathutils
from mathutils import Vector, Quaternion, Euler, Matrix

FPS = 30


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


def mat(colour, roughness=0.9):
    m = bpy.data.materials.new(name=f"mat_{colour[0]:.3f}_{colour[1]:.3f}_{colour[2]:.3f}")
    m.use_nodes = True
    m.node_tree.nodes.clear()
    m.node_tree.links.clear()
    out = m.node_tree.nodes.new('ShaderNodeOutputMaterial')
    out.location = (0, 0)
    diff = m.node_tree.nodes.new('ShaderNodeBsdfDiffuse')
    diff.location = (-200, 0)
    diff.inputs['Color'].default_value = (*colour, 1.0)
    diff.inputs['Roughness'].default_value = roughness
    m.node_tree.links.new(diff.outputs['BSDF'], out.inputs['Surface'])
    return m


# ---------------------------------------------------------------------------
# 2. GEOMETRY HELPERS
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

    # Taper top if needed
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
# 3. BUILD THE MILL (Reality form)
# ---------------------------------------------------------------------------
def build_mill():
    objs = []

    # Tower: 8-sided cylinder, ochre limestone, wider at foot
    o_tower, m_tower = add_cyl_mesh("Tower", radius_top=1.55, radius_bottom=1.95,
                                    height=8.0, location=(0, 0, 4.0),
                                    segments=8, material=mat(OCHRE))
    vertex_colour(m_tower, OCHRE)
    objs.append(o_tower)

    # Stone course bands - horizontal stripes around tower for masonry look
    for i in range(5):
        y = 1.0 + i * 1.6  # band positions
        o_course, m_course = add_cyl_mesh(f"Course{i}", radius_top=1.93, radius_bottom=1.91,
                                          height=0.25, location=(0, 0, y),
                                          segments=8, material=mat(DARK_OCHRE))
        vertex_colour(m_course, DARK_OCHRE)
        objs.append(o_course)

    # Cap: cone, dark tile
    o_cap, m_cap = add_cyl_mesh("Cap", radius_top=0.0, radius_bottom=2.4,
                                height=2.2, location=(0, 0, 9.1),
                                segments=8, material=mat(DARK_OCHRE))
    vertex_colour(m_cap, DARK_OCHRE)
    objs.append(o_cap)

    # Door: black, at base front
    o_door, m_door = add_box_mesh("Door", (1.0, 0.34, 1.95),
                                  (0.0, -1.72, 0.98), material=mat(BLACK_IRON))
    vertex_colour(m_door, BLACK_IRON)
    objs.append(o_door)

    # Lintel
    o_lintel, m_lintel = add_box_mesh("Lintel", (1.34, 0.44, 0.22),
                                      (0.0, -1.74, 2.05), material=mat(DARK_OLIVE))
    vertex_colour(m_lintel, DARK_OLIVE)
    objs.append(o_lintel)

    # Sails: three strips each, decreasing length, ragged ends
    sail_sizes = [(0.35, 2.3, 1.05), (0.35, 1.7, 1.05), (0.35, 1.1, 1.05)]
    sail_z = [1.75, -0.15, -1.55]

    for i, (sz, z) in enumerate(zip(sail_sizes, sail_z)):
        # Vertical sails
        o_sv, m_sv = add_box_mesh(f"SailV{i}", sz, (0.0, z, 0),
                                  material=mat(OCHRE))
        vertex_colour(m_sv, OCHRE)
        objs.append(o_sv)
        # Horizontal sails
        o_sh, m_sh = add_box_mesh(f"SailH{i}", (sz[1], sz[0], 1.05), (z, 0.0, 0),
                                  rotation=(0, 0, 90),
                                  material=mat(OCHRE))
        vertex_colour(m_sh, OCHRE)
        objs.append(o_sh)

    # Hub
    o_hub, m_hub = add_sphere_mesh("Hub", 0.55, (0, 0, 7.4),
                                   segments=10, rings=5,
                                   material=mat(STEEL))
    vertex_colour(m_hub, STEEL)
    objs.append(o_hub)

    return objs


# ---------------------------------------------------------------------------
# 4. BUILD THE GIANT (Book form)
# ---------------------------------------------------------------------------
def build_giant():
    objs = []

    # Legs - very thin, emaciated
    for side in [-1, 1]:
        o, m = add_box_mesh(f"Leg{side}", (0.5, 0.5, 2.2),
                            (side * 0.55, 3.2, 0), material=mat(OCHRE))
        vertex_colour(m, OCHRE)
        objs.append(o)
        o, m = add_box_mesh(f"Shin{side}", (0.42, 0.42, 2.1),
                            (side * 0.52, 1.0, 0.06), material=mat(OCHRE))
        vertex_colour(m, OCHRE)
        objs.append(o)
        o, m = add_box_mesh(f"Foot{side}", (0.55, 0.25, 1.15),
                            (side * 0.55, 0.15, -0.35), material=mat(OCHRE))
        vertex_colour(m, OCHRE)
        objs.append(o)

    # Hips + belt
    o, m = add_box_mesh("Hips", (1.4, 0.9, 1.05), (0, 4.4, 0), material=mat(OCHRE))
    vertex_colour(m, OCHRE)
    objs.append(o)
    o, m = add_box_mesh("Belt", (1.7, 0.5, 1.2), (0, 4.15, 0), material=mat(OLIVE))
    vertex_colour(m, OLIVE)
    objs.append(o)

    # Torso + chest - very gaunt
    o, m = add_box_mesh("Torso", (1.5, 0.9, 2.1), (0, 5.9, 0), material=mat(OCHRE))
    vertex_colour(m, OCHRE)
    objs.append(o)
    o, m = add_box_mesh("Chest", (1.8, 1.0, 1.1), (0, 6.9, -0.05), material=mat(OCHRE))
    vertex_colour(m, OCHRE)
    objs.append(o)

    # Ribs - visible ribcage to show emaciation
    for i in range(4):
        rib_y = 6.3 + i * 0.35
        o_rib, m_rib = add_box_mesh(f"Rib{side if False else i}", (0.5, 0.08, 0.4),
                                    (0, rib_y, 0.15 + i * 0.2), material=mat(DARK_OLIVE))
        vertex_colour(m_rib, DARK_OLIVE)
        objs.append(o_rib)

    # Shoulders
    for side in [-1, 1]:
        o, m = add_box_mesh(f"Shoulder{side}", (0.65, 0.6, 0.68),
                            (side * 1.0, 7.15, 0), material=mat(OCHRE))
        vertex_colour(m, OCHRE)
        objs.append(o)

        # Upper arm - very thin
        o, m = add_box_mesh(f"UpperArm{side}", (0.35, 0.35, 2.6),
                            (side * 1.25, 5.75, 0),
                            rotation=(0, 0, 90 if side > 0 else -90),
                            material=mat(OCHRE))
        vertex_colour(m, OCHRE)
        objs.append(o)

        # Forearm
        o, m = add_box_mesh(f"Forearm{side}", (0.34, 0.34, 2.5),
                            (side * 1.18, 4.2, 0.05),
                            rotation=(0, 0, 90 if side > 0 else -90),
                            material=mat(OCHRE))
        vertex_colour(m, OCHRE)
        objs.append(o)

        # Sail-hand - a strip of canvas instead of a hand
        o, m = add_box_mesh(f"SailHand{side}", (0.12, 2.2, 0.06),
                            (side * 1.32, 1.5, 0.05),
                            rotation=(0, 0, 90 if side > 0 else -90),
                            material=mat(OCHRE))
        vertex_colour(m, OCHRE)
        objs.append(o)

        # Sail strip hanging down
        o, m = add_box_mesh(f"SailStrip{side}", (0.07, 0.7, 0.08),
                            (side * 0.68, -5.9, 0.1),
                            rotation=(0, 0, 45 if side > 0 else -45),
                            material=mat(DARK_OCHRE))
        vertex_colour(m, DARK_OCHRE)
        objs.append(o)

    # Neck + millstone head
    o, m = add_cyl_mesh("Neck", 0.25, 0.3, 0.5, (0, 7.72, 0),
                        material=mat(OCHRE))
    vertex_colour(m, OCHRE)
    objs.append(o)

    o, m = add_cyl_mesh("Millstone", 1.0, 1.0, 0.5, (0, 8.35, -0.05),
                        rotation=(90, 0, 0), material=mat(IRON_GREY))
    vertex_colour(m, IRON_GREY)
    objs.append(o)

    o, m = add_cyl_mesh("MillstoneHole", 0.24, 0.24, 0.56, (0, 8.35, -0.05),
                        rotation=(90, 0, 0), material=mat(BLACK_IRON))
    vertex_colour(m, BLACK_IRON)
    objs.append(o)

    return objs


# ---------------------------------------------------------------------------
# 5. MAIN
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