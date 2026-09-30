# Compact Travel Shaving Bowl

This is a fresh, open-bowl design built around a seeded mathematical height field. It contains a rounded shaving bowl, an integrated side grip, an angled open razor cradle, a centered enclosed DE-blade compartment, and a separately printable sliding drawer. **There is no lid.**

![Isometric view of the bowl and integrated razor dock](renders/01-isometric.png)

See the [`renders/`](renders/) gallery for top, side, bottom, texture close-up, section views, and drawer/razor previews. Adjustable dimensions and texture controls are listed in [`PARAMETERS.md`](PARAMETERS.md).

## Files

- `travel_shaving_bowl.scad` — parametric source and selectable test/view modes.
- `travel_shaving_bowl.stl` — bowl/body with integrated handle, dock, and empty blade vault; drawer is excluded.
- `blade_drawer.stl` — separate captive sliding drawer with pull tab, passive detent bumps, and end-stop tabs.
- `texture_test_coupon.stl` — 40 × 40 mm terrain and diamond-pattern coupon.
- `razor_dock_test.stl` — cradle samples for 8, 10, 12, and 15 mm handles.
- `blade_storage_test.stl` — drawer samples with 1, 3, and 5 dummy blades.
- `handle_strength_test.stl` — grip, attachment pads, blade vault, and dock assembly.
- `renders/` — isometric, orthographic, section, close-up, and storage previews.

## Exporting

Open the project with OpenSCAD 2021.01 or newer. `preview_mode=true` keeps interactive previews lighter. Set it to `false` for the finer production mesh. With Flatpak OpenSCAD:

```sh
flatpak run org.openscad.OpenSCAD -D 'preview_mode=false' -D 'part="bowl"' -o travel_shaving_bowl.stl travel_shaving_bowl.scad
flatpak run org.openscad.OpenSCAD -D 'preview_mode=false' -D 'part="blade_drawer"' -o blade_drawer.stl travel_shaving_bowl.scad
flatpak run org.openscad.OpenSCAD -D 'preview_mode=false' -D 'part="texture_test"' -o texture_test_coupon.stl travel_shaving_bowl.scad
flatpak run org.openscad.OpenSCAD -D 'preview_mode=false' -D 'part="razor_dock_test"' -o razor_dock_test.stl travel_shaving_bowl.scad
flatpak run org.openscad.OpenSCAD -D 'preview_mode=false' -D 'part="blade_storage_test"' -o blade_storage_test.stl travel_shaving_bowl.scad
flatpak run org.openscad.OpenSCAD -D 'preview_mode=false' -D 'part="handle_strength_test"' -o handle_strength_test.stl travel_shaving_bowl.scad
```

The top-level `part` selector supports `assembly`, `bowl`, `bowl_shell`, `blade_drawer`, `texture_test`, `razor_dock_test`, `blade_storage_test`, and `handle_strength_test`. Use `part="assembly"` for inspection only; export the body and drawer separately. `render_mode` supports `top`, `side`, `bottom`, `texture_closeup`, `texture_section`, `handle_section`, `blade_section`, `razor_parked`, and `blades_inside`. For example:

```sh
flatpak run org.openscad.OpenSCAD -D 'render_mode="blade_section"' -o renders/blade-section.png travel_shaving_bowl.scad
flatpak run org.openscad.OpenSCAD -D 'render_mode="blades_inside"' -o renders/blades-inside.png travel_shaving_bowl.scad
```

## Design notes

- The inside and outside bowl profiles are rounded and near-hemispherical, with a flat stable foot and a minimum 3.5 mm center base.
- The lather surface uses an even, staggered 45-degree diamond/drum pattern with softened ridges, shallow broad seeded undulations, and subdued connecting channels. Its outer 5.5 mm fades smoothly into the bowl wall; the relief is limited to about 4.5 mm peak-to-valley rather than the previous deep, uneven craters.
- The razor cradle is open upward, fits the target 8–15 mm handle range, includes rounded retaining bumps and through-drainage ports, and does not drain into blade storage.
- The blade vault and drawer are centered across the handle's middle plane, kept below the upper/lower handle attachment pads, and separated from the wet bowl and dock. The shorter vault keeps the drawer and handle balanced while preserving its front pull access. Its independent drawer has adjustable per-side clearance, integral flexible detent tongues and bumps, matching body recesses, stop tabs, and a compact pull tab. Squeeze the stop tabs to remove the drawer deliberately.
- The design targets upright FDM printing with a 0.4 mm nozzle. Inspect the sections and test coupons, then physically validate wall strength, fit, washability, and drawer retention before travel use.

## Mesh verification

The production body, separate drawer, and four test meshes were exported with
OpenSCAD and checked with FreeCAD 1.1.3's mesh importer; each reported a solid
mesh. This confirms mesh closure, not real-world print strength, fit, or
waterproofness. Print and physically test before travel use.

## Limitations

The razor and blades shown in preview modes are illustrative solids, not part of the production bowl STL. The model does not guarantee lather performance, razor compatibility beyond the nominal diameter range, waterproofness after printing, or blade safety. Print and test before use.
