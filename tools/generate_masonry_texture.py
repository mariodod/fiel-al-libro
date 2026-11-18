#!/usr/bin/env python3
"""Generate a 2K tileable gouache masonry texture for the Venture's tower.

No external dependencies: pure Python + zlib PNG writer. The result is a
seamlessly tiling 2048x2048 colour map of staggered, rough-cut ochre
limestone courses with wandering mortar joints, chipped corners, dry-brush
variation and paper tooth, in the game's palette.

Deterministic: re-running reproduces the same PNG byte for byte.
"""

from pathlib import Path
import math
import struct
import zlib

W = H = 2048
COURSE_H = 128
N_COURSES = H // COURSE_H

# Palette (docs/ART_BRIEF_VENTURE.md)
OCHRE = (192, 138, 62)
DARK_OCHRE = (138, 90, 40)
BONE = (232, 220, 192)
DIRTY_BONE = (201, 184, 150)
IRON = (76, 74, 70)
OLIVE = (110, 115, 69)

OUT = Path("assets/textures/windmill_masonry.png")


def mix(a, b, t):
    return tuple(a[i] + (b[i] - a[i]) * t for i in range(3))


def clamp8(v):
    return max(0, min(255, int(v)))


def hash2(x, y, seed=0):
    n = x * 374761393 + y * 668265263 + seed * 2246822519
    n = (n ^ (n >> 13)) * 1274126177
    return ((n ^ (n >> 16)) & 0xFFFFFFFF) / 4294967295.0


def make_grid(period, seed):
    return [[hash2(x, y, seed) for x in range(period)] for y in range(period)]


def sample(grid, u, v):
    p = len(grid)
    x, y = u * p, v * p
    x0, y0 = int(x) % p, int(y) % p
    x1, y1 = (x0 + 1) % p, (y0 + 1) % p
    fx, fy = x - math.floor(x), y - math.floor(y)
    fx, fy = fx * fx * (3 - 2 * fx), fy * fy * (3 - 2 * fy)
    a = grid[y0][x0] + (grid[y0][x1] - grid[y0][x0]) * fx
    b = grid[y1][x0] + (grid[y1][x1] - grid[y1][x0]) * fx
    return a + (b - a) * fy


def png_chunk(tag, data):
    return (
        struct.pack(">I", len(data))
        + tag
        + data
        + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
    )


def write_png(path, width, height, rows):
    raw = b"".join(b"\x00" + row for row in rows)
    ihdr = struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0)
    path.write_bytes(
        b"\x89PNG\r\n\x1a\n"
        + png_chunk(b"IHDR", ihdr)
        + png_chunk(b"IDAT", zlib.compress(raw, 9))
        + png_chunk(b"IEND", b"")
    )


def course_joints(course):
    """Joint x-positions for one course: varied widths that sum to W.

    Different widths per course give the stagger without a fixed half-offset.
    Because the widths are normalised to W, the pattern tiles horizontally.
    """
    n = 6 + int(hash2(course, 0, 13) * 4)  # 6..9 stones per course
    widths = [0.6 + hash2(course, i, 17) * 0.8 for i in range(n)]
    total = sum(widths)
    joints = [0.0]
    for w in widths[:-1]:
        joints.append(joints[-1] + W * w / total)
    return joints


def main():
    brush = make_grid(16, 11)
    tooth = make_grid(128, 29)
    joints_by_course = [course_joints(c) for c in range(N_COURSES)]

    # Per-stone colour, indexed by course and stone index.
    stone_tint = [
        [hash2(s, c, 7) for s in range(len(joints_by_course[c]))]
        for c in range(N_COURSES)
    ]

    rows = []
    for y in range(H):
        row = bytearray()
        course = y // COURSE_H
        dy = y % COURSE_H
        edge_v = min(dy, COURSE_H - dy)
        joints = joints_by_course[course]

        for x in range(W):
            u, v = x / W, y / H
            b = sample(brush, u, v)
            t = sample(tooth, u, v)
            grain = hash2(x, y, 3)

            # Nearest vertical joint in this course.
            k = 0
            while k < len(joints) - 1 and joints[k + 1] <= x:
                k += 1
            left = joints[k]
            right = joints[k + 1] if k + 1 < len(joints) else W
            edge_h = min(x - left, right - x)

            # Chipped corners: mortar eats an L into the stone at some joints.
            chip = hash2(k, course, 41) > 0.72
            corner = min(edge_v, edge_h)
            if chip and corner < 22.0 + (b - 0.5) * 18.0:
                edge_h = min(edge_h, corner * 0.45)

            mortar = (edge_v < 5.0 + (b - 0.5) * 3.0) or (
                edge_h < 4.0 + (t - 0.5) * 2.5
            )

            if mortar:
                col = mix(DARK_OCHRE, DIRTY_BONE, 0.22 + b * 0.32)
                col = mix(col, IRON, 0.14 * t)
            else:
                st = stone_tint[course][k % len(stone_tint[course])]
                col = mix(OCHRE, DIRTY_BONE, 0.08 + st * 0.55 + (b - 0.5) * 0.28)
                near = max(0.0, 1.0 - corner / 14.0)
                col = mix(col, DARK_OCHRE, 0.26 * near)
                if t > 0.94 and b < 0.45:
                    col = mix(col, OLIVE, 0.38)
                elif t < 0.035 and b > 0.62:
                    col = mix(col, IRON, 0.28)

            shade = 1.0 + (b - 0.5) * 0.18 + (t - 0.5) * 0.12 + (grain - 0.5) * 0.07
            row.extend(
                (
                    clamp8(col[0] * shade),
                    clamp8(col[1] * shade),
                    clamp8(col[2] * shade),
                )
            )

        rows.append(bytes(row))

    OUT.parent.mkdir(parents=True, exist_ok=True)
    write_png(OUT, W, H, rows)
    print(f"Wrote {OUT} ({W}x{H}, {OUT.stat().st_size} bytes)")


if __name__ == "__main__":
    main()
