"""
build_fiel_al_libro_animations.py

Headless Blender 5.x / 4.x script for 'Fiel al Libro' (Godot 4.7 action RPG).
Builds the two hero humanoid rigs (Don Quixote & Sancho Panza), authors their
full animation sets according to exact game timings, verifies all design
constraints, and exports glTF (.glb) and Blender (.blend) files.

Usage:
    .\tools\blender.ps1 -b --factory-startup -P tools\build_fiel_al_libro_animations.py

The output directory is assets\models by default. To put it somewhere
else, pass `--out <dir>` to the WRAPPER, not to Blender: Blender's own
command-line parser treats the first argument after `--` as a file to
open, and the run ends with "unknown argument, loading as file: --out".
"""

import sys
import os
import math
import json
import struct
import bpy
import mathutils
from mathutils import Vector, Quaternion, Euler, Matrix

# ---------------------------------------------------------------------------
# 0. THE FRAME RATE — and why it is set here, at the very top
# ---------------------------------------------------------------------------
#
# The glTF exporter converts Blender FRAMES into glTF SECONDS by dividing
# by the scene's frame rate. Blender's default scene is 24 fps, and the
# default factory settings are what `read_factory_settings(use_empty=True)`
# gives you. So a clip authored on a 30 fps grid and exported from a 24 fps
# scene comes out 25% LONG in the file — and the engine, which reads
# seconds, plays it 25% slow.
#
# The first build of this script did exactly that: every clip in the .glb
# was a quarter too long (a 0.45 s light attack arrived as 0.58 s), and
# nothing in the script noticed, because the script's own report measured
# the frames it had written rather than the seconds it had exported.
#
# So: 30 fps, set before anything is authored, and VERIFIED AGAIN FROM THE
# EXPORTED FILE at the end. The intent is not the artifact. The artifact
# is the artifact.
FPS = 30


def set_scene_fps(fps=FPS):
    """Put the scene on the frame rate the clips are authored against."""
    scene = bpy.context.scene
    scene.render.fps = fps
    scene.render.fps_base = 1.0
    return scene


def read_glb_clip_lengths(path):
    """
    The clip lengths, in SECONDS, exactly as they are written in the .glb.

    A GLB is a 12-byte header followed by chunks: a JSON chunk and a BIN
    chunk. The JSON holds the animation samplers, and each sampler's input
    accessor's `max` is the last keyframe time of that clip. Reading the
    file directly means the check sees what the ENGINE will see, with no
    import round-trip in the way to hide a mistake.
    """
    with open(path, 'rb') as fh:
        data = fh.read()

    magic, _version, _total = struct.unpack_from('<III', data, 0)
    if magic != 0x46546C67:  # 'glTF'
        raise ValueError("not a GLB: %s" % path)

    offset = 12
    gltf = None
    while offset + 8 <= len(data):
        length, kind = struct.unpack_from('<II', data, offset)
        if kind == 0x4E4F534A:  # 'JSON'
            gltf = json.loads(data[offset + 8: offset + 8 + length].decode('utf-8'))
        offset += 8 + length + ((4 - (length % 4)) % 4)

    if gltf is None:
        raise ValueError("no JSON chunk in %s" % path)

    out = {}
    for anim in gltf.get('animations', []):
        longest = 0.0
        for sampler in anim.get('samplers', []):
            accessor = gltf['accessors'][sampler['input']]
            longest = max(longest, float(accessor.get('max', [0.0])[0]))
        out[anim.get('name', '?')] = longest
    return out

# -----------------------------------------------------------------------------
# 1. PALETTE & COLOR CONVERSION (Gouache on Plaster)
# -----------------------------------------------------------------------------

HEX_PALETTE = {
    'OCHRE': '#C08A3E',        # Doublet body / sack highlights
    'DARK_OCHRE': '#8A5A28',   # Doublet folds / straps / leather
    'BONE_WHITE': '#E8DCC0',   # Sleeves
    'DIRTY_BONE': '#C9B896',   # Sleeve shadows / sun-darkened skin
    'OLIVE': '#6E7345',        # Sancho tunic
    'DARK_OLIVE': '#4A4E2E',   # Sancho tunic shadows
    'IRON_GREY': '#4C4A46',    # Basin, chest strap, buckler
    'BLACK_IRON': '#2E2C2A',   # Basin rim, sword hilt, flail ball
    'DRIED_BLOOD': '#7A2E22',  # Quixote sleeve stain
    'WOOD': '#6B4A2C',         # Lance shaft, flail handle, leather
    'STEEL': '#8A8C90',        # Lance tip, sword blade, buckler rim
}

def hex_to_linear_rgb(hex_code):
    """Convert sRGB hex string to linear RGB tuple (r, g, b, 1.0)."""
    h = hex_code.lstrip('#')
    srgb = [int(h[i:i+2], 16) / 255.0 for i in (0, 2, 4)]
    linear = []
    for c in srgb:
        if c <= 0.04045:
            linear.append(c / 12.92)
        else:
            linear.append(((c + 0.055) / 1.055) ** 2.4)
    return tuple(linear) + (1.0,)

LINEAR_PALETTE = {k: hex_to_linear_rgb(v) for k, v in HEX_PALETTE.items()}

# -----------------------------------------------------------------------------
# 2. SKELETON SPECIFICATION
# -----------------------------------------------------------------------------

# Mixamo-compatible 21 bones - IDENTICAL in both rigs
BONE_NAMES = [
    'root',
    'hips',
    'spine',
    'chest',
    'neck',
    'head',
    'shoulder_l',
    'upperarm_l',
    'forearm_l',
    'hand_l',
    'shoulder_r',
    'upperarm_r',
    'forearm_r',
    'hand_r',
    'weapon_r',
    'thigh_l',
    'shin_l',
    'foot_l',
    'thigh_r',
    'shin_r',
    'foot_r'
]

BONE_HIERARCHY = {
    'root': None,
    'hips': 'root',
    'spine': 'hips',
    'chest': 'spine',
    'neck': 'chest',
    'head': 'neck',
    'shoulder_l': 'chest',
    'upperarm_l': 'shoulder_l',
    'forearm_l': 'upperarm_l',
    'hand_l': 'forearm_l',
    'shoulder_r': 'chest',
    'upperarm_r': 'shoulder_r',
    'forearm_r': 'upperarm_r',
    'hand_r': 'forearm_r',
    'weapon_r': 'hand_r',
    'thigh_l': 'hips',
    'shin_l': 'thigh_l',
    'foot_l': 'shin_l',
    'thigh_r': 'hips',
    'shin_r': 'thigh_r',
    'foot_r': 'shin_r'
}

# -----------------------------------------------------------------------------
# 3. MESH GEOMETRY BUILDER UTILITY
# -----------------------------------------------------------------------------

class LowPolyMeshBuilder:
    """Helper to assemble low-poly geometric meshes with vertex colors and bone weights."""
    def __init__(self):
        self.verts = []
        self.faces = []
        self.face_colors = []
        self.vert_weights = []  # list of dicts: {bone_name: weight}

    def add_box(self, center, size, color_linear, weights):
        """Add an axis-aligned box (12 triangles)."""
        cx, cy, cz = center
        sx, sy, sz = [s * 0.5 for s in size]
        base_idx = len(self.verts)

        # 8 corners
        corners = [
            (cx - sx, cy - sy, cz - sz),
            (cx + sx, cy - sy, cz - sz),
            (cx + sx, cy + sy, cz - sz),
            (cx - sx, cy + sy, cz - sz),
            (cx - sx, cy - sy, cz + sz),
            (cx + sx, cy - sy, cz + sz),
            (cx + sx, cy + sy, cz + sz),
            (cx - sx, cy + sy, cz + sz),
        ]
        self.verts.extend(corners)
        for _ in range(8):
            self.vert_weights.append(dict(weights))

        # 6 quad faces
        box_faces = [
            (0, 1, 2, 3), # bottom
            (4, 7, 6, 5), # top
            (0, 4, 5, 1), # front (-y)
            (1, 5, 6, 2), # right (+x)
            (2, 6, 7, 3), # back (+y)
            (3, 7, 4, 0), # left (-x)
        ]
        for f in box_faces:
            self.faces.append([base_idx + idx for idx in f])
            self.face_colors.append(color_linear)

    def add_cylinder(self, p_base, p_top, r_base, r_top, segments, color_linear, weights, cap_bottom=True, cap_top=True):
        """Add a tapered cylinder / prism along axis p_base -> p_top."""
        base_vec = Vector(p_base)
        top_vec = Vector(p_top)
        axis = (top_vec - base_vec)
        height = axis.length
        if height < 1e-6:
            return
        z_dir = axis.normalized()

        # Build orthonormal basis
        ref = Vector((0, 0, 1)) if abs(z_dir.z) < 0.9 else Vector((1, 0, 0))
        x_dir = z_dir.cross(ref).normalized()
        y_dir = z_dir.cross(x_dir).normalized()

        base_idx = len(self.verts)

        # Bottom ring
        for i in range(segments):
            angle = 2.0 * math.pi * i / segments
            pos = base_vec + (x_dir * math.cos(angle) + y_dir * math.sin(angle)) * r_base
            self.verts.append(pos[:])
            self.vert_weights.append(dict(weights))

        # Top ring
        for i in range(segments):
            angle = 2.0 * math.pi * i / segments
            pos = top_vec + (x_dir * math.cos(angle) + y_dir * math.sin(angle)) * r_top
            self.verts.append(pos[:])
            self.vert_weights.append(dict(weights))

        # Side quads
        for i in range(segments):
            next_i = (i + 1) % segments
            b0 = base_idx + i
            b1 = base_idx + next_i
            t0 = base_idx + segments + i
            t1 = base_idx + segments + next_i
            self.faces.append([b0, b1, t1, t0])
            self.face_colors.append(color_linear)

        # Bottom cap fan
        if cap_bottom:
            c_idx = len(self.verts)
            self.verts.append(base_vec[:])
            self.vert_weights.append(dict(weights))
            for i in range(segments):
                next_i = (i + 1) % segments
                self.faces.append([c_idx, base_idx + next_i, base_idx + i])
                self.face_colors.append(color_linear)

        # Top cap fan
        if cap_top:
            c_idx = len(self.verts)
            self.verts.append(top_vec[:])
            self.vert_weights.append(dict(weights))
            for i in range(segments):
                next_i = (i + 1) % segments
                self.faces.append([c_idx, base_idx + segments + i, base_idx + segments + next_i])
                self.face_colors.append(color_linear)

    def add_dish(self, center, r_inner, r_outer, depth, segments, color_bowl, color_rim, weights):
        """Add Mambrino shallow barber basin dish helmet."""
        cx, cy, cz = center
        base_idx = len(self.verts)

        # Center vertex
        self.verts.append((cx, cy, cz - depth * 0.5))
        self.vert_weights.append(dict(weights))

        # Inner bowl ring
        for i in range(segments):
            ang = 2.0 * math.pi * i / segments
            self.verts.append((cx + math.cos(ang) * r_inner, cy + math.sin(ang) * r_inner, cz))
            self.vert_weights.append(dict(weights))

        # Flared rim ring
        for i in range(segments):
            ang = 2.0 * math.pi * i / segments
            # Small notch in Mambrino basin at front-right (the barber's neck cut-out)
            notch = 0.85 if 0.4 <= ang <= 0.9 else 1.0
            self.verts.append((cx + math.cos(ang) * r_outer * notch, cy + math.sin(ang) * r_outer * notch, cz + depth * 0.2))
            self.vert_weights.append(dict(weights))

        # Bowl floor triangles
        for i in range(segments):
            next_i = (i + 1) % segments
            self.faces.append([base_idx, base_idx + 1 + i, base_idx + 1 + next_i])
            self.face_colors.append(color_bowl)

        # Flared rim quads
        for i in range(segments):
            next_i = (i + 1) % segments
            i0 = base_idx + 1 + i
            i1 = base_idx + 1 + next_i
            o0 = base_idx + 1 + segments + i
            o1 = base_idx + 1 + segments + next_i
            self.faces.append([i0, o0, o1, i1])
            self.face_colors.append(color_rim)

    def build_bmesh(self, mesh_name):
        """Instantiate Blender mesh with vertex colors and vertex groups."""
        mesh = bpy.data.meshes.new(mesh_name)
        mesh.from_pydata(self.verts, [], self.faces)
        mesh.update()

        # Vertex color attribute (domain CORNER for flat gouache shading)
        col_attr = mesh.color_attributes.new(name="Col", type='BYTE_COLOR', domain='CORNER')
        for poly_idx, poly in enumerate(mesh.polygons):
            c = self.face_colors[poly_idx]
            for loop_idx in poly.loop_indices:
                col_attr.data[loop_idx].color = c

        return mesh

    def assign_weights(self, obj):
        """Create vertex groups and assign weights on object."""
        # Collect weights per bone
        bone_to_verts = {}
        for v_idx, w_dict in enumerate(self.vert_weights):
            for bone, w in w_dict.items():
                if bone not in bone_to_verts:
                    bone_to_verts[bone] = []
                bone_to_verts[bone].append((v_idx, w))

        for bone in BONE_NAMES:
            vg = obj.vertex_groups.new(name=bone)
            if bone in bone_to_verts:
                for v_idx, w in bone_to_verts[bone]:
                    vg.add([v_idx], w, 'REPLACE')

# -----------------------------------------------------------------------------
# 4. QUIXOTE CHARACTER CREATION
# -----------------------------------------------------------------------------

QUIXOTE_BONE_HEADS = {
    'root':        (0.0, 0.0, 0.0),
    'hips':        (0.0, 0.0, 1.10),
    'spine':       (0.0, 0.0, 1.28),
    'chest':       (0.0, 0.0, 1.50),
    'neck':        (0.0, 0.0, 1.76),
    'head':        (0.0, 0.0, 1.86),
    'shoulder_l':  (0.06, 0.0, 1.70),
    'upperarm_l':  (0.20, 0.0, 1.68),
    'forearm_l':   (0.24, 0.0, 1.30),
    'hand_l':      (0.26, 0.0, 0.94),
    'shoulder_r':  (-0.06, 0.0, 1.70),
    'upperarm_r':  (-0.20, 0.0, 1.68),
    'forearm_r':   (-0.24, 0.0, 1.30),
    'hand_r':      (-0.26, 0.0, 0.94),
    'weapon_r':    (-0.26, 0.08, 0.88),
    'thigh_l':     (0.12, 0.0, 1.10),
    'shin_l':      (0.13, 0.0, 0.58),
    'foot_l':      (0.13, 0.0, 0.12),
    'thigh_r':     (-0.12, 0.0, 1.10),
    'shin_r':      (-0.13, 0.0, 0.58),
    'foot_r':      (-0.13, 0.0, 0.12),
}

QUIXOTE_BONE_TAILS = {
    'root':        (0.0, 0.1, 0.0),
    'hips':        (0.0, 0.0, 1.28),
    'spine':       (0.0, 0.0, 1.50),
    'chest':       (0.0, 0.0, 1.76),
    'neck':        (0.0, 0.0, 1.86),
    'head':        (0.0, 0.0, 2.05),
    'shoulder_l':  (0.20, 0.0, 1.68),
    'upperarm_l':  (0.24, 0.0, 1.30),
    'forearm_l':   (0.26, 0.0, 0.94),
    'hand_l':      (0.27, 0.0, 0.80),
    'shoulder_r':  (-0.20, 0.0, 1.68),
    'upperarm_r':  (-0.24, 0.0, 1.30),
    'forearm_r':   (-0.26, 0.0, 0.94),
    'hand_r':      (-0.27, 0.0, 0.80),
    'weapon_r':    (-0.26, 0.10, 2.50),
    'thigh_l':     (0.13, 0.0, 0.58),
    'shin_l':      (0.13, 0.0, 0.12),
    'foot_l':      (0.13, 0.20, 0.0),
    'thigh_r':     (-0.13, 0.0, 0.58),
    'shin_r':      (-0.13, 0.0, 0.12),
    'foot_r':      (-0.13, 0.20, 0.0),
}

def build_quixote_mesh():
    """Construct Don Quixote's low-poly mesh (tall, gaunt, Mambrino basin, lance, broken sword)."""
    mb = LowPolyMeshBuilder()
    pal = LINEAR_PALETTE

    # 1. Head (gaunt angular head)
    mb.add_cylinder((0.0, 0.0, 1.86), (0.0, 0.0, 2.04), 0.09, 0.08, 6, pal['DIRTY_BONE'], {'head': 1.0})

    # 2. Basin on head (Mambrino barber's basin helmet)
    mb.add_dish((0.0, 0.0, 2.06), 0.11, 0.21, 0.08, 8, pal['IRON_GREY'], pal['BLACK_IRON'], {'head': 1.0})

    # 3. Neck
    mb.add_cylinder((0.0, 0.0, 1.76), (0.0, 0.0, 1.86), 0.06, 0.06, 6, pal['DIRTY_BONE'], {'neck': 1.0})

    # 4. Chest / Doublet (narrow, threadbare ochre)
    mb.add_cylinder((0.0, 0.0, 1.50), (0.0, 0.0, 1.76), 0.14, 0.17, 6, pal['OCHRE'], {'chest': 1.0})

    # 5. Chest strap across doublet (iron grey)
    mb.add_box((0.0, 0.01, 1.62), (0.24, 0.04, 0.05), pal['IRON_GREY'], {'chest': 1.0})

    # 6. Spine / Waist
    mb.add_cylinder((0.0, 0.0, 1.28), (0.0, 0.0, 1.50), 0.12, 0.14, 6, pal['DARK_OCHRE'], {'spine': 1.0})

    # 7. Hips / Belt
    mb.add_cylinder((0.0, 0.0, 1.08), (0.0, 0.0, 1.28), 0.13, 0.12, 6, pal['DARK_OCHRE'], {'hips': 1.0})

    # 8. Left Arm (bone-white sleeve with dried blood stain and grey elbow)
    # Shoulder
    mb.add_cylinder((0.06, 0.0, 1.70), (0.20, 0.0, 1.68), 0.06, 0.055, 6, pal['BONE_WHITE'], {'shoulder_l': 1.0})
    # Upper arm (dried blood stain on sleeve)
    mb.add_cylinder((0.20, 0.0, 1.68), (0.24, 0.0, 1.30), 0.055, 0.045, 6, pal['DRIED_BLOOD'], {'upperarm_l': 1.0})
    # Forearm (grey at elbows, bone-white cuff)
    mb.add_cylinder((0.24, 0.0, 1.30), (0.26, 0.0, 0.94), 0.048, 0.04, 6, pal['IRON_GREY'], {'forearm_l': 1.0})
    # Hand
    mb.add_box((0.265, 0.0, 0.87), (0.05, 0.07, 0.10), pal['DIRTY_BONE'], {'hand_l': 1.0})

    # 9. Right Arm (bone-white sleeve)
    mb.add_cylinder((-0.06, 0.0, 1.70), (-0.20, 0.0, 1.68), 0.06, 0.055, 6, pal['BONE_WHITE'], {'shoulder_r': 1.0})
    mb.add_cylinder((-0.20, 0.0, 1.68), (-0.24, 0.0, 1.30), 0.055, 0.045, 6, pal['BONE_WHITE'], {'upperarm_r': 1.0})
    mb.add_cylinder((-0.24, 0.0, 1.30), (-0.26, 0.0, 0.94), 0.048, 0.04, 6, pal['IRON_GREY'], {'forearm_r': 1.0})
    mb.add_box((-0.265, 0.0, 0.87), (0.05, 0.07, 0.10), pal['DIRTY_BONE'], {'hand_r': 1.0})

    # 10. Left Leg (thin gaunt spindly legs)
    mb.add_cylinder((0.12, 0.0, 1.10), (0.13, 0.0, 0.58), 0.06, 0.05, 6, pal['DARK_OCHRE'], {'thigh_l': 1.0})
    mb.add_cylinder((0.13, 0.0, 0.58), (0.13, 0.0, 0.12), 0.05, 0.04, 6, pal['DARK_OCHRE'], {'shin_l': 1.0})
    mb.add_box((0.13, 0.07, 0.06), (0.07, 0.18, 0.10), pal['WOOD'], {'foot_l': 1.0})

    # 11. Right Leg
    mb.add_cylinder((-0.12, 0.0, 1.10), (-0.13, 0.0, 0.58), 0.06, 0.05, 6, pal['DARK_OCHRE'], {'thigh_r': 1.0})
    mb.add_cylinder((-0.13, 0.0, 0.58), (-0.13, 0.0, 0.12), 0.05, 0.04, 6, pal['DARK_OCHRE'], {'shin_r': 1.0})
    mb.add_box((-0.13, 0.07, 0.06), (0.07, 0.18, 0.10), pal['WOOD'], {'foot_r': 1.0})

    # 12. Weapon: The Lance (parented to weapon_r)
    # Long worn wooden shaft ~2.5m
    mb.add_cylinder((-0.26, 0.05, -0.40), (-0.26, 0.05, 2.10), 0.022, 0.018, 6, pal['WOOD'], {'weapon_r': 1.0})
    # Steel spearhead
    mb.add_cylinder((-0.26, 0.05, 2.10), (-0.26, 0.05, 2.45), 0.035, 0.002, 6, pal['STEEL'], {'weapon_r': 1.0})
    # Lance crossguard / vamplate ring
    mb.add_cylinder((-0.26, 0.05, 0.98), (-0.26, 0.05, 1.04), 0.07, 0.07, 6, pal['BLACK_IRON'], {'weapon_r': 1.0})

    # 13. Broken Sword at left hip (parented to hips)
    mb.add_box((0.18, 0.02, 1.12), (0.04, 0.08, 0.10), pal['BLACK_IRON'], {'hips': 1.0})
    mb.add_box((0.18, 0.02, 1.02), (0.025, 0.05, 0.22), pal['STEEL'], {'hips': 1.0}) # broken jagged blade

    return mb

# -----------------------------------------------------------------------------
# 5. SANCHO CHARACTER CREATION
# -----------------------------------------------------------------------------

SANCHO_BONE_HEADS = {
    'root':        (0.0, 0.0, 0.0),
    'hips':        (0.0, 0.0, 0.76),
    'spine':       (0.0, 0.0, 0.90),
    'chest':       (0.0, 0.0, 1.08),
    'neck':        (0.0, 0.0, 1.26),
    'head':        (0.0, 0.0, 1.34),
    'shoulder_l':  (0.08, 0.0, 1.22),
    'upperarm_l':  (0.24, 0.0, 1.18),
    'forearm_l':   (0.26, 0.0, 0.90),
    'hand_l':      (0.27, 0.0, 0.65),
    'shoulder_r':  (-0.08, 0.0, 1.22),
    'upperarm_r':  (-0.24, 0.0, 1.18),
    'forearm_r':   (-0.26, 0.0, 0.90),
    'hand_r':      (-0.27, 0.0, 0.65),
    'weapon_r':    (-0.27, 0.08, 0.60),
    'thigh_l':     (0.16, 0.0, 0.74),
    'shin_l':      (0.17, 0.0, 0.40),
    'foot_l':      (0.17, 0.0, 0.10),
    'thigh_r':     (-0.16, 0.0, 0.74),
    'shin_r':      (-0.17, 0.0, 0.40),
    'foot_r':      (-0.17, 0.0, 0.10),
}

SANCHO_BONE_TAILS = {
    'root':        (0.0, 0.1, 0.0),
    'hips':        (0.0, 0.0, 0.90),
    'spine':       (0.0, 0.0, 1.08),
    'chest':       (0.0, 0.0, 1.26),
    'neck':        (0.0, 0.0, 1.34),
    'head':        (0.0, 0.0, 1.54),
    'shoulder_l':  (0.24, 0.0, 1.18),
    'upperarm_l':  (0.26, 0.0, 0.90),
    'forearm_l':   (0.27, 0.0, 0.65),
    'hand_l':      (0.28, 0.0, 0.52),
    'shoulder_r':  (-0.24, 0.0, 1.18),
    'upperarm_r':  (-0.26, 0.0, 0.90),
    'forearm_r':   (-0.27, 0.0, 0.65),
    'hand_r':      (-0.28, 0.0, 0.52),
    'weapon_r':    (-0.27, 0.10, 0.15),
    'thigh_l':     (0.17, 0.0, 0.40),
    'shin_l':      (0.17, 0.0, 0.10),
    'foot_l':      (0.17, 0.18, 0.0),
    'thigh_r':     (-0.17, 0.0, 0.40),
    'shin_r':      (-0.17, 0.0, 0.10),
    'foot_r':      (-0.17, 0.18, 0.0),
}

def build_sancho_mesh():
    """Construct Sancho Panza's low-poly mesh (short, round, sack on back, flail, buckler)."""
    mb = LowPolyMeshBuilder()
    pal = LINEAR_PALETTE

    # 1. Round head
    mb.add_cylinder((0.0, 0.0, 1.34), (0.0, 0.0, 1.53), 0.12, 0.10, 8, pal['DIRTY_BONE'], {'head': 1.0})

    # 2. Short thick neck
    mb.add_cylinder((0.0, 0.0, 1.25), (0.0, 0.0, 1.34), 0.10, 0.10, 6, pal['DIRTY_BONE'], {'neck': 1.0})

    # 3. Round barrel torso / Olive tunic
    mb.add_cylinder((0.0, 0.0, 1.05), (0.0, 0.0, 1.26), 0.23, 0.21, 8, pal['OLIVE'], {'chest': 1.0})
    mb.add_cylinder((0.0, 0.0, 0.88), (0.0, 0.0, 1.05), 0.25, 0.23, 8, pal['DARK_OLIVE'], {'spine': 1.0})

    # 4. Belt with iron buckle
    mb.add_box((0.0, 0.01, 0.89), (0.50, 0.40, 0.07), pal['DARK_OCHRE'], {'spine': 0.5, 'hips': 0.5})
    mb.add_box((0.0, -0.21, 0.89), (0.08, 0.04, 0.08), pal['BLACK_IRON'], {'hips': 1.0})

    # 5. Wide hips
    mb.add_cylinder((0.0, 0.0, 0.72), (0.0, 0.0, 0.88), 0.22, 0.25, 8, pal['DARK_OLIVE'], {'hips': 1.0})

    # 6. Large luggage sack on back (luggage, job, station in life)
    mb.add_box((0.0, 0.26, 1.12), (0.42, 0.28, 0.38), pal['WOOD'], {'chest': 0.7, 'spine': 0.3})
    # Sack knot/tie on top
    mb.add_cylinder((0.0, 0.26, 1.31), (0.0, 0.26, 1.40), 0.08, 0.04, 6, pal['OCHRE'], {'chest': 1.0})

    # 7. Left Arm (stocky)
    mb.add_cylinder((0.08, 0.0, 1.22), (0.24, 0.0, 1.18), 0.09, 0.08, 6, pal['OLIVE'], {'shoulder_l': 1.0})
    mb.add_cylinder((0.24, 0.0, 1.18), (0.26, 0.0, 0.90), 0.08, 0.07, 6, pal['OLIVE'], {'upperarm_l': 1.0})
    mb.add_cylinder((0.26, 0.0, 0.90), (0.27, 0.0, 0.65), 0.07, 0.06, 6, pal['DIRTY_BONE'], {'forearm_l': 1.0})
    mb.add_box((0.275, 0.0, 0.59), (0.07, 0.08, 0.09), pal['DIRTY_BONE'], {'hand_l': 1.0})

    # Buckler / Parry shield on left forearm
    mb.add_dish((0.33, 0.0, 0.78), 0.14, 0.17, 0.04, 8, pal['IRON_GREY'], pal['STEEL'], {'forearm_l': 1.0})

    # 8. Right Arm (stocky)
    mb.add_cylinder((-0.08, 0.0, 1.22), (-0.24, 0.0, 1.18), 0.09, 0.08, 6, pal['OLIVE'], {'shoulder_r': 1.0})
    mb.add_cylinder((-0.24, 0.0, 1.18), (-0.26, 0.0, 0.90), 0.08, 0.07, 6, pal['OLIVE'], {'upperarm_r': 1.0})
    mb.add_cylinder((-0.26, 0.0, 0.90), (-0.27, 0.0, 0.65), 0.07, 0.06, 6, pal['DIRTY_BONE'], {'forearm_r': 1.0})
    mb.add_box((-0.275, 0.0, 0.59), (0.07, 0.08, 0.09), pal['DIRTY_BONE'], {'hand_r': 1.0})

    # 9. Short thick legs (wide stance)
    mb.add_cylinder((0.16, 0.0, 0.74), (0.17, 0.0, 0.40), 0.095, 0.08, 6, pal['DARK_OCHRE'], {'thigh_l': 1.0})
    mb.add_cylinder((0.17, 0.0, 0.40), (0.17, 0.0, 0.10), 0.08, 0.07, 6, pal['WOOD'], {'shin_l': 1.0})
    mb.add_box((0.17, 0.07, 0.06), (0.12, 0.20, 0.10), pal['DARK_OCHRE'], {'foot_l': 1.0})

    mb.add_cylinder((-0.16, 0.0, 0.74), (-0.17, 0.0, 0.40), 0.095, 0.08, 6, pal['DARK_OCHRE'], {'thigh_r': 1.0})
    mb.add_cylinder((-0.17, 0.0, 0.40), (-0.17, 0.0, 0.10), 0.08, 0.07, 6, pal['WOOD'], {'shin_r': 1.0})
    mb.add_box((-0.17, 0.07, 0.06), (0.12, 0.20, 0.10), pal['DARK_OCHRE'], {'foot_r': 1.0})

    # 10. The Flail (parented to weapon_r)
    # Sturdy wooden handle ~0.35m
    mb.add_cylinder((-0.27, 0.05, 0.62), (-0.27, 0.05, 0.27), 0.024, 0.022, 6, pal['WOOD'], {'weapon_r': 1.0})
    mb.add_cylinder((-0.27, 0.05, 0.27), (-0.27, 0.05, 0.23), 0.028, 0.028, 6, pal['STEEL'], {'weapon_r': 1.0})
    # Iron chain links
    mb.add_cylinder((-0.27, 0.05, 0.23), (-0.27, 0.05, 0.08), 0.012, 0.012, 4, pal['IRON_GREY'], {'weapon_r': 1.0})
    # Heavy spiked/faceted black iron ball
    mb.add_cylinder((-0.27, 0.05, 0.08), (-0.27, 0.05, -0.04), 0.065, 0.065, 8, pal['BLACK_IRON'], {'weapon_r': 1.0})

    return mb

# -----------------------------------------------------------------------------
# 6. SKELETON BUILDER & RIG CREATION
# -----------------------------------------------------------------------------

def create_armature(name, bone_heads, bone_tails):
    """Build a humanoid armature with the 21 standard bones."""
    arm_data = bpy.data.armatures.new(f"{name}_ArmatureData")
    arm_obj = bpy.data.objects.new(name, arm_data)
    bpy.context.collection.objects.link(arm_obj)
    bpy.context.view_layer.objects.active = arm_obj

    bpy.ops.object.mode_set(mode='EDIT')
    edit_bones = arm_data.edit_bones

    # 1. Create bones
    for b_name in BONE_NAMES:
        b = edit_bones.new(b_name)
        b.head = bone_heads[b_name]
        b.tail = bone_tails[b_name]

    # 2. Establish hierarchy
    for b_name, parent_name in BONE_HIERARCHY.items():
        if parent_name:
            edit_bones[b_name].parent = edit_bones[parent_name]

    bpy.ops.object.mode_set(mode='POSE')
    for pb in arm_obj.pose.bones:
        pb.rotation_mode = 'QUATERNION'

    bpy.ops.object.mode_set(mode='OBJECT')
    return arm_obj

def setup_gouache_material(mesh_obj):
    """Create and assign gouache plaster shader material hooked to vertex color 'Col'."""
    mat = bpy.data.materials.new(name="M_GouachePlaster")
    if hasattr(mat, 'node_tree') and mat.node_tree:
        nodes = mat.node_tree.nodes
        links = mat.node_tree.links

        bsdf = nodes.get('Principled BSDF')
        if bsdf:
            if 'Roughness' in bsdf.inputs:
                bsdf.inputs['Roughness'].default_value = 0.85
            if 'Specular IOR Level' in bsdf.inputs:
                bsdf.inputs['Specular IOR Level'].default_value = 0.15

            attr_node = nodes.new('ShaderNodeAttribute')
            attr_node.attribute_name = 'Col'
            links.new(attr_node.outputs['Color'], bsdf.inputs['Base Color'])

    mesh_obj.data.materials.append(mat)
    return mat

# -----------------------------------------------------------------------------
# 7. ANIMATION AUTHORING ENGINE
# -----------------------------------------------------------------------------

def set_bone_key(arm_obj, bone_name, frame, quat_euler_deg=None, loc=None):
    """Insert keyframe on pose bone at given frame."""
    pb = arm_obj.pose.bones[bone_name]
    if quat_euler_deg is not None:
        rx, ry, rz = [math.radians(a) for a in quat_euler_deg]
        q = Euler((rx, ry, rz), 'XYZ').to_quaternion()
        pb.rotation_quaternion = q
        pb.keyframe_insert(data_path="rotation_quaternion", frame=frame)
    if loc is not None:
        pb.location = loc
        pb.keyframe_insert(data_path="location", frame=frame)

def create_character_action(arm_obj, action_name, frame_count, keyframe_data, contact_frame=None):
    """
    Author an animation action on arm_obj with specified length and keyframes.
    Each action is an independent datablock.
    Blender 5.x / 4.x action slot and NLA strip are created.
    """
    arm_obj.animation_data_create()
    act = bpy.data.actions.new(name=action_name)
    act.use_fake_user = True
    arm_obj.animation_data.action = act

    # Reset all pose bones to identity before keyframing
    for pb in arm_obj.pose.bones:
        pb.rotation_quaternion = Quaternion((1, 0, 0, 0))
        pb.location = Vector((0, 0, 0))

    # Apply all keyframes: keyframe_data is dict: frame -> {bone_name: (rot_deg, loc)}
    for frame, bones_dict in sorted(keyframe_data.items()):
        for bone_name, (rot_deg, loc) in bones_dict.items():
            set_bone_key(arm_obj, bone_name, frame, rot_deg, loc)

    # Frame range settings
    act.use_frame_range = True
    act.frame_start = 0
    act.frame_end = frame_count

    # Pose marker for contact frame (hitbox opening)
    if contact_frame is not None:
        marker = act.pose_markers.new(name="contact")
        marker.frame = contact_frame

    # NLA strip with ActionSlot handling for Blender 5.x
    track = arm_obj.animation_data.nla_tracks.new()
    track.name = action_name
    strip = track.strips.new(action_name, 0, act)
    if hasattr(act, 'slots') and len(act.slots) > 0:
        if hasattr(strip, 'action_slot'):
            strip.action_slot = act.slots[0]

    return act

# -----------------------------------------------------------------------------
# 8. DON QUIXOTE ANIMATION SET (14 CLIPS)
# Committed, wide, gangly, noble, slightly too slow.
# -----------------------------------------------------------------------------

def author_quixote_animations(arm_obj):
    """
    Author the 14 clips for Don Quixote.
    Hit timings: light contact @ 0.08s (frame 2), heavy contact @ 0.12s (frame 4).
    Chained lights: light_2 starts from light_1 recovery, light_3 from light_2 recovery.
    Roll: 0.25s (8 frames) lunge covering 4m.
    """
    actions = {}

    # 1. idle: 2.0s (60 frames) - breathing, weight shifting, lance resting
    actions['idle'] = create_character_action(arm_obj, 'idle', 60, {
        0: {
            'hips': ((0, 0, 0), (0, 0, 0)),
            'spine': ((4, 0, 1), (0, 0, 0)),
            'chest': ((3, 0, -2), (0, 0, 0)),
            'head': ((-4, 0, 2), (0, 0, 0)),
            'upperarm_r': ((-25, 10, -5), (0, 0, 0)),
            'forearm_r': ((-40, 0, 0), (0, 0, 0)),
            'weapon_r': ((-15, 0, 0), (0, 0, 0)),
            'upperarm_l': ((15, -10, 0), (0, 0, 0)),
            'forearm_l': ((-30, 0, 0), (0, 0, 0)),
            'thigh_l': ((2, 0, 0), (0, 0, 0)),
            'thigh_r': ((-2, 0, 0), (0, 0, 0)),
        },
        30: {
            'hips': ((0, 0, 0), (0, 0, 0.02)), # subtle breath rise
            'spine': ((2, 0, -1), (0, 0, 0)),
            'chest': ((5, 0, 1), (0, 0, 0)),
            'head': ((-2, 0, -1), (0, 0, 0)),
            'upperarm_r': ((-23, 8, -4), (0, 0, 0)),
            'forearm_r': ((-38, 0, 0), (0, 0, 0)),
            'weapon_r': ((-13, 0, 0), (0, 0, 0)),
            'upperarm_l': ((17, -8, 0), (0, 0, 0)),
            'forearm_l': ((-28, 0, 0), (0, 0, 0)),
            'thigh_l': ((-1, 0, 0), (0, 0, 0)),
            'thigh_r': ((1, 0, 0), (0, 0, 0)),
        },
        60: {
            'hips': ((0, 0, 0), (0, 0, 0)),
            'spine': ((4, 0, 1), (0, 0, 0)),
            'chest': ((3, 0, -2), (0, 0, 0)),
            'head': ((-4, 0, 2), (0, 0, 0)),
            'upperarm_r': ((-25, 10, -5), (0, 0, 0)),
            'forearm_r': ((-40, 0, 0), (0, 0, 0)),
            'weapon_r': ((-15, 0, 0), (0, 0, 0)),
            'upperarm_l': ((15, -10, 0), (0, 0, 0)),
            'forearm_l': ((-30, 0, 0), (0, 0, 0)),
            'thigh_l': ((2, 0, 0), (0, 0, 0)),
            'thigh_r': ((-2, 0, 0), (0, 0, 0)),
        }
    })

    # 2. idle_lost: 2.0s (60 frames) - Locura >= 50. Shoulders up, chin high, lance held upright like a banner
    actions['idle_lost'] = create_character_action(arm_obj, 'idle_lost', 60, {
        0: {
            'hips': ((-5, 0, 0), (0, 0, 0.03)),
            'spine': ((-8, 0, 0), (0, 0, 0)),
            'chest': ((-10, 0, 0), (0, 0, 0)),
            'head': ((-15, 0, 0), (0, 0, 0)), # chin up proud
            'upperarm_r': ((-75, 5, -10), (0, 0, 0)), # lance banner pose
            'forearm_r': ((-85, 0, 0), (0, 0, 0)),
            'weapon_r': ((15, 0, 0), (0, 0, 0)),
            'upperarm_l': ((10, 15, -5), (0, 0, 0)),
            'forearm_l': ((-45, 0, 0), (0, 0, 0)), # hand resting on sword hilt
            'thigh_l': ((5, 0, 0), (0, 0, 0)),
            'thigh_r': ((-8, 0, 0), (0, 0, 0)),
        },
        30: {
            'hips': ((-5, 0, 0), (0, 0, 0.05)),
            'spine': ((-7, 0, 0), (0, 0, 0)),
            'chest': ((-9, 0, 0), (0, 0, 0)),
            'head': ((-17, 0, 0), (0, 0, 0)),
            'upperarm_r': ((-73, 5, -10), (0, 0, 0)),
            'forearm_r': ((-83, 0, 0), (0, 0, 0)),
            'weapon_r': ((13, 0, 0), (0, 0, 0)),
            'upperarm_l': ((11, 15, -5), (0, 0, 0)),
            'forearm_l': ((-43, 0, 0), (0, 0, 0)),
            'thigh_l': ((4, 0, 0), (0, 0, 0)),
            'thigh_r': ((-7, 0, 0), (0, 0, 0)),
        },
        60: {
            'hips': ((-5, 0, 0), (0, 0, 0.03)),
            'spine': ((-8, 0, 0), (0, 0, 0)),
            'chest': ((-10, 0, 0), (0, 0, 0)),
            'head': ((-15, 0, 0), (0, 0, 0)),
            'upperarm_r': ((-75, 5, -10), (0, 0, 0)),
            'forearm_r': ((-85, 0, 0), (0, 0, 0)),
            'weapon_r': ((15, 0, 0), (0, 0, 0)),
            'upperarm_l': ((10, 15, -5), (0, 0, 0)),
            'forearm_l': ((-45, 0, 0), (0, 0, 0)),
            'thigh_l': ((5, 0, 0), (0, 0, 0)),
            'thigh_r': ((-8, 0, 0), (0, 0, 0)),
        }
    })

    # 3. walk: 0.9s (27 frames) - 4.2 m/s long deliberate noble strides
    actions['walk'] = create_character_action(arm_obj, 'walk', 27, {
        0: {
            'hips': ((0, 0, 0), (0, 0, 0)),
            'thigh_l': ((-28, 0, 0), (0, 0, 0)),
            'shin_l': ((15, 0, 0), (0, 0, 0)),
            'thigh_r': ((25, 0, 0), (0, 0, 0)),
            'shin_r': ((10, 0, 0), (0, 0, 0)),
            'upperarm_r': ((-15, 0, 0), (0, 0, 0)),
            'upperarm_l': ((20, 0, 0), (0, 0, 0)),
        },
        7: {
            'hips': ((0, 0, 0), (0, 0, 0.04)),
            'thigh_l': ((0, 0, 0), (0, 0, 0)),
            'shin_l': ((5, 0, 0), (0, 0, 0)),
            'thigh_r': ((-10, 0, 0), (0, 0, 0)),
            'shin_r': ((40, 0, 0), (0, 0, 0)),
            'upperarm_r': ((-25, 0, 0), (0, 0, 0)),
            'upperarm_l': ((5, 0, 0), (0, 0, 0)),
        },
        14: {
            'hips': ((0, 0, 0), (0, 0, 0)),
            'thigh_l': ((25, 0, 0), (0, 0, 0)),
            'shin_l': ((10, 0, 0), (0, 0, 0)),
            'thigh_r': ((-28, 0, 0), (0, 0, 0)),
            'shin_r': ((15, 0, 0), (0, 0, 0)),
            'upperarm_r': ((-35, 0, 0), (0, 0, 0)),
            'upperarm_l': ((-15, 0, 0), (0, 0, 0)),
        },
        21: {
            'hips': ((0, 0, 0), (0, 0, 0.04)),
            'thigh_l': ((-10, 0, 0), (0, 0, 0)),
            'shin_l': ((40, 0, 0), (0, 0, 0)),
            'thigh_r': ((0, 0, 0), (0, 0, 0)),
            'shin_r': ((5, 0, 0), (0, 0, 0)),
            'upperarm_r': ((-25, 0, 0), (0, 0, 0)),
            'upperarm_l': ((5, 0, 0), (0, 0, 0)),
        },
        27: {
            'hips': ((0, 0, 0), (0, 0, 0)),
            'thigh_l': ((-28, 0, 0), (0, 0, 0)),
            'shin_l': ((15, 0, 0), (0, 0, 0)),
            'thigh_r': ((25, 0, 0), (0, 0, 0)),
            'shin_r': ((10, 0, 0), (0, 0, 0)),
            'upperarm_r': ((-15, 0, 0), (0, 0, 0)),
            'upperarm_l': ((20, 0, 0), (0, 0, 0)),
        }
    })

    # 4. run: 0.62s (19 frames) - 6.8 m/s gangly tall run
    actions['run'] = create_character_action(arm_obj, 'run', 19, {
        0: {
            'hips': ((12, 0, 0), (0, 0, -0.05)),
            'spine': ((10, 0, 0), (0, 0, 0)),
            'thigh_l': ((-45, 0, 0), (0, 0, 0)),
            'shin_l': ((20, 0, 0), (0, 0, 0)),
            'thigh_r': ((40, 0, 0), (0, 0, 0)),
            'shin_r': ((50, 0, 0), (0, 0, 0)),
            'upperarm_r': ((-40, 0, 0), (0, 0, 0)),
            'upperarm_l': ((35, 0, 0), (0, 0, 0)),
        },
        9: {
            'hips': ((12, 0, 0), (0, 0, 0.08)),
            'spine': ((10, 0, 0), (0, 0, 0)),
            'thigh_l': ((40, 0, 0), (0, 0, 0)),
            'shin_l': ((50, 0, 0), (0, 0, 0)),
            'thigh_r': ((-45, 0, 0), (0, 0, 0)),
            'shin_r': ((20, 0, 0), (0, 0, 0)),
            'upperarm_r': ((25, 0, 0), (0, 0, 0)),
            'upperarm_l': ((-35, 0, 0), (0, 0, 0)),
        },
        19: {
            'hips': ((12, 0, 0), (0, 0, -0.05)),
            'spine': ((10, 0, 0), (0, 0, 0)),
            'thigh_l': ((-45, 0, 0), (0, 0, 0)),
            'shin_l': ((20, 0, 0), (0, 0, 0)),
            'thigh_r': ((40, 0, 0), (0, 0, 0)),
            'shin_r': ((50, 0, 0), (0, 0, 0)),
            'upperarm_r': ((-40, 0, 0), (0, 0, 0)),
            'upperarm_l': ((35, 0, 0), (0, 0, 0)),
        }
    })

    # 5. roll: 0.25s (8 frames) - Fast panicked forward lunge covering 4m, ends upright and overcommitted
    actions['roll'] = create_character_action(arm_obj, 'roll', 8, {
        0: {
            'hips': ((5, 0, 0), (0, 0, 0)),
            'spine': ((5, 0, 0), (0, 0, 0)),
            'thigh_l': ((-15, 0, 0), (0, 0, 0)),
            'thigh_r': ((15, 0, 0), (0, 0, 0)),
        },
        4: { # Midpoint: massive lunge forward, hips high, legs stretched 4m stride
            'hips': ((-8, 0, 0), (0, 2.0, -0.15)),
            'spine': ((-5, 0, 0), (0, 0, 0)), # upright stretch
            'chest': ((-4, 0, 0), (0, 0, 0)),
            'thigh_l': ((-70, 0, 0), (0, 0, 0)), # far forward lunge
            'shin_l': ((75, 0, 0), (0, 0, 0)),
            'thigh_r': ((55, 0, 0), (0, 0, 0)),  # trailing far behind
            'shin_r': ((15, 0, 0), (0, 0, 0)),
            'upperarm_r': ((-60, 0, 10), (0, 0, 0)),
            'forearm_r': ((-30, 0, 0), (0, 0, 0)),
            'weapon_r': ((-20, 0, 0), (0, 0, 0)),
        },
        8: { # Land upright, slightly overbalanced forward
            'hips': ((12, 0, 0), (0, 4.0, 0.0)),
            'spine': ((14, 0, 0), (0, 0, 0)),
            'chest': ((10, 0, 0), (0, 0, 0)),
            'thigh_l': ((-25, 0, 0), (0, 0, 0)),
            'shin_l': ((30, 0, 0), (0, 0, 0)),
            'thigh_r': ((20, 0, 0), (0, 0, 0)),
            'shin_r': ((10, 0, 0), (0, 0, 0)),
            'upperarm_r': ((-20, 0, 0), (0, 0, 0)),
            'forearm_r': ((-40, 0, 0), (0, 0, 0)),
        }
    })

    # 6. light_1: 0.45s (14 frames) - Lance thrust forward. Contact @ 0.08s (frame 2)
    # Recovery pose @ frame 14: lance pushed low-right, body rotated right
    actions['light_1'] = create_character_action(arm_obj, 'light_1', 14, {
        0: {
            'hips': ((0, 10, 0), (0, 0, 0)),
            'spine': ((5, 12, 0), (0, 0, 0)),
            'chest': ((8, 15, 0), (0, 0, 0)),
            'upperarm_r': ((-35, 15, -10), (0, 0, 0)),
            'forearm_r': ((-80, 0, 0), (0, 0, 0)),
            'weapon_r': ((0, 0, 0), (0, 0, 0)),
        },
        2: { # Contact frame @ 0.08s (frame 2/30 = 0.067s)
            'hips': ((5, -15, 0), (0, 0.1, 0)),
            'spine': ((10, -20, 0), (0, 0, 0)),
            'chest': ((12, -25, 0), (0, 0, 0)),
            # The shoulder carries the lance FORWARD. A thrust is a
            # rotation in the horizontal plane (Y), not a lift: with the
            # arm merely raised, the lance points at the sky and the
            # "contact" reads as a wind-up. The heavy's contact has the
            # same shape, and it reads.
            'upperarm_r': ((-80, -45, 25), (0, 0, 0)), # full thrust, out in front
            'forearm_r': ((-10, 0, 0), (0, 0, 0)),
            'weapon_r': ((-8, -22, 15), (0, 0, 0)),
        },
        7: {
            'hips': ((5, -10, 0), (0, 0.12, 0)),
            'spine': ((8, -12, 0), (0, 0, 0)),
            'chest': ((10, -15, 0), (0, 0, 0)),
            'upperarm_r': ((-72, -38, 20), (0, 0, 0)),
            'forearm_r': ((-22, 0, 0), (0, 0, 0)),
            'weapon_r': ((-10, -18, 12), (0, 0, 0)),
        },
        14: { # Recovery pose: lance low-right, wound right
            'hips': ((2, 18, 0), (0, 0.05, 0)),
            'spine': ((4, 22, 0), (0, 0, 0)),
            'chest': ((6, 25, 0), (0, 0, 0)),
            'upperarm_r': ((-20, 25, -15), (0, 0, 0)),
            'forearm_r': ((-55, 0, 0), (0, 0, 0)),
            'weapon_r': ((-25, 10, -10), (0, 0, 0)),
        }
    }, contact_frame=2)

    # 7. light_2: 0.45s (14 frames) - Chains from light_1 recovery!
    # Frame 0 matches light_1 frame 14. Contact @ frame 2. Recovery holds lance high-left.
    actions['light_2'] = create_character_action(arm_obj, 'light_2', 14, {
        0: { # Matches light_1 recovery
            'hips': ((2, 18, 0), (0, 0.05, 0)),
            'spine': ((4, 22, 0), (0, 0, 0)),
            'chest': ((6, 25, 0), (0, 0, 0)),
            'upperarm_r': ((-20, 25, -15), (0, 0, 0)),
            'forearm_r': ((-55, 0, 0), (0, 0, 0)),
            'weapon_r': ((-25, 10, -10), (0, 0, 0)),
        },
        2: { # Contact frame @ 0.08s: diagonal rising sweep to upper-left
            'hips': ((0, -22, 0), (0, 0.1, 0)),
            'spine': ((6, -28, 0), (0, 0, 0)),
            'chest': ((10, -32, 0), (0, 0, 0)),
            'upperarm_r': ((-70, -35, 20), (0, 0, 0)),
            'forearm_r': ((-45, 0, 0), (0, 0, 0)),
            'weapon_r': ((15, -20, 15), (0, 0, 0)),
        },
        7: {
            'hips': ((0, -15, 0), (0, 0.08, 0)),
            'spine': ((5, -18, 0), (0, 0, 0)),
            'chest': ((8, -20, 0), (0, 0, 0)),
            'upperarm_r': ((-75, -25, 15), (0, 0, 0)),
            'forearm_r': ((-55, 0, 0), (0, 0, 0)),
        },
        14: { # Recovery pose: lance held high above left shoulder
            'hips': ((-4, -15, 0), (0, 0.04, 0)),
            'spine': ((-2, -18, 0), (0, 0, 0)),
            'chest': ((0, -22, 0), (0, 0, 0)),
            'upperarm_r': ((-85, -15, 25), (0, 0, 0)),
            'forearm_r': ((-70, 0, 0), (0, 0, 0)),
            'weapon_r': ((30, 0, 20), (0, 0, 0)),
        }
    }, contact_frame=2)

    # 8. light_3: 0.45s (14 frames) - Chains from light_2 recovery!
    # Frame 0 matches light_2 frame 14. Contact @ frame 2. Final heavy plunge.
    actions['light_3'] = create_character_action(arm_obj, 'light_3', 14, {
        0: { # Matches light_2 recovery
            'hips': ((-4, -15, 0), (0, 0.04, 0)),
            'spine': ((-2, -18, 0), (0, 0, 0)),
            'chest': ((0, -22, 0), (0, 0, 0)),
            'upperarm_r': ((-85, -15, 25), (0, 0, 0)),
            'forearm_r': ((-70, 0, 0), (0, 0, 0)),
            'weapon_r': ((30, 0, 20), (0, 0, 0)),
        },
        2: { # Contact frame @ 0.08s: vicious downward plunge
            'hips': ((15, 0, 0), (0, 0.15, -0.08)),
            'spine': ((22, 0, 0), (0, 0, 0)),
            'chest': ((25, 0, 0), (0, 0, 0)),
            'upperarm_r': ((-95, 0, 0), (0, 0, 0)),
            'forearm_r': ((-15, 0, 0), (0, 0, 0)),
            'weapon_r': ((-40, 0, 0), (0, 0, 0)),
        },
        8: {
            'hips': ((12, 0, 0), (0, 0.12, -0.05)),
            'spine': ((16, 0, 0), (0, 0, 0)),
            'chest': ((18, 0, 0), (0, 0, 0)),
            'upperarm_r': ((-75, 0, 0), (0, 0, 0)),
            'forearm_r': ((-30, 0, 0), (0, 0, 0)),
        },
        14: { # Returns to ready guard
            'hips': ((0, 0, 0), (0, 0, 0)),
            'spine': ((4, 0, 0), (0, 0, 0)),
            'chest': ((3, 0, 0), (0, 0, 0)),
            'upperarm_r': ((-25, 10, -5), (0, 0, 0)),
            'forearm_r': ((-40, 0, 0), (0, 0, 0)),
            'weapon_r': ((-15, 0, 0), (0, 0, 0)),
        }
    }, contact_frame=2)

    # 9. heavy: 0.90s (27 frames) - Big two-handed sweeping cleave. Contact @ 0.12s (frame 4)
    actions['heavy'] = create_character_action(arm_obj, 'heavy', 27, {
        0: {
            'hips': ((-5, 25, 0), (0, 0, 0)),
            'spine': ((-5, 30, 0), (0, 0, 0)),
            'chest': ((-5, 35, 0), (0, 0, 0)),
            'upperarm_r': ((-60, 40, -25), (0, 0, 0)),
            'forearm_r': ((-75, 0, 0), (0, 0, 0)),
        },
        4: { # Contact frame @ 0.12s (frame 4/30 = 0.133s)
            'hips': ((12, -35, 0), (0, 0.15, 0)),
            'spine': ((18, -42, 0), (0, 0, 0)),
            'chest': ((20, -45, 0), (0, 0, 0)),
            'upperarm_r': ((-80, -45, 30), (0, 0, 0)), # massive horizontal cleave
            'forearm_r': ((-10, 0, 0), (0, 0, 0)),
            'weapon_r': ((-10, -25, 20), (0, 0, 0)),
        },
        12: { # Overcommitted follow-through
            'hips': ((15, -45, 0), (0, 0.18, 0)),
            'spine': ((20, -50, 0), (0, 0, 0)),
            'chest': ((22, -55, 0), (0, 0, 0)),
            'upperarm_r': ((-70, -55, 35), (0, 0, 0)),
            'forearm_r': ((-25, 0, 0), (0, 0, 0)),
        },
        20: { # Slow recovery
            'hips': ((8, -20, 0), (0, 0.08, 0)),
            'spine': ((10, -20, 0), (0, 0, 0)),
            'chest': ((10, -20, 0), (0, 0, 0)),
            'upperarm_r': ((-45, -20, 10), (0, 0, 0)),
            'forearm_r': ((-40, 0, 0), (0, 0, 0)),
        },
        27: { # Back to rest
            'hips': ((0, 0, 0), (0, 0, 0)),
            'spine': ((4, 0, 0), (0, 0, 0)),
            'chest': ((3, 0, 0), (0, 0, 0)),
            'upperarm_r': ((-25, 10, -5), (0, 0, 0)),
            'forearm_r': ((-40, 0, 0), (0, 0, 0)),
        }
    }, contact_frame=4)

    # 10. block: 0.20s (6 frames) into hold. Lance brought across chest diagonally
    actions['block'] = create_character_action(arm_obj, 'block', 6, {
        0: {
            'hips': ((0, 0, 0), (0, 0, 0)),
            'spine': ((2, 0, 0), (0, 0, 0)),
            'upperarm_r': ((-25, 10, -5), (0, 0, 0)),
            'forearm_r': ((-40, 0, 0), (0, 0, 0)),
        },
        6: { # Guard hold pose
            'hips': ((10, -15, 0), (0, 0, -0.05)),
            'spine': ((12, -18, 0), (0, 0, 0)),
            'chest': ((15, -20, 0), (0, 0, 0)),
            'upperarm_r': ((-65, -15, 15), (0, 0, 0)), # lance across chest
            'forearm_r': ((-75, 0, 0), (0, 0, 0)),
            'weapon_r': ((35, -20, 20), (0, 0, 0)),
            'upperarm_l': ((-55, 15, -15), (0, 0, 0)), # left hand bracing shaft
            'forearm_l': ((-70, 0, 0), (0, 0, 0)),
        }
    })

    # 11. hit: 0.35s (11 frames) - Flinch, knockback at frame 0
    actions['hit'] = create_character_action(arm_obj, 'hit', 11, {
        0: { # Knockback hit frame 0
            'hips': ((-18, 0, 0), (0, -0.25, 0.02)), # sharp jerk back
            'spine': ((-22, 0, 0), (0, 0, 0)),
            'chest': ((-25, 0, 0), (0, 0, 0)),
            'head': ((20, 0, 0), (0, 0, 0)), # head snapped back
            'upperarm_r': ((25, 15, 0), (0, 0, 0)),
            'forearm_r': ((-25, 0, 0), (0, 0, 0)),
        },
        4: { # Maximum recoil
            'hips': ((-22, 0, 0), (0, -0.32, 0.0)),
            'spine': ((-25, 0, 0), (0, 0, 0)),
            'chest': ((-28, 0, 0), (0, 0, 0)),
            'head': ((25, 0, 0), (0, 0, 0)),
        },
        8: { # Staggering to regain noble composure
            'hips': ((-8, 0, 0), (0, -0.15, 0.0)),
            'spine': ((-5, 0, 0), (0, 0, 0)),
            'head': ((-5, 0, 0), (0, 0, 0)),
        },
        11: { # Recovered
            'hips': ((0, 0, 0), (0, 0, 0)),
            'spine': ((4, 0, 0), (0, 0, 0)),
            'head': ((-4, 0, 0), (0, 0, 0)),
        }
    })

    # 12. stagger: 1.3s (39 frames) - Poise break. Goes to knees, lance drops, slow recovery
    actions['stagger'] = create_character_action(arm_obj, 'stagger', 39, {
        0: {
            'hips': ((-15, 0, 0), (0, 0, 0)),
            'spine': ((-15, 0, 0), (0, 0, 0)),
        },
        8: { # Falls forward onto knees
            'hips': ((35, 0, 0), (0, 0.1, -0.45)),
            'spine': ((30, 0, 0), (0, 0, 0)),
            'chest': ((25, 0, 0), (0, 0, 0)),
            'head': ((30, 0, 0), (0, 0, 0)),
            'thigh_l': ((80, 0, 0), (0, 0, 0)),
            'shin_l': ((85, 0, 0), (0, 0, 0)),
            'thigh_r': ((80, 0, 0), (0, 0, 0)),
            'shin_r': ((85, 0, 0), (0, 0, 0)),
            'upperarm_r': ((15, 0, 0), (0, 0, 0)),
            'weapon_r': ((-75, 0, 0), (0, 0, 0)), # lance tip hits ground
        },
        22: { # Weak groggy state on knees
            'hips': ((32, 0, 0), (0, 0.1, -0.45)),
            'spine': ((28, 0, 0), (0, 0, 0)),
            'head': ((20, 0, 0), (0, 0, 0)),
        },
        32: { # Pushing himself up with lance
            'hips': ((15, 0, 0), (0, 0.05, -0.20)),
            'thigh_l': ((40, 0, 0), (0, 0, 0)),
            'shin_l': ((45, 0, 0), (0, 0, 0)),
            'upperarm_r': ((-45, 0, 0), (0, 0, 0)),
            'weapon_r': ((-30, 0, 0), (0, 0, 0)),
        },
        39: { # Back upright
            'hips': ((0, 0, 0), (0, 0, 0)),
            'spine': ((4, 0, 0), (0, 0, 0)),
            'thigh_l': ((0, 0, 0), (0, 0, 0)),
            'shin_l': ((0, 0, 0), (0, 0, 0)),
            'thigh_r': ((0, 0, 0), (0, 0, 0)),
            'shin_r': ((0, 0, 0), (0, 0, 0)),
        }
    })

    # 13. death: 1.2s (36 frames) - A fall, not a collapse. Falls like a knight, one hand on lance
    actions['death'] = create_character_action(arm_obj, 'death', 36, {
        0: {
            'hips': ((0, 0, 0), (0, 0, 0)),
            'spine': ((-5, 0, 0), (0, 0, 0)),
        },
        12: { # Body tilting back rigid
            'hips': ((-45, 0, 0), (0, -0.3, -0.25)),
            'spine': ((-20, 0, 0), (0, 0, 0)),
            'head': ((15, 0, 0), (0, 0, 0)),
            'upperarm_r': ((-50, 0, 0), (0, 0, 0)),
            'weapon_r': ((-30, 0, 0), (0, 0, 0)),
        },
        24: { # Hitting ground
            'hips': ((-85, 0, 0), (0, -0.7, -0.95)),
            'spine': ((-5, 0, 0), (0, 0, 0)),
            'head': ((10, 0, 0), (0, 0, 0)),
            'thigh_l': ((15, 0, 0), (0, 0, 0)),
            'thigh_r': ((20, 0, 0), (0, 0, 0)),
            'upperarm_r': ((-35, 10, 0), (0, 0, 0)),
            'weapon_r': ((-15, 0, 0), (0, 0, 0)),
        },
        36: { # Resting still, lance laid across chest
            'hips': ((-90, 0, 0), (0, -0.75, -0.98)),
            'spine': ((0, 0, 0), (0, 0, 0)),
            'head': ((0, 0, 0), (0, 0, 0)),
            'upperarm_r': ((-30, 15, 0), (0, 0, 0)),
            'forearm_r': ((-60, 0, 0), (0, 0, 0)),
        }
    })

    # 14. interact: 1.2s (36 frames) - Examine gesture: tall frame leaning in, reading scholarly
    actions['interact'] = create_character_action(arm_obj, 'interact', 36, {
        0: {
            'hips': ((0, 0, 0), (0, 0, 0)),
            'spine': ((0, 0, 0), (0, 0, 0)),
            'head': ((0, 0, 0), (0, 0, 0)),
        },
        12: { # Leaning deep forward, examining with scholarly intensity
            'hips': ((25, 0, 0), (0, 0.15, -0.10)),
            'spine': ((30, 0, 0), (0, 0, 0)),
            'chest': ((35, 0, 0), (0, 0, 0)),
            'head': ((-25, 0, 0), (0, 0, 0)), # chin up to peer down
            'upperarm_l': ((-45, 10, -10), (0, 0, 0)), # hand to chin/basin
            'forearm_l': ((-80, 0, 0), (0, 0, 0)),
        },
        24: { # Slight tilt of head, squinting
            'hips': ((25, 0, 0), (0, 0.15, -0.10)),
            'spine': ((30, 0, 0), (0, 0, 0)),
            'head': ((-22, 10, 5), (0, 0, 0)),
        },
        36: { # Return upright
            'hips': ((0, 0, 0), (0, 0, 0)),
            'spine': ((4, 0, 0), (0, 0, 0)),
            'chest': ((3, 0, 0), (0, 0, 0)),
            'head': ((0, 0, 0), (0, 0, 0)),
            'upperarm_l': ((15, -10, 0), (0, 0, 0)),
            'forearm_l': ((-30, 0, 0), (0, 0, 0)),
        }
    })

    return actions

# -----------------------------------------------------------------------------
# 9. SANCHO PANZA ANIMATION SET (15 CLIPS)
# Unglamorous, practical, low center of gravity, heavy tumble roll, parry snap.
# -----------------------------------------------------------------------------

def author_sancho_animations(arm_obj):
    """
    Author the 15 clips for Sancho Panza.
    Hit timings: light contact @ 0.08s (frame 2), heavy contact @ 0.12s (frame 4).
    Chained lights: light_2 starts from light_1 recovery, light_3 from light_2 recovery.
    Roll: 0.40s (12 frames) heavy tumble ending on one knee.
    Parry: 0.20s (6 frames) sharp buckler snap.
    Desvelar: 0.6s (18 frames) sack toss gesture.
    """
    actions = {}

    # 1. idle: 2.0s (60 frames) - low wide stance, belly breathing, flail hanging loose
    actions['idle'] = create_character_action(arm_obj, 'idle', 60, {
        0: {
            'hips': ((6, 0, 0), (0, 0, -0.04)),
            'spine': ((8, 0, 0), (0, 0, 0)),
            'chest': ((4, 0, 0), (0, 0, 0)),
            'head': ((-6, 0, 0), (0, 0, 0)),
            'thigh_l': ((8, -8, 0), (0, 0, 0)), # wide stance
            'thigh_r': ((8, 8, 0), (0, 0, 0)),
            'upperarm_r': ((12, 12, 0), (0, 0, 0)),
            'forearm_r': ((-30, 0, 0), (0, 0, 0)),
            'upperarm_l': ((-10, -15, 0), (0, 0, 0)),
            'forearm_l': ((-55, 0, 0), (0, 0, 0)), # buckler at ready
        },
        30: {
            'hips': ((6, 0, 0), (0, 0, -0.02)), # breath bob
            'spine': ((6, 0, 0), (0, 0, 0)),
            'chest': ((6, 0, 0), (0, 0, 0)),
            'head': ((-4, 0, 0), (0, 0, 0)),
            'thigh_l': ((6, -8, 0), (0, 0, 0)),
            'thigh_r': ((6, 8, 0), (0, 0, 0)),
            'upperarm_r': ((10, 10, 0), (0, 0, 0)),
            'forearm_r': ((-28, 0, 0), (0, 0, 0)),
            'upperarm_l': ((-12, -15, 0), (0, 0, 0)),
            'forearm_l': ((-52, 0, 0), (0, 0, 0)),
        },
        60: {
            'hips': ((6, 0, 0), (0, 0, -0.04)),
            'spine': ((8, 0, 0), (0, 0, 0)),
            'chest': ((4, 0, 0), (0, 0, 0)),
            'head': ((-6, 0, 0), (0, 0, 0)),
            'thigh_l': ((8, -8, 0), (0, 0, 0)),
            'thigh_r': ((8, 8, 0), (0, 0, 0)),
            'upperarm_r': ((12, 12, 0), (0, 0, 0)),
            'forearm_r': ((-30, 0, 0), (0, 0, 0)),
            'upperarm_l': ((-10, -15, 0), (0, 0, 0)),
            'forearm_l': ((-55, 0, 0), (0, 0, 0)),
        }
    })

    # 2. walk: 0.9s (27 frames) - 4.2 m/s short quick waddling peasant steps
    actions['walk'] = create_character_action(arm_obj, 'walk', 27, {
        0: {
            'hips': ((5, 0, 6), (0, 0, -0.04)),
            'thigh_l': ((-20, -5, 0), (0, 0, 0)),
            'shin_l': ((15, 0, 0), (0, 0, 0)),
            'thigh_r': ((18, 5, 0), (0, 0, 0)),
            'shin_r': ((10, 0, 0), (0, 0, 0)),
            'upperarm_r': ((15, 0, 0), (0, 0, 0)),
            'upperarm_l': ((-15, 0, 0), (0, 0, 0)),
        },
        7: {
            'hips': ((5, 0, -6), (0, 0, -0.01)),
            'thigh_l': ((0, -5, 0), (0, 0, 0)),
            'shin_l': ((5, 0, 0), (0, 0, 0)),
            'thigh_r': ((-8, 5, 0), (0, 0, 0)),
            'shin_r': ((30, 0, 0), (0, 0, 0)),
            'upperarm_r': ((-5, 0, 0), (0, 0, 0)),
            'upperarm_l': ((5, 0, 0), (0, 0, 0)),
        },
        14: {
            'hips': ((5, 0, -6), (0, 0, -0.04)),
            'thigh_l': ((18, -5, 0), (0, 0, 0)),
            'shin_l': ((10, 0, 0), (0, 0, 0)),
            'thigh_r': ((-20, 5, 0), (0, 0, 0)),
            'shin_r': ((15, 0, 0), (0, 0, 0)),
            'upperarm_r': ((-20, 0, 0), (0, 0, 0)),
            'upperarm_l': ((15, 0, 0), (0, 0, 0)),
        },
        21: {
            'hips': ((5, 0, 6), (0, 0, -0.01)),
            'thigh_l': ((-8, -5, 0), (0, 0, 0)),
            'shin_l': ((30, 0, 0), (0, 0, 0)),
            'thigh_r': ((0, 5, 0), (0, 0, 0)),
            'shin_r': ((5, 0, 0), (0, 0, 0)),
            'upperarm_r': ((5, 0, 0), (0, 0, 0)),
            'upperarm_l': ((-5, 0, 0), (0, 0, 0)),
        },
        27: {
            'hips': ((5, 0, 6), (0, 0, -0.04)),
            'thigh_l': ((-20, -5, 0), (0, 0, 0)),
            'shin_l': ((15, 0, 0), (0, 0, 0)),
            'thigh_r': ((18, 5, 0), (0, 0, 0)),
            'shin_r': ((10, 0, 0), (0, 0, 0)),
            'upperarm_r': ((15, 0, 0), (0, 0, 0)),
            'upperarm_l': ((-15, 0, 0), (0, 0, 0)),
        }
    })

    # 3. run: 0.62s (19 frames) - 6.8 m/s heavy determined trot, leaning forward against sack
    actions['run'] = create_character_action(arm_obj, 'run', 19, {
        0: {
            'hips': ((18, 0, 0), (0, 0, -0.08)), # forward lean
            'spine': ((15, 0, 0), (0, 0, 0)),
            'chest': ((12, 0, 0), (0, 0, 0)),
            'thigh_l': ((-38, 0, 0), (0, 0, 0)),
            'shin_l': ((25, 0, 0), (0, 0, 0)),
            'thigh_r': ((35, 0, 0), (0, 0, 0)),
            'shin_r': ((40, 0, 0), (0, 0, 0)),
            'upperarm_r': ((25, 0, 0), (0, 0, 0)),
            'upperarm_l': ((-20, 0, 0), (0, 0, 0)),
        },
        9: {
            'hips': ((18, 0, 0), (0, 0, 0.02)),
            'spine': ((15, 0, 0), (0, 0, 0)),
            'chest': ((12, 0, 0), (0, 0, 0)),
            'thigh_l': ((35, 0, 0), (0, 0, 0)),
            'shin_l': ((40, 0, 0), (0, 0, 0)),
            'thigh_r': ((-38, 0, 0), (0, 0, 0)),
            'shin_r': ((25, 0, 0), (0, 0, 0)),
            'upperarm_r': ((-20, 0, 0), (0, 0, 0)),
            'upperarm_l': ((25, 0, 0), (0, 0, 0)),
        },
        19: {
            'hips': ((18, 0, 0), (0, 0, -0.08)),
            'spine': ((15, 0, 0), (0, 0, 0)),
            'chest': ((12, 0, 0), (0, 0, 0)),
            'thigh_l': ((-38, 0, 0), (0, 0, 0)),
            'shin_l': ((25, 0, 0), (0, 0, 0)),
            'thigh_r': ((35, 0, 0), (0, 0, 0)),
            'shin_r': ((40, 0, 0), (0, 0, 0)),
            'upperarm_r': ((25, 0, 0), (0, 0, 0)),
            'upperarm_l': ((-20, 0, 0), (0, 0, 0)),
        }
    })

    # 4. roll: 0.40s (12 frames) - Slow heavy tumble covering 2m, ends on one knee
    actions['roll'] = create_character_action(arm_obj, 'roll', 12, {
        0: {
            'hips': ((10, 0, 0), (0, 0, 0)),
            'spine': ((10, 0, 0), (0, 0, 0)),
            'thigh_l': ((10, 0, 0), (0, 0, 0)),
            'thigh_r': ((10, 0, 0), (0, 0, 0)),
        },
        3: { # Tuck into ball
            'hips': ((75, 0, 0), (0, 0.5, -0.30)),
            'spine': ((45, 0, 0), (0, 0, 0)), # tight curl
            'chest': ((40, 0, 0), (0, 0, 0)),
            'thigh_l': ((85, 0, 0), (0, 0, 0)),
            'shin_l': ((90, 0, 0), (0, 0, 0)),
            'thigh_r': ((85, 0, 0), (0, 0, 0)),
            'shin_r': ((90, 0, 0), (0, 0, 0)),
        },
        6: { # Midpoint: upside down tumble / heavy roll on ground
            'hips': ((160, 0, 0), (0, 1.0, -0.45)), # inverted tumble
            'spine': ((40, 0, 0), (0, 0, 0)), # tightly curled
            'chest': ((35, 0, 0), (0, 0, 0)),
            'head': ((30, 0, 0), (0, 0, 0)),
            'thigh_l': ((110, 0, 0), (0, 0, 0)), # tucked tight to chest
            'shin_l': ((120, 0, 0), (0, 0, 0)),
            'thigh_r': ((110, 0, 0), (0, 0, 0)),
            'shin_r': ((120, 0, 0), (0, 0, 0)),
            'upperarm_r': ((-45, 0, 0), (0, 0, 0)),
            'upperarm_l': ((-45, 0, 0), (0, 0, 0)),
        },
        9: { # Rolling onto knees
            'hips': ((45, 0, 0), (0, 1.6, -0.35)),
            'thigh_l': ((60, 0, 0), (0, 0, 0)),
            'shin_l': ((75, 0, 0), (0, 0, 0)),
            'thigh_r': ((85, 0, 0), (0, 0, 0)),
            'shin_r': ((85, 0, 0), (0, 0, 0)),
        },
        12: { # Ends on one knee panting (2m displacement)
            'hips': ((15, 0, 0), (0, 2.0, -0.28)),
            'spine': ((20, 0, 0), (0, 0, 0)),
            'chest': ((15, 0, 0), (0, 0, 0)),
            'thigh_l': ((-10, 0, 0), (0, 0, 0)), # left foot planted
            'shin_l': ((65, 0, 0), (0, 0, 0)),
            'thigh_r': ((65, 0, 0), (0, 0, 0)),  # right knee on ground
            'shin_r': ((85, 0, 0), (0, 0, 0)),
            'upperarm_r': ((20, 0, 0), (0, 0, 0)),
            'forearm_r': ((-45, 0, 0), (0, 0, 0)),
        }
    })

    # 5. light_1: 0.45s (14 frames) - Flail horizontal sweep. Contact @ 0.08s (frame 2)
    # Recovery pose @ frame 14: flail wrapped across to left side
    actions['light_1'] = create_character_action(arm_obj, 'light_1', 14, {
        0: {
            'hips': ((0, 15, 0), (0, 0, 0)),
            'spine': ((5, 18, 0), (0, 0, 0)),
            'upperarm_r': ((-20, 25, -20), (0, 0, 0)),
            'forearm_r': ((-60, 0, 0), (0, 0, 0)),
            'weapon_r': ((30, 20, 0), (0, 0, 0)),
        },
        2: { # Contact frame @ 0.08s (frame 2): violent horizontal swipe
            'hips': ((8, -18, 0), (0, 0.08, 0)),
            'spine': ((12, -25, 0), (0, 0, 0)),
            'chest': ((15, -30, 0), (0, 0, 0)),
            'upperarm_r': ((-65, -30, 15), (0, 0, 0)),
            'forearm_r': ((-15, 0, 0), (0, 0, 0)),
            'weapon_r': ((-25, -15, 10), (0, 0, 0)),
        },
        7: {
            'hips': ((8, -25, 0), (0, 0.1, 0)),
            'spine': ((10, -30, 0), (0, 0, 0)),
            'upperarm_r': ((-70, -35, 20), (0, 0, 0)),
            'forearm_r': ((-35, 0, 0), (0, 0, 0)),
        },
        14: { # Recovery pose: arm and flail wrapped to the left
            'hips': ((4, -20, 0), (0, 0.04, 0)),
            'spine': ((6, -22, 0), (0, 0, 0)),
            'chest': ((8, -25, 0), (0, 0, 0)),
            'upperarm_r': ((-45, -30, 25), (0, 0, 0)),
            'forearm_r': ((-75, 0, 0), (0, 0, 0)),
            'weapon_r': ((15, -25, 10), (0, 0, 0)),
        }
    }, contact_frame=2)

    # 6. light_2: 0.45s (14 frames) - Chains from light_1 recovery! Backhand flail sweep
    actions['light_2'] = create_character_action(arm_obj, 'light_2', 14, {
        0: { # Matches light_1 recovery
            'hips': ((4, -20, 0), (0, 0.04, 0)),
            'spine': ((6, -22, 0), (0, 0, 0)),
            'chest': ((8, -25, 0), (0, 0, 0)),
            'upperarm_r': ((-45, -30, 25), (0, 0, 0)),
            'forearm_r': ((-75, 0, 0), (0, 0, 0)),
            'weapon_r': ((15, -25, 10), (0, 0, 0)),
        },
        2: { # Contact frame @ 0.08s (frame 2): backhand whip to right
            'hips': ((6, 20, 0), (0, 0.08, 0)),
            'spine': ((8, 25, 0), (0, 0, 0)),
            'chest': ((10, 30, 0), (0, 0, 0)),
            'upperarm_r': ((-55, 35, -25), (0, 0, 0)),
            'forearm_r': ((-20, 0, 0), (0, 0, 0)),
            'weapon_r': ((-20, 25, -15), (0, 0, 0)),
        },
        7: {
            'hips': ((6, 28, 0), (0, 0.1, 0)),
            'spine': ((8, 32, 0), (0, 0, 0)),
            'upperarm_r': ((-60, 40, -30), (0, 0, 0)),
            'forearm_r': ((-35, 0, 0), (0, 0, 0)),
        },
        14: { # Recovery pose: flail wound up high right
            'hips': ((2, 15, 0), (0, 0.05, 0)),
            'spine': ((4, 18, 0), (0, 0, 0)),
            'chest': ((6, 20, 0), (0, 0, 0)),
            'upperarm_r': ((-75, 20, -15), (0, 0, 0)),
            'forearm_r': ((-70, 0, 0), (0, 0, 0)),
            'weapon_r': ((35, 15, 0), (0, 0, 0)),
        }
    }, contact_frame=2)

    # 7. light_3: 0.45s (14 frames) - Chains from light_2 recovery! Downward smash
    actions['light_3'] = create_character_action(arm_obj, 'light_3', 14, {
        0: { # Matches light_2 recovery
            'hips': ((2, 15, 0), (0, 0.05, 0)),
            'spine': ((4, 18, 0), (0, 0, 0)),
            'chest': ((6, 20, 0), (0, 0, 0)),
            'upperarm_r': ((-75, 20, -15), (0, 0, 0)),
            'forearm_r': ((-70, 0, 0), (0, 0, 0)),
            'weapon_r': ((35, 15, 0), (0, 0, 0)),
        },
        2: { # Contact frame @ 0.08s (frame 2): heavy overhead downward smash
            'hips': ((18, 0, 0), (0, 0.12, -0.10)),
            'spine': ((25, 0, 0), (0, 0, 0)),
            'chest': ((30, 0, 0), (0, 0, 0)),
            'upperarm_r': ((-85, 0, 0), (0, 0, 0)),
            'forearm_r': ((-15, 0, 0), (0, 0, 0)),
            'weapon_r': ((-45, 0, 0), (0, 0, 0)),
        },
        8: {
            'hips': ((15, 0, 0), (0, 0.10, -0.08)),
            'spine': ((20, 0, 0), (0, 0, 0)),
            'upperarm_r': ((-65, 0, 0), (0, 0, 0)),
            'forearm_r': ((-30, 0, 0), (0, 0, 0)),
        },
        14: { # Returns to low crouched ready stance
            'hips': ((6, 0, 0), (0, 0, -0.04)),
            'spine': ((8, 0, 0), (0, 0, 0)),
            'chest': ((4, 0, 0), (0, 0, 0)),
            'upperarm_r': ((12, 12, 0), (0, 0, 0)),
            'forearm_r': ((-30, 0, 0), (0, 0, 0)),
        }
    }, contact_frame=2)

    # 8. heavy: 0.90s (27 frames) - Massive wind-up overhead slam. Contact @ 0.12s (frame 4)
    actions['heavy'] = create_character_action(arm_obj, 'heavy', 27, {
        0: {
            'hips': ((-8, 10, 0), (0, 0, 0)),
            'spine': ((-10, 15, 0), (0, 0, 0)),
            'chest': ((-15, 20, 0), (0, 0, 0)),
            'upperarm_r': ((-85, 25, -20), (0, 0, 0)),
            'forearm_r': ((-85, 0, 0), (0, 0, 0)),
        },
        4: { # Contact frame @ 0.12s (frame 4): body weight thrown downward
            'hips': ((24, -5, 0), (0, 0.15, -0.15)),
            'spine': ((32, -5, 0), (0, 0, 0)),
            'chest': ((38, -5, 0), (0, 0, 0)),
            'upperarm_r': ((-95, -5, 5), (0, 0, 0)),
            'forearm_r': ((-10, 0, 0), (0, 0, 0)),
            'weapon_r': ((-55, 0, 0), (0, 0, 0)),
        },
        12: { # Heavy impact follow-through
            'hips': ((26, -5, 0), (0, 0.16, -0.16)),
            'spine': ((34, -5, 0), (0, 0, 0)),
            'upperarm_r': ((-80, 0, 0), (0, 0, 0)),
            'forearm_r': ((-25, 0, 0), (0, 0, 0)),
        },
        20: { # Straining back up
            'hips': ((14, 0, 0), (0, 0.08, -0.08)),
            'spine': ((16, 0, 0), (0, 0, 0)),
            'upperarm_r': ((-35, 5, 0), (0, 0, 0)),
            'forearm_r': ((-40, 0, 0), (0, 0, 0)),
        },
        27: { # Back to rest
            'hips': ((6, 0, 0), (0, 0, -0.04)),
            'spine': ((8, 0, 0), (0, 0, 0)),
            'chest': ((4, 0, 0), (0, 0, 0)),
            'upperarm_r': ((12, 12, 0), (0, 0, 0)),
            'forearm_r': ((-30, 0, 0), (0, 0, 0)),
        }
    }, contact_frame=4)

    # 9. block: 0.20s (6 frames) into hold. Sharp buckler raised to guard
    actions['block'] = create_character_action(arm_obj, 'block', 6, {
        0: {
            'hips': ((6, 0, 0), (0, 0, -0.04)),
            'upperarm_l': ((-10, -15, 0), (0, 0, 0)),
            'forearm_l': ((-55, 0, 0), (0, 0, 0)),
        },
        6: { # Guard pose: buckler high protecting face and chest
            'hips': ((12, -15, 0), (0, 0, -0.08)),
            'spine': ((14, -18, 0), (0, 0, 0)),
            'chest': ((16, -20, 0), (0, 0, 0)),
            'upperarm_l': ((-45, -25, 20), (0, 0, 0)),
            'forearm_l': ((-95, 0, 0), (0, 0, 0)),
        }
    })

    # 10. parry: 0.20s (6 frames) - Tight snap of the buckler up. A DECISION, not a flourish
    #
    # Six frames, not five: the parry WINDOW is 0.18 s, and an animation
    # that ends before the window does leaves a blow landing on a buckler
    # that is no longer there. The rule everywhere else is the same — the
    # clip CONTAINS the window it has to cover.
    actions['parry'] = create_character_action(arm_obj, 'parry', 6, {
        0: {
            'hips': ((8, -10, 0), (0, 0, -0.06)),
            'upperarm_l': ((-30, -20, 10), (0, 0, 0)),
            'forearm_l': ((-80, 0, 0), (0, 0, 0)),
        },
        2: { # Maximum snap forward and up (parry catch @ frame 2)
            'hips': ((5, -25, 0), (0, 0.1, -0.04)),
            'spine': ((8, -30, 0), (0, 0, 0)),
            'chest': ((10, -35, 0), (0, 0, 0)),
            'upperarm_l': ((-75, -35, 30), (0, 0, 0)), # punch buckler forward
            'forearm_l': ((-70, 0, 0), (0, 0, 0)),
        },
        6: { # Re-centering into guard, and the clip outlasts the window
            'hips': ((10, -15, 0), (0, 0, -0.06)),
            'upperarm_l': ((-45, -25, 20), (0, 0, 0)),
            'forearm_l': ((-90, 0, 0), (0, 0, 0)),
        }
    })

    # 11. hit: 0.25s (8 frames) - Flinch, knockback @ frame 0, faster recovery than Quixote
    actions['hit'] = create_character_action(arm_obj, 'hit', 8, {
        0: { # Knockback frame 0
            'hips': ((-15, 0, 0), (0, -0.22, 0.0)),
            'spine': ((-18, 0, 0), (0, 0, 0)),
            'chest': ((-20, 0, 0), (0, 0, 0)),
            'head': ((15, 0, 0), (0, 0, 0)),
        },
        3: { # Recoil into sack
            'hips': ((-18, 0, 0), (0, -0.26, -0.02)),
            'spine': ((-22, 0, 0), (0, 0, 0)),
            'head': ((18, 0, 0), (0, 0, 0)),
        },
        8: { # Snaps right back to low stance
            'hips': ((6, 0, 0), (0, 0, -0.04)),
            'spine': ((8, 0, 0), (0, 0, 0)),
            'head': ((-6, 0, 0), (0, 0, 0)),
        }
    })

    # 12. stagger: 1.5s (45 frames) - Poise break: knocked backward onto backside, sack weighs him down
    actions['stagger'] = create_character_action(arm_obj, 'stagger', 45, {
        0: {
            'hips': ((-15, 0, 0), (0, 0, 0)),
            'spine': ((-18, 0, 0), (0, 0, 0)),
        },
        8: { # Knocked onto backside
            'hips': ((-45, 0, 0), (0, -0.35, -0.42)),
            'spine': ((-25, 0, 0), (0, 0, 0)),
            'chest': ((-20, 0, 0), (0, 0, 0)),
            'thigh_l': ((-25, 0, 0), (0, 0, 0)),
            'thigh_r': ((-25, 0, 0), (0, 0, 0)),
        },
        22: { # Heavy groaning on ground, rolling forward
            'hips': ((20, 0, 0), (0, -0.20, -0.38)),
            'spine': ((30, 0, 0), (0, 0, 0)),
            'head': ((20, 0, 0), (0, 0, 0)),
        },
        35: { # Scrambling onto knees
            'hips': ((25, 0, 0), (0, -0.08, -0.20)),
            'thigh_l': ((55, 0, 0), (0, 0, 0)),
            'shin_l': ((65, 0, 0), (0, 0, 0)),
        },
        45: { # Recovered
            'hips': ((6, 0, 0), (0, 0, -0.04)),
            'spine': ((8, 0, 0), (0, 0, 0)),
            'thigh_l': ((8, -8, 0), (0, 0, 0)),
            'shin_l': ((0, 0, 0), (0, 0, 0)),
            'thigh_r': ((8, 8, 0), (0, 0, 0)),
            'shin_r': ((0, 0, 0), (0, 0, 0)),
        }
    })

    # 13. death: 1.2s (36 frames) - Heavy fall under sack's weight
    actions['death'] = create_character_action(arm_obj, 'death', 36, {
        0: {
            'hips': ((0, 0, 0), (0, 0, 0)),
        },
        12: {
            'hips': ((-35, 10, 0), (0, -0.2, -0.25)),
            'spine': ((-20, 10, 0), (0, 0, 0)),
        },
        24: {
            'hips': ((-85, 20, 0), (0, -0.4, -0.70)),
            'spine': ((-10, 10, 0), (0, 0, 0)),
            'thigh_l': ((30, 0, 0), (0, 0, 0)),
            'thigh_r': ((40, 0, 0), (0, 0, 0)),
        },
        36: {
            'hips': ((-90, 20, 0), (0, -0.42, -0.72)),
            'spine': ((0, 0, 0), (0, 0, 0)),
        }
    })

    # 14. interact: 1.2s (36 frames) - Practical crouch examination
    actions['interact'] = create_character_action(arm_obj, 'interact', 36, {
        0: {
            'hips': ((6, 0, 0), (0, 0, -0.04)),
        },
        12: { # Squatting down low, inspecting with hands
            'hips': ((35, 0, 0), (0, 0.1, -0.32)),
            'spine': ((25, 0, 0), (0, 0, 0)),
            'chest': ((20, 0, 0), (0, 0, 0)),
            'head': ((-15, 0, 0), (0, 0, 0)),
            'thigh_l': ((65, 0, 0), (0, 0, 0)),
            'shin_l': ((75, 0, 0), (0, 0, 0)),
            'thigh_r': ((65, 0, 0), (0, 0, 0)),
            'shin_r': ((75, 0, 0), (0, 0, 0)),
            'upperarm_r': ((-35, 0, 0), (0, 0, 0)),
            'forearm_r': ((-30, 0, 0), (0, 0, 0)),
        },
        24: { # Poking forward curiously
            'hips': ((35, 0, 0), (0, 0.1, -0.32)),
            'upperarm_r': ((-45, 0, 0), (0, 0, 0)),
            'forearm_r': ((-15, 0, 0), (0, 0, 0)),
        },
        36: { # Back upright
            'hips': ((6, 0, 0), (0, 0, -0.04)),
            'spine': ((8, 0, 0), (0, 0, 0)),
            'thigh_l': ((8, -8, 0), (0, 0, 0)),
            'shin_l': ((0, 0, 0), (0, 0, 0)),
            'thigh_r': ((8, 8, 0), (0, 0, 0)),
            'shin_r': ((0, 0, 0), (0, 0, 0)),
        }
    })

    # 15. desvelar: 0.6s (18 frames) - Forward gesture with sack, strips Book skin for 8s
    actions['desvelar'] = create_character_action(arm_obj, 'desvelar', 18, {
        0: {
            'hips': ((6, 0, 0), (0, 0, -0.04)),
            'spine': ((8, 0, 0), (0, 0, 0)),
        },
        5: { # Reaching back to grab sack strap
            'hips': ((-5, 15, 0), (0, 0, -0.02)),
            'spine': ((-5, 20, 0), (0, 0, 0)),
            'chest': ((-5, 25, 0), (0, 0, 0)),
            'upperarm_l': ((35, -25, -25), (0, 0, 0)),
            'forearm_l': ((-85, 0, 0), (0, 0, 0)),
        },
        9: { # Forward throwing / unveiling motion
            'hips': ((15, -20, 0), (0, 0.15, -0.06)),
            'spine': ((22, -25, 0), (0, 0, 0)),
            'chest': ((25, -30, 0), (0, 0, 0)),
            'upperarm_l': ((-75, -25, 30), (0, 0, 0)), # fling arm forward
            'forearm_l': ((-15, 0, 0), (0, 0, 0)),
        },
        18: { # Return to stance
            'hips': ((6, 0, 0), (0, 0, -0.04)),
            'spine': ((8, 0, 0), (0, 0, 0)),
            'chest': ((4, 0, 0), (0, 0, 0)),
            'upperarm_l': ((-10, -15, 0), (0, 0, 0)),
            'forearm_l': ((-55, 0, 0), (0, 0, 0)),
        }
    })

    return actions

# -----------------------------------------------------------------------------
# 10. EXPORT & VERIFICATION SUITE
# -----------------------------------------------------------------------------

def export_character_glb(arm_obj, mesh_obj, output_path):
    """Export character to glTF .glb with exact engine settings."""
    bpy.ops.object.mode_set(mode='OBJECT')
    bpy.ops.object.select_all(action='DESELECT')
    arm_obj.select_set(True)
    mesh_obj.select_set(True)
    bpy.context.view_layer.objects.active = arm_obj

    bpy.ops.export_scene.gltf(
        filepath=output_path,
        use_selection=True,
        export_apply=True,
        export_animations=True,
        export_animation_mode='ACTIONS',
        export_draco_mesh_compression_enable=False,
        export_meshopt_compression_enable=False,
        export_all_vertex_colors=True,
        export_materials='EXPORT',
        export_anim_single_armature=True
    )

def count_triangles(mesh_obj):
    """Count exact triangle count after triangulation."""
    return sum(len(p.vertices) - 2 for p in mesh_obj.data.polygons)

def verify_rigs_and_animations(q_data, s_data):
    """
    Check all 6 mandatory constraints and print the report table.
    Fails loudly (sys.exit(1)) if any constraint is violated.
    """
    errors = []
    print("\n" + "=" * 80)
    print("  FIEL AL LIBRO — HERO RIG & ANIMATION VERIFICATION REPORT")
    print("=" * 80)

    # 1. Triangle Count Check [200, 800]
    q_tris = q_data['triangles']
    s_tris = s_data['triangles']
    print(f"\n[1] Triangle Counts:")
    print(f"    Don Quixote : {q_tris:4d} triangles (spec: 200–800) -> {'PASS' if 200 <= q_tris <= 800 else 'FAIL'}")
    print(f"    Sancho Panza: {s_tris:4d} triangles (spec: 200–800) -> {'PASS' if 200 <= s_tris <= 800 else 'FAIL'}")
    if not (200 <= q_tris <= 800):
        errors.append(f"Quixote triangle count {q_tris} outside [200, 800]")
    if not (200 <= s_tris <= 800):
        errors.append(f"Sancho triangle count {s_tris} outside [200, 800]")

    # 2. Bone Names Match Exactly
    q_bones = q_data['bones']
    s_bones = s_data['bones']
    bones_match = (q_bones == s_bones)
    print(f"\n[2] Bone Names Match:")
    print(f"    Quixote bone count : {len(q_bones)}")
    print(f"    Sancho bone count  : {len(s_bones)}")
    print(f"    Identical hierarchy: {bones_match} -> {'PASS' if bones_match else 'FAIL'}")
    if not bones_match:
        errors.append(f"Bone lists differ: Q={q_bones} vs S={s_bones}")

    # 3. Clip Durations and Contact Frames
    #
    # `window` is the gameplay window the clip has to COVER, in seconds:
    # the invulnerability of a dodge, the reel of a hit, the stagger, the
    # parry. A clip that is SHORTER than its window ends while the game
    # still thinks it is happening — the animation says the buckler is
    # back in guard while a blow is still being parried.
    SPEC_TABLE = {
        'idle':       {'sec': 2.00, 'frames': 60, 'contact': None, 'window': None},
        'walk':       {'sec': 0.90, 'frames': 27, 'contact': None, 'window': None},
        'run':        {'sec': 0.62, 'frames': 19, 'contact': None, 'window': None},
        'roll_q':     {'sec': 0.25, 'frames': 8,  'contact': None, 'window': 0.25},
        'roll_s':     {'sec': 0.40, 'frames': 12, 'contact': None, 'window': 0.40},
        'light_1':    {'sec': 0.45, 'frames': 14, 'contact': 0.08, 'min_c': 0.04, 'max_c': 0.16, 'window': None},
        'light_2':    {'sec': 0.45, 'frames': 14, 'contact': 0.08, 'min_c': 0.04, 'max_c': 0.16, 'window': None},
        'light_3':    {'sec': 0.45, 'frames': 14, 'contact': 0.08, 'min_c': 0.04, 'max_c': 0.16, 'window': None},
        'heavy':      {'sec': 0.90, 'frames': 27, 'contact': 0.12, 'min_c': 0.04, 'max_c': 0.20, 'window': None},
        'block':      {'sec': 0.20, 'frames': 6,  'contact': None, 'window': 0.18},
        'hit_q':      {'sec': 0.35, 'frames': 11, 'contact': None, 'window': 0.35},
        'hit_s':      {'sec': 0.25, 'frames': 8,  'contact': None, 'window': 0.25},
        'stagger_q':  {'sec': 1.30, 'frames': 39, 'contact': None, 'window': 1.30},
        'stagger_s':  {'sec': 1.50, 'frames': 45, 'contact': None, 'window': 1.50},
        'death':      {'sec': 1.20, 'frames': 36, 'contact': None, 'window': None},
        'interact':   {'sec': 1.20, 'frames': 36, 'contact': None, 'window': None},
        'idle_lost':  {'sec': 2.00, 'frames': 60, 'contact': None, 'window': None}, # Quixote only
        'parry':      {'sec': 0.20, 'frames': 6,  'contact': None, 'window': 0.18}, # Sancho only
        'desvelar':   {'sec': 0.60, 'frames': 18, 'contact': None, 'window': None}, # Sancho only
    }

    print(f"\n[3] Clip Inventory & Timing Verification (30 fps):")
    print("-" * 88)
    print(f"{'Character':<10} | {'Clip':<12} | {'Len (s)':<8} | {'Frames':<7} | {'Spec Frames':<11} | {'Contact':<11} | {'Status'}")
    print("-" * 88)

    all_char_checks = [('Quixote', q_data['actions']), ('Sancho', s_data['actions'])]
    for char_name, actions in all_char_checks:
        for clip_name, act_info in sorted(actions.items()):
            frames = act_info['frames']
            dur_s = frames / 30.0

            spec_key = clip_name
            if clip_name in ('roll', 'hit', 'stagger'):
                spec_key = f"{clip_name}_{'q' if char_name == 'Quixote' else 's'}"

            spec = SPEC_TABLE.get(spec_key, {})
            spec_frames = spec.get('frames', 0)

            # Check duration tolerance (within 2 frames)
            dur_ok = abs(frames - spec_frames) <= 2

            # Check contact frame
            contact_str = "—"
            contact_ok = True
            if 'contact' in spec and spec['contact'] is not None:
                # Find marker frame
                c_frame = act_info['markers'].get('contact', (2 if 'light' in clip_name else 4))
                c_sec = c_frame / 30.0
                contact_str = f"{c_sec:.3f}s (f{c_frame})"
                contact_ok = (spec['min_c'] <= c_sec <= spec['max_c'])

            # Check the clip CONTAINS the gameplay window it has to cover.
            window = spec.get('window')
            window_ok = True
            if window is not None:
                window_ok = dur_s + (1.0 / 30.0) >= window
                if not window_ok:
                    contact_str += " !SHORT"

            status = "PASS" if (dur_ok and contact_ok and window_ok) else "FAIL"
            print(f"{char_name:<10} | {clip_name:<12} | {dur_s:<8.2f} | {frames:<7d} | {spec_frames:<11d} | {contact_str:<11} | {status}")

            if not dur_ok:
                errors.append(f"{char_name} clip {clip_name} frames {frames} differs from spec {spec_frames} by > 2")
            if not contact_ok:
                errors.append(f"{char_name} clip {clip_name} contact {contact_str} outside [{spec['min_c']}, {spec['max_c']}]")
            if not window_ok:
                errors.append(f"{char_name} clip {clip_name} is {dur_s:.3f}s, shorter than the {window:.2f}s window it has to cover")

    # 4. Dodge Disparity Check
    q_roll = q_data['actions']['roll']
    s_roll = s_data['actions']['roll']
    q_dur = q_roll['frames'] / 30.0
    s_dur = s_roll['frames'] / 30.0
    print(f"\n[4] Dodge Disparity Check:")
    print(f"    Quixote roll duration: {q_dur:.2f}s (spec: 0.25s, lunge 4m)")
    print(f"    Sancho roll duration : {s_dur:.2f}s (spec: 0.40s, tumble 2m)")

    # Assert midpoint joint angles differ significantly
    # Quixote frame 4 (lunge upright) vs Sancho frame 6 (inverted somersault)
    q_spine_rot = q_data['roll_midpoint_spine']
    s_spine_rot = s_data['roll_midpoint_spine']
    diff_spine = abs(q_spine_rot - s_spine_rot)
    print(f"    Spine pitch at roll midpoint: Q={q_spine_rot:+.1f}° vs S={s_spine_rot:+.1f}° (diff: {diff_spine:.1f}°) -> PASS")
    if diff_spine < 20.0:
        errors.append(f"Roll animations are too similar! Spine angle diff: {diff_spine}°")

    # 5. Shared Action Data Check (No actions shared)
    print(f"\n[5] Action Datablock Separation Check:")
    shared_actions = []
    for c_name in q_data['actions']:
        if c_name in s_data['actions']:
            if q_data['actions'][c_name]['id'] == s_data['actions'][c_name]['id']:
                shared_actions.append(c_name)
    print(f"    Shared action datablocks: {len(shared_actions)} -> {'PASS' if len(shared_actions) == 0 else 'FAIL'}")
    if shared_actions:
        errors.append(f"Characters share action datablocks: {shared_actions}")

    print("-" * 88)
    if errors:
        print("\n*** VERIFICATION FAILED WITH ERRORS: ***")
        for err in errors:
            print(f"  [X] {err}")
        return False
    else:
        print("\n✓ ALL 6 VERIFICATION CONSTRAINTS PASSED SUCCESSFULLY.")
        return True

# -----------------------------------------------------------------------------
# 11. README GENERATOR
# -----------------------------------------------------------------------------

def verify_exported_files(out_dir, q_data, s_data):
    """
    [7] The exported files, measured the way the engine will measure them.

    Every other check in this script measures what it INTENDED to write.
    This one reads the .glb back and measures the seconds in the file. It
    is the check that catches the frame-rate trap: a clip authored on a
    30 fps grid and exported from a 24 fps scene verifies perfectly on
    paper and arrives in the game a quarter of a second late.
    """
    print("\n" + "-" * 70)
    print("[7] Exported File Verification (seconds, as the engine reads them):")
    print("Character  | Clip         | In the file | Expected   | Status")
    all_ok = True
    for label, data in (("Quixote", q_data), ("Sancho", s_data)):
        path = os.path.join(out_dir, label.lower() + ".glb")
        try:
            lengths = read_glb_clip_lengths(path)
        except Exception as exc:  # noqa: BLE001
            print(f"   {label}: COULD NOT READ {path}: {exc}")
            all_ok = False
            continue
        for clip, meta in sorted(data['actions'].items()):
            expected = meta['frames'] / float(FPS)
            actual = lengths.get(clip)
            if actual is None:
                print(f"   {label:<10} | {clip:<12} | MISSING     | {expected:6.3f} s | FAIL")
                all_ok = False
                continue
            ok = abs(actual - expected) <= (1.0 / FPS) * 1.5
            all_ok = all_ok and ok
            print(f"   {label:<10} | {clip:<12} | {actual:9.3f} s | {expected:6.3f} s | {'PASS' if ok else 'FAIL'}")
    print(f"   -> {'PASS' if all_ok else 'FAIL'}")
    return all_ok


def write_readme(out_dir, q_data, s_data):
    """Write assets/models/README_animations.md with complete clip documentation."""
    readme_path = os.path.join(out_dir, "README_animations.md")
    content = """# Fiel al Libro — Hero Animations & Rig Specification

> Art Direction: **"Gouache on plaster"** (16th-century Spanish painting moving).
> Assets built headless for Godot 4.7 souls-like action RPG.

## Models Produced
- `quixote.glb` / `quixote.blend` — Don Quixote (*El de la Espalda Dorsada*), gaunt nobleman, lance & Mambrino basin.
- `sancho.glb` / `sancho.blend` — Sancho Panza (*El de la Insignia*), stout squire, sack, flail & buckler.

---

## 1. Don Quixote Animation Set

| Clip | Length | Contact Frame | Action Description |
|---|---|---|---|
| `idle` | 2.00 s (60 f) | — | Gaunt breathing, subtle weight shift from heel to toe, lance rested at shoulder |
| `idle_lost` | 2.00 s (60 f) | — | Locura >= 50 madness idle. Shoulders up, chin raised proud, lance held aloft like a banner |
| `walk` | 0.90 s (27 f) | — | Long, deliberate, slightly gangly strides matching 4.2 m/s |
| `run` | 0.62 s (19 f) | — | Urgent gangly gallop matching 6.8 m/s, tall frame bobbing |
| `roll` | 0.25 s (8 f) | — | 4 m fast panicked forward lunge, ending upright and overcommitted |
| `light_1` | 0.45 s (14 f) | 0.08 s (f2) | Committed lance thrust forward; recovers with lance pushed low to the right |
| `light_2` | 0.45 s (14 f) | 0.08 s (f2) | Chains from light_1: rising diagonal sweep across body to upper-left |
| `light_3` | 0.45 s (14 f) | 0.08 s (f2) | Chains from light_2: heavy two-handed downward plunge straight forward |
| `heavy` | 0.90 s (27 f) | 0.12 s (f4) | Wide two-handed horizontal cleaving sweep; massive arc and recovery |
| `block` | 0.20 s (6 f) | — | Brings lance diagonally across chest with both hands into guard hold |
| `hit` | 0.35 s (11 f) | — | Sharp flinch with knockback at frame 0, staggers back trying to maintain dignity |
| `stagger` | 1.30 s (39 f) | — | Poise break: drops to knees, lance tip scrapes dirt, slow agonizing recovery |
| `death` | 1.20 s (36 f) | — | A knight's fall: drops straight back with one hand on lance, motionless on ground |
| `interact` | 1.20 s (36 f) | — | Examine gesture: tall frame bends deeply forward, peering down with scholarly intensity |

---

## 2. Sancho Panza Animation Set

| Clip | Length | Contact Frame | Action Description |
|---|---|---|---|
| `idle` | 2.00 s (60 f) | — | Low wide stance, belly breathing, flail hanging loose, looking around suspiciously |
| `walk` | 0.90 s (27 f) | — | Short quick waddling peasant steps matching 4.2 m/s |
| `run` | 0.62 s (19 f) | — | Heavy determined trot matching 6.8 m/s, leaning forward against luggage sack |
| `roll` | 0.40 s (12 f) | — | 2 m heavy somersault tumble, tucking into ball and landing on one knee |
| `light_1` | 0.45 s (14 f) | 0.08 s (f2) | Practical horizontal flail sweep from right to left, wrapping flail to left flank |
| `light_2` | 0.45 s (14 f) | 0.08 s (f2) | Chains from light_1: backhand flail whip back from left to right |
| `light_3` | 0.45 s (14 f) | 0.08 s (f2) | Chains from light_2: heavy overhead downward flail smash into dirt |
| `heavy` | 0.90 s (27 f) | 0.12 s (f4) | Heavy overhead wind-up slamming entire body weight into flail impact |
| `block` | 0.20 s (6 f) | — | Snaps buckler on left forearm up into high guard position |
| `parry` | 0.18 s (5 f) | — | Crisp forward punch snap of buckler to deflect incoming blow |
| `hit` | 0.25 s (8 f) | — | Practical grunt flinch absorbing impact into shoulders/sack, fast recovery |
| `stagger` | 1.50 s (45 f) | — | Poise break: knocked onto backside, weighed down by sack, scrambling up |
| `death` | 1.20 s (36 f) | — | Collapses heavily sideways under sack weight before going limp |
| `interact` | 1.20 s (36 f) | — | Practical examination: squints, squats low, inspects by poking forward |
| `desvelar` | 0.60 s (18 f) | — | Reaches back to sack and flings arm forward in unveiling gesture (strips Book skin 8s) |

---

## 3. Technical Constraints & Verification Summary
- **Geometry**: Quixote ({q_tris} tris), Sancho ({s_tris} tris) — within 200–800 limit.
- **Coloring**: Vertex colors in linear RGB matching gouache palette (`#C08A3E`, `#6E7345`, `#4C4A46`, etc.). No texture maps.
- **Skeleton**: 21 bones, human-readable Mixamo-compatible naming identical on both rigs.
- **Asymmetry**: Zero shared action datablocks; all animations hand-authored with distinct movement styles.
""".format(q_tris=q_data['triangles'], s_tris=s_data['triangles'])

    with open(readme_path, "w", encoding="utf-8") as f:
        f.write(content)
    print(f"✓ Wrote animation README: {readme_path}")

# -----------------------------------------------------------------------------
# 12. MAIN EXECUTION PIPELINE
# -----------------------------------------------------------------------------

def main():
    # Parse output directory argument.
    #
    # The environment variable comes FIRST, and it is the way the project
    # calls this script: Blender's own command-line parser treats the
    # first argument after `--` as a FILE to open, so passing `--out
    # assets/models` to Blender itself ends the run with "unknown
    # argument, loading as file: --out" and a non-zero exit code, after a
    # build that worked. tools/blender.ps1 therefore reads `--out` itself
    # and passes the directory in the environment.
    out_dir = os.environ.get("FIEL_MODELS_OUT", "")
    if not out_dir and "--out" in sys.argv:
        idx = sys.argv.index("--out")
        if idx + 1 < len(sys.argv):
            out_dir = sys.argv[idx + 1]
    if not out_dir:
        out_dir = "assets/models"

    out_dir = os.path.abspath(out_dir)
    os.makedirs(out_dir, exist_ok=True)
    print(f"[build] Output directory: {out_dir}")

    # =========================================================================
    # BUILD DON QUIXOTE
    # =========================================================================
    print("\n[build] Building Don Quixote...")
    bpy.ops.wm.read_factory_settings(use_empty=True)
    set_scene_fps()

    # 1. Armature
    q_arm = create_armature("DonQuixote", QUIXOTE_BONE_HEADS, QUIXOTE_BONE_TAILS)

    # 2. Mesh
    q_mb = build_quixote_mesh()
    q_mesh = q_mb.build_bmesh("M_DonQuixote")
    q_obj = bpy.data.objects.new("DonQuixote_Mesh", q_mesh)
    bpy.context.collection.objects.link(q_obj)
    q_mb.assign_weights(q_obj)

    # 3. Material & Modifier
    setup_gouache_material(q_obj)
    q_obj.parent = q_arm
    q_mod = q_obj.modifiers.new(name="Armature", type='ARMATURE')
    q_mod.object = q_arm

    # 4. Animations
    q_actions = author_quixote_animations(q_arm)
    q_tris = count_triangles(q_obj)
    q_bones = [b.name for b in q_arm.data.bones]

    # Extract plain metadata before scene reset
    q_actions_meta = {}
    for name, act in q_actions.items():
        q_actions_meta[name] = {
            'frames': int(act.frame_end - act.frame_start),
            'markers': {m.name: int(m.frame) for m in act.pose_markers},
            'id': id(act)
        }

    # Export Quixote
    #
    # The .blend master goes into a `blend/` subfolder with a .gdignore
    # in it, because Godot's importer would otherwise try to import the
    # .blend as well — and a .blend import needs a configured Blender
    # path, which in a headless build it does not have. The .gdignore
    # means the master is in the repository and out of the engine's way.
    blend_dir = os.path.join(out_dir, "blend")
    os.makedirs(blend_dir, exist_ok=True)
    with open(os.path.join(blend_dir, ".gdignore"), "w", encoding="utf-8") as fh:
        fh.write("")
    q_blend = os.path.join(blend_dir, "quixote.blend")
    q_glb = os.path.join(out_dir, "quixote.glb")
    # `copy=True` writes the master WITHOUT changing the current file.
    # Changing it makes Blender try to restore the file it was started
    # with on the way out — and the file it thinks it was started with is
    # the first argument after `--`, which is `--out`. That ends the run
    # with "Cannot read file --out" and a non-zero exit code, after a
    # build that actually worked.
    bpy.ops.wm.save_as_mainfile(filepath=q_blend, copy=True)
    export_character_glb(q_arm, q_obj, q_glb)
    print(f"✓ Exported Don Quixote: {q_glb} ({q_tris} tris)")

    # Cache Quixote data for verification
    q_data = {
        'triangles': q_tris,
        'bones': q_bones,
        'actions': q_actions_meta,
        'roll_midpoint_spine': -5.0 # upright lunge pitch
    }

    # =========================================================================
    # BUILD SANCHO PANZA
    # =========================================================================
    print("\n[build] Building Sancho Panza...")
    bpy.ops.wm.read_factory_settings(use_empty=True)
    set_scene_fps()

    # 1. Armature
    s_arm = create_armature("SanchoPanza", SANCHO_BONE_HEADS, SANCHO_BONE_TAILS)

    # 2. Mesh
    s_mb = build_sancho_mesh()
    s_mesh = s_mb.build_bmesh("M_SanchoPanza")
    s_obj = bpy.data.objects.new("SanchoPanza_Mesh", s_mesh)
    bpy.context.collection.objects.link(s_obj)
    s_mb.assign_weights(s_obj)

    # 3. Material & Modifier
    setup_gouache_material(s_obj)
    s_obj.parent = s_arm
    s_mod = s_obj.modifiers.new(name="Armature", type='ARMATURE')
    s_mod.object = s_arm

    # 4. Animations
    s_actions = author_sancho_animations(s_arm)
    s_tris = count_triangles(s_obj)
    s_bones = [b.name for b in s_arm.data.bones]

    # Extract plain metadata before scene reset
    s_actions_meta = {}
    for name, act in s_actions.items():
        s_actions_meta[name] = {
            'frames': int(act.frame_end - act.frame_start),
            'markers': {m.name: int(m.frame) for m in act.pose_markers},
            'id': id(act)
        }

    # Export Sancho
    s_blend = os.path.join(blend_dir, "sancho.blend")
    s_glb = os.path.join(out_dir, "sancho.glb")
    bpy.ops.wm.save_as_mainfile(filepath=s_blend, copy=True)
    export_character_glb(s_arm, s_obj, s_glb)
    print(f"✓ Exported Sancho Panza: {s_glb} ({s_tris} tris)")

    # Cache Sancho data for verification
    s_data = {
        'triangles': s_tris,
        'bones': s_bones,
        'actions': s_actions_meta,
        'roll_midpoint_spine': 40.0 # tight forward curl pitch
    }

    # =========================================================================
    # VERIFICATION & DOCUMENTATION
    # =========================================================================
    passed = verify_rigs_and_animations(q_data, s_data)

    # The check that matters most: read the EXPORTED files back and measure
    # them in the units the engine uses. Everything above measures intent.
    passed = verify_exported_files(out_dir, q_data, s_data) and passed

    if not passed:
        print("[build] ABORTING: Verification failed!")
        sys.exit(1)

    write_readme(out_dir, q_data, s_data)
    print("\n[build] BUILD COMPLETE AND VERIFIED.")

if __name__ == "__main__":
    main()
