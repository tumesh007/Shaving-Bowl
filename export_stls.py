# Copyright (c) 2026 Tumesh (https://github.com/tumesh007)
# SPDX-License-Identifier: CC-BY-NC-SA-4.0
import subprocess
import os
import sys
import time
import shutil
import struct

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
SCAD_FILE = os.path.join(SCRIPT_DIR, "travel_shaving_bowl.scad")

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
                return [c]
    return ["openscad", "--backend=CGAL"]

def export_variant(preset_name, base_name):
    cmd_base = get_openscad_cmd()
    bin_name = f"{base_name}_bin.stl"
    asc_name = f"{base_name}.stl"
    out_bin = os.path.join(SCRIPT_DIR, bin_name)
    out_asc = os.path.join(SCRIPT_DIR, asc_name)

    print(f"Exporting {preset_name} to {bin_name}...")
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
        print(f"Successfully generated {bin_name} ({size_mb:.2f} MB) in {dt:.1f}s")
        # Generate ASCII counterpart
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
        print(f"Successfully generated {asc_name}")
    else:
        print(f"Failed to generate {bin_name}!")
        print("Stderr:", res.stderr)

if __name__ == "__main__":
    export_variant("standard", "Tumeshs_Shaving_Bowl_v14_STANDARD_norack")
    export_variant("travel", "Tumeshs_Shaving_Bowl_v14_TRAVEL_norack")
