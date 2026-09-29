# Travel Shaving Bowl

A compact, parametric, FDM-printable travel shaving bowl designed for shaving while traveling.

This project intentionally has no lid, no lid lock, no snap-fit cover, and no bayonet cover. No lid geometry is created anywhere in the model or in the source files.

## Printing orientation

Print the bowl upright with the bowl opening facing upward. The handle and dock are integrated into the body and are intended to print without supports in normal FDM settings.

## Recommended print settings

For a 0.4 mm nozzle:
- Layer height: 0.12 to 0.28 mm
- Wall loops: 3 to 4
- Infill: 15 to 25%
- Top/bottom layers: 4 to 6
- Materials: PLA, PLA+, or PETG

## Export commands

If OpenSCAD is available in the environment:

```bash
openscad -o travel_shaving_bowl.stl travel_shaving_bowl.scad
openscad -o texture_test_coupon.stl texture_test_coupon.scad
openscad -o razor_dock_test.stl razor_dock_test.scad
openscad -o blade_storage_test.stl blade_storage_test.scad
openscad -o handle_strength_test.stl handle_strength_test.scad
```

If OpenSCAD is not available in the current environment, keep the SCAD source files as the canonical exportable files and run the same commands on a machine with OpenSCAD installed.

## Test-coupon workflow

Use the coupon and validation files to inspect:
- texture quality and transition
- razor dock fit across several handle diameters
- blade drawer fit and captive stop behavior
- handle strength and broad attachment zones

Preview examples:

```bash
openscad -D 'render_mode="assembly"' travel_shaving_bowl.scad
openscad -D 'render_mode="dock_test"' travel_shaving_bowl.scad
openscad -D 'render_mode="blade_test"' travel_shaving_bowl.scad
openscad -D 'render_mode="handle_test"' travel_shaving_bowl.scad
```

## Dimensional parameters

Core bowl values:
- bowl_outer_diameter = 80
- bowl_inner_diameter = 67
- bowl_height = 35
- wall_thickness = 3
- base_thickness = 3.5
- rim_width = 6
- interior_depth = 22

Texture values:
- diamond_length = 8
- diamond_width = 5
- diamond_spacing = 2
- diamond_ridge_height = 1.0
- diamond_channel_depth = 1.2
- hill_height = 1.8
- valley_height = -2.5
- deep_valley_height = -4.5
- feature_radius = 6.0
- seed = 42
- edge_attenuation = 5.0

Handle and dock values:
- handle_width = 20
- handle_height = 40
- handle_projection = 22
- handle_fillet = 4
- handle_joint_radius = 4
- razor_dock_angle = 25
- razor_handle_min_diameter = 8
- razor_handle_max_diameter = 15
- razor_handle_clearance = 1.0
- razor_dock_depth = 4

Blade storage values:
- de_blade_length = 43
- de_blade_width = 22
- de_blade_thickness = 0.25
- blade_storage_count = 5
- blade_clearance = 0.4

## Drawer clearance adjustment

The storage drawer clearance is controlled by:

```scad
blade_clearance = 0.4;
```

Adjust this value for tighter or looser fit:
- 0.3 mm = tighter friction fit
- 0.4 mm = general use default
- 0.5 mm = easier slide

## Razor-dock fit guidance

Check fit across:
- 8 mm handle
- 10 mm handle
- 12 mm handle
- 15 mm handle

The dock is intentionally open-top, shallow, and removal-friendly. It should retain the razor gently without a hard snap and should remain easily removable with one wet hand.

## Validation notes

This model should be visually reviewed and tested in OpenSCAD preview/render for:
- bowl is watertight and has no accidental openings
- base is flat and stable
- wall thickness remains intact
- texture does not penetrate the bowl walls or base
- no sharp spikes or knife-edge ridges exist
- valleys are partially interconnected and not sealed
- handle has two broad attachment zones
- dock supports 8–15 mm handles
- dock drains without feeding into the blade compartment
- blade drawer remains isolated and captive
- 3–5 blades fit with reasonable clearance

## Validation limitations

OpenSCAD validation is only a design aid. Physical fit, strength, and long-term reliability must still be tested on actual printed parts before daily use.

## Warning

Do not use this design for daily shaving without physical testing, especially for strength, fit, and safe blade handling.
