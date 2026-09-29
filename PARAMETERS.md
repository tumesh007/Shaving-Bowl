# Parameter Reference

This file documents the main adjustable dimensions and personalization controls for the travel shaving bowl.

## Handoff defaults

The production source is `travel_shaving_bowl.scad` on the `main` branch.

- `include_lid = false` — fixed requirement; do not change to add a lid.
- `render_mode = "assembly"` — default complete preview.
- `seed = 42` — deterministic terrain seed.

## Bowl dimensions

- `bowl_outer_diameter = 80` mm
- `bowl_inner_diameter = 67` mm
- `bowl_height = 35` mm
- `wall_thickness = 3` mm
- `base_thickness = 3.5` mm
- `rim_width = 6` mm
- `interior_depth = 22` mm

Keep the outer diameter approximately 75–85 mm and height approximately 30–40 mm for the intended travel form factor.

## Hybrid lather texture

- `diamond_length = 8` mm
- `diamond_width = 5` mm
- `diamond_spacing = 2` mm
- `diamond_ridge_height = 1.0` mm
- `diamond_channel_depth = 1.2` mm
- `hill_height = 1.8` mm
- `valley_height = -2.5` mm
- `deep_valley_height = -4.5` mm
- `feature_radius = 6.0` mm
- `seed = 42`
- `edge_attenuation = 5.0` mm

Changing `seed` changes deterministic feature placement while keeping the same seed and dimensions reproducible.

## Handle

- `handle_width = 20` mm
- `handle_height = 40` mm
- `handle_projection = 22` mm
- `handle_fillet = 4` mm
- `handle_joint_radius = 4` mm

## Razor dock

- `razor_dock_angle = 25` degrees
- `razor_handle_min_diameter = 8` mm
- `razor_handle_max_diameter = 15` mm
- `razor_handle_clearance = 1.0` mm
- `razor_dock_depth = 4` mm

## Blade storage

- `de_blade_length = 43` mm
- `de_blade_width = 22` mm
- `de_blade_thickness = 0.25` mm
- `blade_storage_count = 5`
- `blade_clearance = 0.4` mm per mating side

Recommended drawer clearance range:
- `0.3` mm — tighter fit
- `0.4` mm — default
- `0.5` mm — looser/easier slide

## Personalization controls

The current default marking is **Tumesh** in **Pacifico**:

```scad
name_text = "Tumesh";
name_font = "Pacifico";
name_size = 8;
name_depth = 0.8;
name_z = 17;
name_spacing = 1.0;
```

### Change the name

Edit `name_text` and keep the value in quotes:

```scad
name_text = "Your Name";
```

### Change the font

Edit `name_font` using an installed system font family and optional style:

```scad
name_font = "DejaVu Sans:style=Bold";
```

Pacifico must be installed on the computer running OpenSCAD. The font file is not stored in this repository. To list Linux font family/style names:

```bash
fc-list : family style
```

On Windows and macOS, use the exact family name shown by the system font viewer. Restart OpenSCAD after installing a font if it does not appear.

### Change the marking appearance

- `name_size` controls text height in millimetres.
- `name_depth` controls emboss thickness in millimetres.
- `name_z` moves the marking vertically on the exterior.
- `name_spacing` adjusts spacing between characters.

The `name_marking()` module places the text on the front exterior wall, and `assembly_preview()` includes it in the default view.

## Command-line personalization

OpenSCAD can override values without editing the file:

```bash
openscad -D 'name_text="Alex"' -D 'name_font="DejaVu Sans:style=Bold"' -D 'name_size=8' -o personalized_bowl.stl travel_shaving_bowl.scad
```

For repeatable project handoff, editing the named parameters in the SCAD source is preferred.

## Safety / no-lid requirement

- `include_lid = false`

There is no lid module or lid geometry in this project. Do not add lid geometry when customizing the model.
