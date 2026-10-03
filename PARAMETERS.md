# Parameter Reference

The canonical model and all selectable test parts are in
[`travel_shaving_bowl.scad`](travel_shaving_bowl.scad). Dimensions are in
millimetres. Edit the values near the top of that file or pass OpenSCAD `-D`
overrides when exporting.

## Bowl

| Parameter | Default | Purpose |
| --- | ---: | --- |
| `bowl_outer_diameter` | 84 | Rounded outside diameter |
| `bowl_inner_diameter` | 73.7 | Inside diameter and texture boundary |
| `bowl_height` | 38.5 | Rim height from the stable base (stays $\ge \text{inner\_radius} + 1.5$ mm) |
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
| `preview_texture_resolution` | 0.6 | Preview height-field grid spacing |
| `export_texture_resolution` | 0.25 | STL height-field grid spacing (rule: $\le$ (`diamond_width` + `diamond_spacing`) / 10) |
| `texture_seed` | 4217 | Repeatable deterministic feature layout |
| `diamond_scale` | 0.4 | Uniform scale factor: 1.0 = v4 size (8 × 5 mm); smaller = denser pattern |
| `diamond_length` | 8 × `diamond_scale` | Rhombus pitch along the long axis |
| `diamond_width` | 5 × `diamond_scale` | Rhombus pitch along the short axis |
| `diamond_spacing` | max(0.8, 2 × `diamond_scale`) | Gap between repeated rhombi (≥ 0.8 mm for a 0.4 mm nozzle) |
| `diamond_ridge_height` | 1.15 | Raised drum-feature amplitude |
| `diamond_channel_depth` | 0.65 | Recessed channel amplitude |
| `diamond_height_variation` | 0.04 | Small seeded feature variation |
| `hill_max_height` | 1.3 | Positive height-field clamp |
| `valley_min_height` | -3.2 | Negative height-field clamp |
| `macro_hill_scale` | 0.35 | Broad-hill contribution |
| `macro_valley_scale` | 0.45 | Broad-valley contribution |
| `major_groove_scale` | 0.4 | Sparse broad-groove contribution |
| `outer_smooth_width` | 5.5 | Texture fade into the wall |

### Diamond scale reference

| `diamond_scale` | Diamond size (mm) | Spacing (mm) | Approx. count (r < 30 mm) | Recommended `export_texture_resolution` |
| ---: | ---: | ---: | ---: | ---: |
| 0.5 | 4.0 × 2.5 | 1.0 | ~320 | 0.35 |
| 0.4 | 3.2 × 2.0 | 0.8 | ~500 | 0.25 |
| 0.375 | 3.0 × 1.875 | 0.8 | ~570 | 0.25 |

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
| `dock_raise` | 8 | Vertical dock elevation above rim reference level |
| `overhang_safe` | `true` | Enable 45-degree self-supporting geometry (conical base, gussets, pitched cutouts) |
| `gusset_start` | 2.0 | Dock support gusset offset from cradle mount post |
| `gusset_drop` | 12.0 | Vertical drop distance for 45-degree cradle support gussets down to handle |

## Razor head rest

| Parameter | Default | Purpose |
| --- | ---: | --- |
| `head_rest_radius` | 24 | Half-round support plate radius |
| `head_rest_thickness` | 3.5 | Plate thickness |
| `head_rest_rim_height` | 1.6 | Lip height around perimeter |
| `head_rest_rim_width` | 1.6 | Lip width around perimeter |
| `head_rest_gap` | 3 | Gap between dock top and shelf bottom |
| `neck_slot_radius` | 6.5 | U-shaped neck slot radius |
| `head_rest_flat_edge` | 6 | Offset for straight edge flat cut |
| `head_rest_drain_gap` | 5 | Through-drainage cutout width |

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

## Embossed name

| Parameter | Default | Purpose |
| --- | ---: | --- |
| `emboss_enabled` | `true` | Enable raised lettering on bowl wall |
| `emboss_line1` | "Tumesh's" | Top text line |
| `emboss_line2` | "Travel Shaving Bowl" | Bottom text line |
| `emboss_bold` | 0.15 | 2D offset applied after resize to ensure stroke >= 0.8 mm |
| `emboss_font` | "Pacifico" | Font family name (requires bundled TTF) |
| `emboss_width1` | 34 | Target width for line 1 |
| `emboss_width2` | 48 | Target width for line 2 |
| `emboss_line_gap` | 10 | Vertical line spacing center-to-center |
| `emboss_z` | 22 | Vertical center elevation of text block |
| `emboss_height` | 0.8 | Outward emboss projection height |
| `emboss_sink` | 0.4 | Inward penetration into bowl wall |
| `emboss_max_half_width` | 25 | Maximum lateral half-width clamp |

## Output selectors

Set `part` to one of:

- `assembly` — preview body and separate drawer together
- `bowl` — production body
- `bowl_shell` — bowl-only geometry diagnostic
- `blade_drawer` — separate printable tray
- `texture_test`
- `razor_dock_test`
- `blade_storage_test`
- `emboss_test` — exterior-wall patch for checking raised lettering

Set `preview_mode=false` for finer STL exports. See the README for complete
Flatpak OpenSCAD export commands.
