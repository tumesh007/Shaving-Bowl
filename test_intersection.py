import subprocess

def test_diam(d):
    scad_code = f"""
    include <travel_shaving_bowl.scad>
    
    // Check intersection between final_merged_handle and the razor handle
    intersection() {{
        final_merged_handle();
        // A hypothetical razor handle
        translate([outer_radius + 2.0, 0, bowl_height - 1 + dock_raise])
            rotate([0, 90 - razor_dock_angle, 0])
                translate([0, 0, 0])
                    cylinder(h=100, r={d/2}, $fn=32);
    }}
    """
    with open("temp.scad", "w") as f:
        f.write(scad_code)
    
    res = subprocess.run(["flatpak", "run", "org.openscad.OpenSCAD", "-o", "temp.stl", "temp.scad"], capture_output=True, text=True)
    # Check volume or bounding box of temp.stl
    # Just print the output
    print(f"Tested {d}: {res.stderr}")

for d in [10.8, 11.6, 12, 13, 14]:
    test_diam(d)

