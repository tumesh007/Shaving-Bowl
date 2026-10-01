import trimesh
import numpy as np

def run():
    stl_path = '/home/pnb/repos/Shaving-Bowl/travel_shaving_bowl.stl'
    print(f"Loading {stl_path}...")
    mesh = trimesh.load(stl_path)
    if isinstance(mesh, trimesh.Scene):
        mesh = mesh.dump(concatenate=True)

    print("\n================ 1. Topology & Mesh Closure ================")
    split = mesh.split(only_watertight=False)
    comp_count = len(split)
    watertight = mesh.is_watertight
    bounds = mesh.bounds
    bbox_h = bounds[1][2] - bounds[0][2]
    print(f"Watertight: {watertight}")
    print(f"Connected components: {comp_count}")
    print(f"Vertices: {len(mesh.vertices):,}")
    print(f"Faces: {len(mesh.faces):,}")
    print(f"Bounding box: {np.round(bounds, 3).tolist()}")
    print(f"Bounding box height: {bbox_h:.3f} mm")

    print("\n================ 2. Overhang Analysis (nz < -0.72, z > 0.5) ================")
    normals = mesh.face_normals
    areas = mesh.area_faces
    centers = mesh.triangles_center

    # Exclude bed contact (centers[:, 2] <= 0.5)
    mask = (normals[:, 2] < -0.72) & (centers[:, 2] > 0.5)
    total_overhang = float(np.sum(areas[mask]))
    print(f"Total overhang area (steeper than ~46 deg): {total_overhang:.2f} mm2 (target <= 2000 mm2: {total_overhang <= 2000.0})")

    submesh = mesh.submesh([mask], append=True)
    if not submesh.is_empty:
        clusters = submesh.split(only_watertight=False)
        clusters.sort(key=lambda x: x.area, reverse=True)
        print(f"Total clusters: {len(clusters)}")
        print("Top 8 clusters:")
        for i in range(min(len(clusters), 8)):
            c = clusters[i]
            cntr = np.round(c.centroid, 2).tolist()
            bnds = np.round(c.bounds, 2).tolist()
            is_drawer = (c.area > 500) and (abs(c.centroid[2] - 10.7) < 1.0)
            note = " [Drawer ceiling bridge]" if is_drawer else ""
            print(f"  Cluster {i+1}: area = {c.area:8.2f} mm2 | center = {cntr} | z-span = [{bnds[0][2]:.2f}, {bnds[1][2]:.2f}]{note}")
        
        above_500 = [c for c in clusters if c.area > 500]
        print(f"\nClusters above 500 mm2: {len(above_500)}")
        for c in above_500:
            print(f"  Area: {c.area:.2f} mm2, Center: {np.round(c.centroid, 2).tolist()}, z-span: [{c.bounds[0][2]:.2f}, {c.bounds[1][2]:.2f}]")

    print("\n================ 3. Bowl Footprint Radius at z = 0.3 mm ================")
    section = mesh.section(plane_origin=[0, 0, 0.3], plane_normal=[0, 0, 1])
    if section is not None:
        pts = section.vertices[:, :2]
        # Filter points belonging to the circular bowl base (r < 32)
        base_pts = pts[np.linalg.norm(pts, axis=1) < 32.0]
        radii = np.linalg.norm(base_pts, axis=1)
        r_min = float(np.min(radii))
        r_mean = float(np.mean(radii))
        r_max = float(np.max(radii))
        print(f"Footprint radius at z=0.3 mm: min = {r_min:.3f} mm, mean = {r_mean:.3f} mm, max = {r_max:.3f} mm")
        print(f"Requirement (radius >= 20 mm): min radius {r_min:.3f} mm >= 20.0: {r_min >= 20.0}")

    print("\n================ 4. Shaft Clearance (t=3..21 mm) ================")
    outer_radius = 84.0 / 2.0
    bowl_inner_diameter = 73.7
    bowl_height = 38.5
    dock_raise = 8.0

    dock_origin = np.array([outer_radius + 2.0, 0.0, bowl_height - 1.0 + dock_raise])
    theta = np.radians(90 - 25)
    axis_dir = np.array([np.sin(theta), 0.0, np.cos(theta)])

    t_min, t_max = 3.0, 21.0
    h = t_max - t_min

    for r_shaft in [5.4, 5.8, 6.0, 6.5, 7.0, 7.5]:
        cyl = trimesh.creation.cylinder(radius=r_shaft, height=h, sections=72)
        center = dock_origin + axis_dir * (t_min + h / 2.0)
        rot_mat = trimesh.geometry.align_vectors([0, 0, 1], axis_dir)
        transform = np.eye(4)
        transform[:3, :3] = rot_mat[:3, :3]
        transform[:3, 3] = center
        cyl.apply_transform(transform)

        cyl_vol = np.pi * (r_shaft**2) * h
        inter = trimesh.boolean.intersection([mesh, cyl], engine='manifold')
        inter_vol = float(inter.volume) if (inter and inter.is_volume) else 0.0
        pct = (inter_vol / cyl_vol) * 100.0 if cyl_vol > 0 else 0
        status = "PASS" if (r_shaft in [5.4, 5.8] and inter_vol == 0.0) else ("REPORT ONLY" if r_shaft > 5.8 else "FAIL")
        print(f"  Radius {r_shaft:.1f} mm (dia {2*r_shaft:.1f} mm): vol = {inter_vol:.6f} mm3 ({pct:.4f}%) [{status}]")

    print("\n================ 5. Inner Floor Profile (z at r = 0, 5, 8, 11, 15, 20, 25 mm) ================")
    radii_to_check = [0, 5, 8, 11, 15, 20, 25]
    print("Along X-axis (y=0):")
    for r in radii_to_check:
        locs, _, _ = mesh.ray.intersects_location(np.array([[r, 0.0, 50.0]]), np.array([[0.0, 0.0, -1.0]]))
        hits = locs[locs[:, 2] < 38.0]
        z_val = float(np.max(hits[:, 2])) if len(hits) > 0 else 0.0
        print(f"  r = {r:2d} mm: z = {z_val:.3f} mm")

    print("\n================ 6. Thinnest Wall with Texture ================")
    # Parametric inner surface sampling (outer_radius minus distance to sphere center [0, 0, bowl_height])
    def smoothstep(edge0, edge1, value):
        t = np.clip((value - edge0) / (edge1 - edge0), 0.0, 1.0)
        return t * t * (3.0 - 2.0 * t)

    def fract(v): return v - np.floor(v)
    texture_seed = 4217
    feature_spread = 22.0
    def rand01(k): return fract(np.sin((k + texture_seed * 17.0) * 127.1 + 311.7) * 43758.5453123)
    def feature_coord(i, salt): return (rand01(i * 13.7 + salt) * 2.0 - 1.0) * feature_spread
    def make_feature(i, salt, rmin, rmax, amin, amax):
        return [feature_coord(i, salt), feature_coord(i, salt + 101.0),
                rmin + rand01(i * 7.3 + salt + 207.0) * (rmax - rmin),
                amin + rand01(i * 11.9 + salt + 419.0) * (amax - amin)]

    macro_hill_features = [make_feature(i, 37.0, 7.0, 10.0, 0.18, 0.32) for i in range(8)]
    macro_valley_features = [make_feature(i, 211.0, 7.0, 10.0, -0.48, -0.28) for i in range(6)]
    deep_valley_features = [make_feature(i, 503.0, 7.5, 9.5, -1.15, -0.95) for i in range(2)]
    local_hill_features = [make_feature(i, 809.0, 4.0, 6.0, 0.08, 0.15) for i in range(5)]
    local_valley_features = [make_feature(i, 1103.0, 4.0, 6.0, -0.18, -0.10) for i in range(5)]

    def feature_sum(features, x, y):
        tot = np.zeros_like(x, dtype=float)
        for f in features:
            dx, dy, sigma = x - f[0], y - f[1], f[2]
            tot += f[3] * np.exp(-(dx*dx + dy*dy) / (2.0 * sigma * sigma))
        return tot

    def diamond_texture(x, y):
        u, v = (x + y) * 0.70710678, (x - y) * 0.70710678
        pitch_u, pitch_v = 10.0, 7.0
        row = np.floor(v / pitch_v + 0.5)
        v_local = (v - row * pitch_v) / (pitch_v / 2.0)
        u_staggered = u - 0.12 * pitch_u * np.cos(np.radians(180.0 * v / pitch_v))
        u_local = (u_staggered - pitch_u * np.floor(u_staggered / pitch_u + 0.5)) / (pitch_u / 2.0)
        diamond_radius = np.abs(u_local) + np.abs(v_local)
        rounded_diamond = 1.0 - smoothstep(0.72, 1.12, diamond_radius)
        variation = 1.0 + 0.04 * np.sin((u + v) * 10.0 + texture_seed)
        return variation * (1.15 * rounded_diamond - 0.65 * (1.0 - rounded_diamond))

    def combined_texture(x, y):
        r = np.sqrt(x*x + y*y)
        fade = 1.0 - smoothstep(36.85 - 5.5, 36.85, r)
        macro = (0.045 * np.sin(x * 5.0 + texture_seed) + 0.04 * np.cos(y * 5.4 - texture_seed * 0.7) + 0.03 * np.sin((x + y) * 3.6))
        raw = fade * (macro + diamond_texture(x, y) + 0.35 * feature_sum(macro_hill_features, x, y)
                      + 0.45 * feature_sum(macro_valley_features, x, y) + 0.4 * feature_sum(deep_valley_features, x, y)
                      + feature_sum(local_hill_features, x, y) + feature_sum(local_valley_features, x, y)
                      - 0.14 * np.exp(-((y - 1.5 * np.sin(x*8.0 + texture_seed))**2) / 24.0)
                      - 0.12 * np.exp(-((x - 1.5 * np.sin(y*7.0 - texture_seed*0.61))**2) / 26.0)
                      + 0.025 * np.sin(x*15.0 + y*11.0 + texture_seed) + 0.02 * np.cos(x*9.0 - y*13.0 + texture_seed*0.41))
        return np.where(r >= 36.85, 0.0, np.clip(raw, -3.2, 1.3))

    def inner_z(r, x, y):
        sz = bowl_height - np.sqrt(np.maximum(0.0, 36.85**2 - np.minimum(r, 36.85)**2))
        base = 3.5 + smoothstep(8.0, 15.0, r) * (sz - 3.5)
        return np.maximum(3.5, base + combined_texture(x, y))

    xs = np.linspace(-36.85, 36.85, 400)
    xx, yy = np.meshgrid(xs, xs)
    rr = np.hypot(xx, yy)
    vld = rr <= 36.85
    xv, yv, rv = xx[vld], yy[vld], rr[vld]
    zv = inner_z(rv, xv, yv)
    dists = np.sqrt(xv*xv + yv*yv + (zv - bowl_height)**2)
    min_wall = float(np.min(outer_radius - dists))
    print(f"Thinnest wall with texture: {min_wall:.3f} mm (requirement >= 3.5 mm: {min_wall >= 3.5})")

if __name__ == '__main__':
    run()
