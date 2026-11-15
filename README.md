# Tumesh's Shaving Bowl (v14.2)

[![GitHub Pages](https://img.shields.io/badge/Web_App-Live_Demo-brightgreen?logo=github)](https://tumesh007.github.io/Shaving-Bowl/)
[![License: CC BY-NC-SA 4.0](https://img.shields.io/badge/License-CC_BY--NC--SA_4.0-lightgrey.svg)](LICENSE)
[![Bambu Lab A1 Mini](https://img.shields.io/badge/3D_Printer-Bambu_Lab_A1_Mini-orange)](https://bambulab.com)

> 🚀 **Live Interactive 3D Web App:** **[tumesh007.github.io/Shaving-Bowl](https://tumesh007.github.io/Shaving-Bowl/)**  
> Customize bowl dimensions, micro-diamond lather friction, and real-time cursive name engraving directly in your browser.

Parametric, open lather shaving bowl with a blended height-field lather surface, support-free ergonomic sliced cylinder handle, integrated safety razor cradle with through-rim drip drainage, and an interactive 3D Web Customizer. **Engineered specifically for support-free 3D printing on the Bambu Lab A1 Mini (0.40 mm nozzle, gold textured PEI plate).**

![Isometric view of the bowl and integrated razor dock](renders/01-isometric.png)

---

## What's New in v14.2 (Sliced Cylinder Ergonomics, Razor Drip Cutout & Web App Overhaul)

1. **Architectural Sliced Cylinder Ergonomic Handle:**
   - **Flaw in v14.1:** The v14.1 lower strut was a flat 20 mm wide rectangular bar that felt boxy and slippery when lifted between two fingers with wet, soapy hands.
   - **v14.2 Solution:** Replaced with an architectural sliced-cylinder strut. The outer surface follows a smooth cylindrical arc, while the middle section tapers to an ergonomic **two-finger pinch waist** (narrowing to 15.6 mm at the midpoint).
   - **100% Support-Free:** Sloped along the $51.15^\circ$ self-supporting axis with zero steep overhangs.
2. **Through-Rim Razor Drip & Clearance Cutout:**
   - **Flaw in Earlier Versions:** The bowl rim formed a solid wall between the cradle groove and the inner bowl, obstructing long safety razor handles and trapping rinse water.
   - **v14.2 Solution:** Slotted a continuous cylindrical channel ($r = 8.1\text{ mm}$) and open top U-slot at $65^\circ$ directly through the solid rim wall into the bowl cavity. Drops the rim wall at the dock from $Z = 45.0\text{ mm}$ down to $Z = 34.29\text{ mm}$ for free handle passage and self-draining water runoff.
3. **Zero Internal Cavity Protrusion:**
   - Re-anchored the lower handle strut securely to $X = 41.0\text{ mm}$ at $Z = 12.0\text{ mm}$ (outer wall $R = 42.74\text{ mm}$). Completely eliminates handle penetration into the inner bowl cavity ($R_{in} = 34.86\text{ mm}$), leaving nearly $5\text{ mm}$ of solid wall margin.
4. **Web App 3D STLLoader Integration:**
   - Integrated Three.js `STLLoader` into `index.html` and `app.js` to render the verified production binary STL directly in 3D.
   - Eliminates disconnected floating bounding primitives and reveals the authentic micro-diamond lather friction floor.
5. **Real-Time Dynamic Outer Wall Engraving:**
   - Promoted custom text inputs to a dedicated, always-visible card in the Web App.
   - Dynamic 2D canvas decal projects the cursive `Pacifico` script text onto the 3D bowl wall live as you type.

---

## 3D Web Customizer App

Experience the live 3D customizer online at **[tumesh007.github.io/Shaving-Bowl](https://tumesh007.github.io/Shaving-Bowl/)** or open [`index.html`](index.html) locally in any web browser:
- **Real-Time Three.js Viewport:** Orbit, pan, zoom, inspect wireframe, and test filament colors (Gold PEI, Charcoal Black, Arctic White, Ocean Blue).
- **Live Parametric Controls:** Bowl diameter, height, wall thickness, lather diamond friction scale, razor handle diameter clearance, and custom emboss text.
- **Client-Side Binary STL Export:** Generate slicer-ready binary STLs instantly from the browser without needing OpenSCAD installed.
- **OpenSCAD Exporter:** Live generates the exact `.scad` code matching customized parameters.

---

## Variants: Standard vs Travel

Selectable via `bowl_preset` in `travel_shaving_bowl_v14_2.scad`:

| Specification | Travel (`bowl_preset = "travel"`) | Standard (`bowl_preset = "standard"`) |
| :--- | :--- | :--- |
| **Outer / Inner Diameter** | 84 / 74 mm | 108 / 96 mm |
| **Cavity Volume (Rim-to-Brim)** | ~104 mL | ~212 mL (Standard) / ~298 mL (@112% scale) |
| **Usable Lather Capacity** | ~85 mL | ~175 mL (Standard) / ~250 mL (@112% scale) |
| **Flat Swirl Floor (slope < 30°)** | 46 mm | 64 mm (fits 24–28 mm brush knots) |
| **Overall Footprint (L × W × H)** | 120 × 84 × 62 mm | 143.2 × 110 × 62.6 mm |
| **Wall Thickness** | ~5.0 mm | ~6.0 mm |
| **Swirl Surface Relief** | ~1.6 mm | 1.89 mm |
| **Bed Fit (A1 Mini 180×180 mm)** | +60 mm plate margin | +36.8 mm plate margin (Leaves room for purge line) |
| **Official v14.2 STL** | `travel_shaving_bowl_v14_2.scad` (preset) | [`Tumeshs_Shaving_Bowl_v14_2_STANDARD_bin.stl`](https://github.com/tumesh007/Shaving-Bowl/releases/tag/v14.2) |

---

## Bambu Studio / Slicer Recommendations

- **Printer:** Bambu Lab A1 Mini (or standard $180\times180\text{ mm}$ bed).
- **Plate:** WOL3D Gold Textured PEI.
- **Material:** PETG (recommended for hot water lather & bathroom humidity resistance) or PLA.
- **Preset Profile:** `0.20 mm Standard @BBL A1M`.
- **Wall Loops:** `3` to `4` perimeters (ensures watertight seal without post-processing).
- **Top / Bottom Shells:** `4` top, `4` bottom layers.
- **Infill:** `15% Gyroid` (strictly Gyroid; avoids nozzle collisions during high-speed travels).
- **Supports:** 
  - **Enable Support:** `Checked`
  - **Type:** `Tree(auto)` (or `Tree(manual)` painted on head rest disc)
  - **Style:** `Tree Slim`
  - **On build plate only:** **`CHECKED` (Critical)** — Prevents supports from ever generating inside the bowl cavity or on the micro-diamond lather floor.
  - **Threshold angle:** `30°`
- **Print Time & Filament Weight:**
  - **Standard (100% scale):** **~2h 25m** | **~76g PETG** (Rim capacity: $212\text{ ml}$).
  - **Enlarged (112% scale):** **~3h 20m** | **~107g PETG** (Working lather capacity: $250\text{ ml}$, Rim capacity: $298\text{ ml}$).

---

## Exporting via CLI

With OpenSCAD Nightly (Manifold backend):

```sh
# v14.2 Standard preset (15–20 seconds via Manifold):
openscad --backend=Manifold -D 'preview_mode=false' -D 'bowl_preset="standard"' -D 'blade_storage_enabled=false' -D 'part="bowl"' -o Tumeshs_Shaving_Bowl_v14_2_STANDARD_bin.stl travel_shaving_bowl_v14_2.scad

# v14.2 Travel preset:
openscad --backend=Manifold -D 'preview_mode=false' -D 'bowl_preset="travel"' -D 'blade_storage_enabled=false' -D 'part="bowl"' -o Tumeshs_Shaving_Bowl_v14_2_TRAVEL_bin.stl travel_shaving_bowl_v14_2.scad
```

---

## License

This project is licensed under Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0). See [LICENSE](LICENSE).

You may print it for yourself, share it and modify it, as long as you:
- give credit to Tumesh,
- do not sell it or its prints for money,
- share any modified version under the same licence.

For commercial use (selling prints or licensing the design), ask the author first.

The Pacifico font is under the SIL Open Font License and is not covered by this licence (see [NOTICE.md](NOTICE.md)).
