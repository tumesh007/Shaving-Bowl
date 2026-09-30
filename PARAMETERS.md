# Parameter Reference

The canonical model and all selectable test parts are in
[`travel_shaving_bowl.scad`](travel_shaving_bowl.scad). Dimensions are in
millimetres. Edit the values near the top of that file or pass OpenSCAD `-D`
overrides when exporting.

## Bowl

| Parameter | Default | Purpose |
| --- | ---: | --- |
| `bowl_outer_diameter` | 80 | Rounded outside diameter |
| `bowl_inner_diameter` | 67 | Inside diameter and texture boundary |
| `bowl_height` | 35 | Rim height from the stable base |
| `base_thickness` | 3.5 | Minimum floor thickness at the center |

The inside and outside curves are generated as near-hemispherical profiles
with a flat foot. The textured floor follows the spherical interior instead
of placing a flat plate at the bottom. `wall_thickness`, `rim_width`, and
`complete_width_with_handle` remain as design-reference values in the source;
the current profile is controlled by the inside/outside diameters and does
not use those three parameters as direct geometry inputs.

## Lather texture

| Parameter | Default | Purpose |
| --- | ---: | --- |
| `preview_mode` | `true` | Faster, coarser interactive model |
| `preview_texture_resolution` | 1.6 | Preview height-field grid spacing |
| `export_texture_resolution` | 0.8 | STL height-field grid spacing |
| `texture_seed` | 4217 | Repeatable deterministic feature layout |
| `diamond_length` | 8 | Rhombus pitch along the long axis |
| `diamond_width` | 5 | Rhombus pitch along the short axis |
| `diamond_spacing` | 2 | Gap between repeated rhombi |
| `diamond_ridge_height` | 1.15 | Raised drum-feature amplitude |
| `diamond_channel_depth` | 0.65 | Recessed channel amplitude |
| `diamond_height_variation` | 0.04 | Small seeded feature variation |
| `hill_max_height` | 1.3 | Positive height-field clamp |
| `valley_min_height` | -3.2 | Negative height-field clamp |
| `macro_hill_scale` | 0.35 | Broad-hill contribution |
| `macro_valley_scale` | 0.45 | Broad-valley contribution |
| `major_groove_scale` | 0.4 | Sparse broad-groove contribution |
| `outer_smooth_width` | 5.5 | Texture fade into the wall |

The softened staggered rhombus field is the primary texture. Low-amplitude
seeded terrain blends into the diamonds without forming isolated deep craters.

## Handle and razor dock

| Parameter | Default | Purpose |
| --- | ---: | --- |
| `handle_width` | 20 | Grip width |
| `handle_height` | 40 | Grip height |
| `handle_projection` | 22 | Handle projection from the bowl |
| `handle_fillet` | 4 | Rounded grip edge radius |
| `razor_dock_angle` | 25 | Dock inclination in degrees |
| `razor_handle_min_diameter` | 8 | Smallest target razor handle |
| `razor_handle_max_diameter` | 15 | Largest target razor handle |
| `razor_handle_clearance` | 1.0 | Cradle fit allowance |
| `razor_dock_wall` | 3.0 | Cradle wall thickness |

## Blade drawer

| Parameter | Default | Purpose |
| --- | ---: | --- |
| `de_blade_length` | 43 | Standard DE blade length |
| `de_blade_width` | 22 | Standard DE blade width |
| `de_blade_thickness` | 0.25 | Single-blade thickness |
| `blade_clearance` | 0.5 | Blade fit allowance |
| `blade_storage_count` | 5 | Preview stack capacity |
| `drawer_wall` | 1.2 | Drawer wall thickness |
| `drawer_clearance` | 0.3 | Sliding clearance per mating side |
| `drawer_open_travel` | 11.9 | Maximum captive travel |
| `drawer_pull_width` | 12 | Pull-tab width |
| `drawer_pull_height` | 5 | Pull-tab height |
| `drawer_pull_projection` | 4 | Pull-tab projection |
| `detent_bump_radius` | 0.65 | Passive detent bump size |
| `detent_flexure_length` | 8 | Integral detent flexure length |
| `detent_flexure_thickness` | 0.9 | Integral detent flexure thickness |
| `drawer_endstop_overlap` | 1.0 | Captive stop-tab overlap |

The vault and tray are centered across the handle's middle plane. The bowl,
drawer, and razor cradle are distinct/dry and wet regions; there is no spring,
magnet, or lid.

## Output selectors

Set `part` to one of:

- `assembly` — preview body and separate drawer together
- `bowl` — production body
- `bowl_shell` — bowl-only geometry diagnostic
- `blade_drawer` — separate printable tray
- `texture_test`
- `razor_dock_test`
- `blade_storage_test`
- `handle_strength_test`

Set `preview_mode=false` for finer STL exports. See the README for complete
Flatpak OpenSCAD export commands.
