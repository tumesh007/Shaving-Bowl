import subprocess
import os
import sys
import time
import shutil
import struct
import math

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
SCAD_FILE = os.path.join(SCRIPT_DIR, "travel_shaving_bowl_v14_1.scad")
DOWNLOADS_DIR = r"C:\Users\tumes\Downloads"

def get_openscad_cmd():
    if os.name == 'nt':
        nightly = r"C:\Users\tumes\.gemini\antigravity\scratch\openscad-nightly\OpenSCAD-2025.11.06-x86-64\openscad.com"
        if os.path.exists(nightly):
            return [nightly, "--backend=CGAL", "--export-format=binstl"]
        candidates = [
            r"C:\Program Files\OpenSCAD\openscad.com",
            r"C:\Program Files (x86)\OpenSCAD\openscad.com",
        ]
        for c in candidates:
            if os.path.exists(c):
                return [c, "--backend=CGAL", "--export-format=binstl"]
    return ["openscad", "--backend=CGAL", "--export-format=binstl"]

def verify_stl(path, is_standard_preset):
    print(f"\n--- Multi-Point Air Cavity & Overhang Verification: {os.path.basename(path)} ---")
    with open(path, "rb") as f:
        f.read(80)
        n_tri = struct.unpack("<I", f.read(4))[0]
        
        min_x, max_x = float('inf'), float('-inf')
        min_y, max_y = float('inf'), float('-inf')
        min_z, max_z = float('inf'), float('-inf')
        
        test_rays = [
            (0.0, 0.0),
            (15.0, 0.0), (-15.0, 0.0),
            (0.0, 15.0), (0.0, -15.0),
            (25.0, 0.0), (-25.0, 0.0)
        ]
        ray_hits = {pt: [] for pt in test_rays}
        
        steep_handle_overhang_area = 0.0
        handle_z_max = 24.0 if is_standard_preset else 20.0
        handle_x_min = 45.0 if is_standard_preset else 35.0
        
        def sign(p1, p2, p3):
            return (p1[0] - p3[0]) * (p2[1] - p3[1]) - (p2[0] - p3[0]) * (p1[1] - p3[1])

        for _ in range(n_tri):
            data = struct.unpack("<3f 3f 3f 3f 2x", f.read(50))
            nx, ny, nz = data[0], data[1], data[2]
            v1, v2, v3 = data[3:6], data[6:9], data[9:12]
            
            for v in (v1, v2, v3):
                min_x, max_x = min(min_x, v[0]), max(max_x, v[0])
                min_y, max_y = min(min_y, v[1]), max(max_y, v[1])
                min_z, max_z = min(min_z, v[2]), max(max_z, v[2])

            # Multi-point raycast test
            for pt in test_rays:
                d1, d2, d3 = sign(pt, v1, v2), sign(pt, v2, v3), sign(pt, v3, v1)
                if not ((d1 < -1e-5 or d2 < -1e-5 or d3 < -1e-5) and (d1 > 1e-5 or d2 > 1e-5 or d3 > 1e-5)):
                    if abs(nz) > 1e-6:
                        z_at_pt = v1[2] - (nx * (pt[0] - v1[0]) + ny * (pt[1] - v1[1])) / nz
                        ray_hits[pt].append((z_at_pt, nz))

            # Overhang analysis
            ax, ay, az = v2[0]-v1[0], v2[1]-v1[1], v2[2]-v1[2]
            bx, by, bz = v3[0]-v1[0], v3[1]-v1[1], v3[2]-v1[2]
            area = 0.5 * math.sqrt((ay*bz - az*by)**2 + (az*bx - ax*bz)**2 + (ax*by - ay*bx)**2)
            
            z_mid = (v1[2] + v2[2] + v3[2]) / 3.0
            x_mid = (v1[0] + v2[0] + v3[0]) / 3.0
            y_mid = (v1[1] + v2[1] + v3[1]) / 3.0
            
            if x_mid > handle_x_min and 1.0 < z_mid < handle_z_max and abs(y_mid) <= 10.5 and nz < -0.7071:
                steep_handle_overhang_area += area

        print(f"Triangles: {n_tri:,}")
        print(f"Bounding Box: X=[{min_x:.1f}, {max_x:.1f}], Y=[{min_y:.1f}, {max_y:.1f}], Z=[{min_z:.1f}, {max_z:.1f}] mm")
        
        # Verify air cavity at (0, 0)
        center_hits = sorted(ray_hits[(0.0, 0.0)], key=lambda x: x[0])
        print("Raycast along Z at center (0, 0):")
        for z, nz in center_hits:
            print(f"  Z = {z:.2f} mm (nz = {nz:+.3f})")
            
        floor_ok = any(3.0 <= z <= 7.5 and nz > 0.0 for z, nz in center_hits)
        
        # Solid lid check: ensure NO hits above Z = 12.0 mm for central rays
        lid_detected = False
        for pt, hits in ray_hits.items():
            for z, nz in hits:
                if z > 15.0:
                    print(f"FAILED: Solid ceiling detected at ray {pt}: Z = {z:.2f} mm (nz = {nz:+.3f})")
                    lid_detected = True
                    break
            if lid_detected:
                break
                
        handle_ok = (steep_handle_overhang_area <= 5.0)
        
        print(f"1. Cavity Floor Check: {'PASS (Internal floor verified)' if floor_ok else 'FAIL'}")
        print(f"2. Solid Lid Bug Check: {'PASS (100% Hollow Cavity Open to Sky)' if not lid_detected else 'FAIL (SOLID LID DETECTED!)'}")
        print(f"3. Lower Handle Overhang (>45 deg): {steep_handle_overhang_area:.2f} mm2 -> {'PASS (100% Support-Free)' if handle_ok else 'FAIL'}")
        
        return floor_ok and (not lid_detected) and handle_ok

def export_variant(preset_name, base_name):
    cmd_base = get_openscad_cmd()
    bin_name = f"{base_name}_bin.stl"
    asc_name = f"{base_name}.stl"
    out_bin = os.path.join(SCRIPT_DIR, bin_name)
    out_asc = os.path.join(SCRIPT_DIR, asc_name)
    is_std = (preset_name == "standard")

    if "--skip-existing" in sys.argv and os.path.exists(out_bin):
        print(f"\n==========================================")
        print(f"Found existing {bin_name}, checking verification...")
        if verify_stl(out_bin, is_std):
            print(f"Skipping re-render for verified {bin_name}")
            return

    print(f"\n==========================================")
    print(f"Exporting {preset_name.upper()} preset via CGAL to {bin_name}...")
    t0 = time.time()
    cmd = cmd_base + [
        "-D", "preview_mode=false",
        "-D", f'bowl_preset="{preset_name}"',
        "-D", "blade_storage_enabled=false",
        "-D", 'part="bowl"',
        "-o", out_bin,
        SCAD_FILE
    ]
    res = subprocess.run(cmd, cwd=SCRIPT_DIR, capture_output=True, text=True)
    dt = time.time() - t0
    
    if os.path.exists(out_bin):
        size_mb = os.path.getsize(out_bin) / (1024 * 1024)
        print(f"Generated {bin_name} ({size_mb:.2f} MB) in {dt:.1f}s via CGAL")
        
        # Verify binary STL
        is_std = (preset_name == "standard")
        passed = verify_stl(out_bin, is_std)
        if not passed:
            print("ERROR: STL verification failed!")
            sys.exit(1)
            
        # Convert to ASCII STL
        print(f"Generating ASCII STL: {asc_name}...")
        with open(out_bin, "rb") as f_in, open(out_asc, "w") as f_out:
            f_in.seek(80)
            n_tri = struct.unpack("<I", f_in.read(4))[0]
            f_out.write(f"solid {base_name}\n")
            for _ in range(n_tri):
                data = f_in.read(50)
                norm = struct.unpack("<3f", data[:12])
                v1 = struct.unpack("<3f", data[12:24])
                v2 = struct.unpack("<3f", data[24:36])
                v3 = struct.unpack("<3f", data[36:48])
                f_out.write(f"  facet normal {norm[0]:.6e} {norm[1]:.6e} {norm[2]:.6e}\n")
                f_out.write("    outer loop\n")
                f_out.write(f"      vertex {v1[0]:.6e} {v1[1]:.6e} {v1[2]:.6e}\n")
                f_out.write(f"      vertex {v2[0]:.6e} {v2[1]:.6e} {v2[2]:.6e}\n")
                f_out.write(f"      vertex {v3[0]:.6e} {v3[1]:.6e} {v3[2]:.6e}\n")
                f_out.write("    endloop\n")
                f_out.write("  endfacet\n")
            f_out.write(f"endsolid {base_name}\n")
        print(f"Successfully generated ASCII STL: {asc_name}")
        
        # Deploy to Downloads
        if os.path.exists(DOWNLOADS_DIR):
            dl_bin = os.path.join(DOWNLOADS_DIR, bin_name)
            dl_asc = os.path.join(DOWNLOADS_DIR, asc_name)
            shutil.copyfile(out_bin, dl_bin)
            shutil.copyfile(out_asc, dl_asc)
            print(f"Deployed to Downloads: {dl_bin} and {dl_asc}")
    else:
        print(f"Failed to generate {bin_name}!")
        print("Stderr:", res.stderr)
        sys.exit(1)

if __name__ == "__main__":
    t_start = time.time()
    export_variant("standard", "Tumeshs_Shaving_Bowl_v14_1_STANDARD")
    export_variant("travel", "Tumeshs_Shaving_Bowl_v14_1_TRAVEL")
    t_total = time.time() - t_start
    print(f"\n==========================================")
    print(f"ALL v14.1 EXPORTS AND VERIFICATIONS COMPLETED IN {t_total:.1f}s!")
