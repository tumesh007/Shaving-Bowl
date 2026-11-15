# Copyright (c) 2026 Tumesh (https://github.com/tumesh007)
# SPDX-License-Identifier: CC-BY-NC-SA-4.0
import subprocess
import os
import time

SCRIPT_DIR = r"C:\Users\tumes\.gemini\antigravity\scratch\shaving-bowl"
nightly = r"C:\Users\tumes\.gemini\antigravity\scratch\openscad-nightly\OpenSCAD-2025.11.06-x86-64\openscad.com"
scad = os.path.join(SCRIPT_DIR, "travel_shaving_bowl_v14_2.scad")
renders_dir = os.path.join(SCRIPT_DIR, "renders")

views = [
    {
        "file": "01-isometric.png",
        "camera": "16,0,25,60,0,35,280",
        "desc": "Isometric perspective of bowl, sliced cylinder handle, and razor dock"
    },
    {
        "file": "02-top.png",
        "camera": "16,0,25,0,0,0,270",
        "desc": "Top-down view showing micro-diamond lather floor and rim drip cutout"
    },
    {
        "file": "03-side.png",
        "camera": "16,0,25,90,0,90,300",
        "desc": "Side elevation showing 49 deg support-free strut and sliced cylinder waist"
    },
    {
        "file": "04-bottom.png",
        "camera": "16,0,20,180,0,0,270",
        "desc": "Bottom view showing flat 77mm footprint and support-free handle transition"
    },
    {
        "file": "05-lather-surface-closeup.png",
        "camera": "0,0,10,40,0,20,150",
        "desc": "Macro closeup of micro-diamond ridges and blended terrain"
    },
    {
        "file": "07-handle-section.png",
        "camera": "50,0,30,65,0,60,170",
        "desc": "Detail of sliced cylinder handle and 2-finger pinch waist"
    },
    {
        "file": "10-razor-in-dock.png",
        "camera": "52,0,44,52,0,45,150",
        "desc": "Detail of razor cradle and through-rim water drip cutout"
    },
    {
        "file": "14-head-rest-closeup.png",
        "camera": "66,0,52,55,0,25,130",
        "desc": "Closeup of razor head rest disc and retention lip"
    },
    {
        "file": "15-name-emboss-closeup.png",
        "camera": "0,-50,24,90,0,0,130",
        "desc": "Closeup of Tumesh's Shaving Bowl embossed cursive script"
    }
]

print(f"Starting batch render of {len(views)} views using OpenSCAD Manifold...")
total_t0 = time.time()

for idx, v in enumerate(views, 1):
    out_path = os.path.join(renders_dir, v["file"])
    print(f"[{idx}/{len(views)}] Rendering {v['file']} ({v['desc']})...")
    t0 = time.time()
    cmd = [
        nightly,
        "--backend=manifold",
        "-D", "preview_mode=false",
        "-D", 'bowl_preset="standard"',
        "-D", "blade_storage_enabled=false",
        "-D", 'part="bowl"',
        "--colorscheme=Tomorrow Night",
        f"--camera={v['camera']}",
        "--imgsize=1600,1200",
        "--projection=p",
        "-o", out_path,
        scad
    ]
    res = subprocess.run(cmd, capture_output=True, text=True)
    dt = time.time() - t0
    if res.returncode == 0 and os.path.exists(out_path):
        size_kb = os.path.getsize(out_path) / 1024
        print(f"    Done in {dt:.1f}s ({size_kb:.1f} KB)")
    else:
        print(f"    FAILED: {res.stderr[:200]}")

print(f"\nBatch rendering complete in {time.time() - total_t0:.1f}s!")
