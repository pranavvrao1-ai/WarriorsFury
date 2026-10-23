import math
import struct
import json
import os
from pathlib import Path
import pygame

from game.settings import BASE_DIR, CHARACTERS_DIR, ROBOT_DIR, SPEAKER_COLORS, WHITE, GREY


class Model3D:
    """Stores normalized 3D mesh geometry loaded from GLB or OBJ files."""

    def __init__(self, vertices, edges=None, faces=None):
        self.vertices = vertices  # list of (x, y, z)
        self.edges = edges or []
        self.faces = faces or []

    @classmethod
    def load_from_glb(cls, file_path, max_points=1200):
        """Loads and normalizes 3D vertex and edge geometry from a .glb file."""
        if not Path(file_path).exists():
            return None

        try:
            with open(file_path, "rb") as f:
                magic, ver, length = struct.unpack("<4sII", f.read(12))
                chunk_len, chunk_type = struct.unpack("<I4s", f.read(8))
                gltf_json = json.loads(f.read(chunk_len).decode("utf-8"))
                chunk2_len, chunk2_type = struct.unpack("<I4s", f.read(8))
                bin_data = f.read(chunk2_len)

            accessors = gltf_json.get("accessors", [])
            buffer_views = gltf_json.get("bufferViews", [])

            raw_pts = []
            for m in gltf_json.get("meshes", []):
                for p in m.get("primitives", []):
                    pos_idx = p.get("attributes", {}).get("POSITION")
                    if pos_idx is not None:
                        acc = accessors[pos_idx]
                        bv = buffer_views[acc["bufferView"]]
                        offset = bv.get("byteOffset", 0) + acc.get("byteOffset", 0)
                        count = acc["count"]
                        fmt = f"<{count * 3}f"
                        coords = struct.unpack_from(fmt, bin_data, offset)
                        step = max(1, count // (max_points // max(1, len(gltf_json.get("meshes", [])))))
                        for i in range(0, count, step):
                            raw_pts.append((coords[i * 3], coords[i * 3 + 1], coords[i * 3 + 2]))

            if not raw_pts:
                return None

            # Compute bounding box and normalize to [-1, 1]
            xs = [p[0] for p in raw_pts]
            ys = [p[1] for p in raw_pts]
            zs = [p[2] for p in raw_pts]
            min_x, max_x = min(xs), max(xs)
            min_y, max_y = min(ys), max(ys)
            min_z, max_z = min(zs), max(zs)
            center = ((min_x + max_x) / 2, (min_y + max_y) / 2, (min_z + max_z) / 2)
            max_extent = max(max_x - min_x, max_y - min_y, max_z - min_z, 0.0001) / 2

            norm_pts = [
                ((p[0] - center[0]) / max_extent,
                 (p[1] - center[1]) / max_extent,
                 (p[2] - center[2]) / max_extent)
                for p in raw_pts
            ]

            # Generate synthetic wireframe edges between neighboring points
            edges = []
            for i in range(0, len(norm_pts) - 1, 2):
                edges.append((i, i + 1))

            return cls(norm_pts, edges=edges)

        except Exception as e:
            print(f"[3D] Error loading {file_path}: {e}")
            return None

    @classmethod
    def load_from_obj(cls, file_path, max_verts=1500):
        """Loads and normalizes 3D vertices and wireframe edges from an .obj file."""
        if not Path(file_path).exists():
            return None

        try:
            raw_pts = []
            edges = []
            with open(file_path, "r", encoding="utf-8", errors="ignore") as f:
                for line in f:
                    if line.startswith("v "):
                        parts = line.strip().split()
                        raw_pts.append((float(parts[1]), float(parts[2]), float(parts[3])))
                    elif line.startswith("f ") and len(raw_pts) < max_verts:
                        parts = line.strip().split()[1:]
                        indices = []
                        for p in parts:
                            idx_str = p.split("/")[0]
                            if idx_str:
                                idx = int(idx_str) - 1
                                if 0 <= idx < len(raw_pts):
                                    indices.append(idx)
                        for i in range(len(indices)):
                            edges.append((indices[i], indices[(i + 1) % len(indices)]))

            if not raw_pts:
                return None

            xs = [p[0] for p in raw_pts]
            ys = [p[1] for p in raw_pts]
            zs = [p[2] for p in raw_pts]
            min_x, max_x = min(xs), max(xs)
            min_y, max_y = min(ys), max(ys)
            min_z, max_z = min(zs), max(zs)
            center = ((min_x + max_x) / 2, (min_y + max_y) / 2, (min_z + max_z) / 2)
            max_extent = max(max_x - min_x, max_y - min_y, max_z - min_z, 0.0001) / 2

            norm_pts = [
                ((p[0] - center[0]) / max_extent,
                 (p[1] - center[1]) / max_extent,
                 (p[2] - center[2]) / max_extent)
                for p in raw_pts[:max_verts]
            ]

            return cls(norm_pts, edges=edges[:max_verts * 2])

        except Exception as e:
            print(f"[3D] Error loading obj {file_path}: {e}")
            return None

    def render_projected(self, screen, cx, cy, scale, yaw, pitch=0.0, roll=0.0, color=(0, 230, 255), point_size=2):
        """Projects and renders the 3D model with lighting and perspective."""
        cos_y, sin_y = math.cos(yaw), math.sin(yaw)
        cos_p, sin_p = math.cos(pitch), math.sin(pitch)

        dist = 3.2
        proj_pts = []
        for x, y, z in self.vertices:
            # Rotate Y (yaw)
            xz = x * cos_y + z * sin_y
            zz = -x * sin_y + z * cos_y
            # Rotate X (pitch)
            yz = y * cos_p - zz * sin_p
            zf = y * sin_p + zz * cos_p

            factor = scale / (zf + dist)
            px = int(cx + xz * factor)
            py = int(cy - yz * factor)
            depth = zf
            proj_pts.append((px, py, depth))

        # Draw wireframe edges
        dim_color = (max(0, color[0] // 3), max(0, color[1] // 3), max(0, color[2] // 3))
        for i1, i2 in self.edges:
            if i1 < len(proj_pts) and i2 < len(proj_pts):
                p1, p2 = proj_pts[i1], proj_pts[i2]
                if p1[2] > -2.0 and p2[2] > -2.0:
                    pygame.draw.line(screen, dim_color, (p1[0], p1[1]), (p2[0], p2[1]), 1)

        # Draw vertices with depth shading
        for px, py, depth in proj_pts:
            if depth > -2.0:
                bright = max(0.3, min(1.0, (depth + 1.2) / 2.0))
                c = (int(color[0] * bright), int(color[1] * bright), int(color[2] * bright))
                if point_size <= 1:
                    screen.set_at((px, py), c)
                else:
                    pygame.draw.circle(screen, c, (px, py), point_size)


class ModelLibrary:
    """Loads and caches all user uploaded 3D character and robot models."""

    def __init__(self):
        self._models = {}
        self._load_all()

    def _load_all(self):
        # 1. MC Protagonist
        p_mc = CHARACTERS_DIR / "male1.glb"
        self._models["mc"] = Model3D.load_from_glb(p_mc, max_points=1400)

        # 2. Unknown Figure (with glasses)
        p_unk = CHARACTERS_DIR / "male3.glb"
        self._models["unknown"] = Model3D.load_from_glb(p_unk, max_points=1400)

        # 3. Receptionist
        p_rec = CHARACTERS_DIR / "female4.glb"
        self._models["receptionist"] = Model3D.load_from_glb(p_rec, max_points=1400)

        # 4. Shopkeeper
        p_sk = CHARACTERS_DIR / "male4.glb"
        self._models["shopkeeper"] = Model3D.load_from_glb(p_sk, max_points=1200)

        # 5. Robot Unit / NEXUS
        p_rob = ROBOT_DIR / "robot_police_unit_animated.glb"
        self._models["robot"] = Model3D.load_from_glb(p_rob, max_points=1800)

        # 6. Cyberpunk Robot
        p_cyb = ROBOT_DIR / "Cyberpunk Robot.obj"
        if p_cyb.exists():
            self._models["cyber_robot"] = Model3D.load_from_obj(p_cyb, max_verts=1200)

        print("[3D Library] Loaded characters:", list(self._models.keys()))

    def get_model(self, name):
        return self._models.get(name)


models_3d = ModelLibrary()
