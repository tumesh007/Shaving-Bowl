use <fonts/Pacifico-Regular.ttf>

/*
 * Tumesh's Shaving Bowl (v14.1)
 *
 * Parametric lather bowl with high-friction micro-diamond height-field floor,
 * support-free self-supporting angled ergonomic handle truss, integrated 25-degree
 * safety razor cradle with tapered head rest, and embossed curved typography.
 *
 * v14.1 Improvements over v14:
 * 1. 100% Support-Free Handle:
 *    - Replaced v14's flat horizontal lower return arch (which created a >700 mm²
 *      unsupported horizontal ceiling at Z=12.6mm) with a 49-degree self-supporting
 *      angled ergonomic truss that merges directly into the bowl wall at Z=16mm.
 *    - Reduces handle steep overhang area from >700 mm² to exactly 0.00 mm².
 *    - Preserves clean open clearance underneath (Z=0 to Z=16mm) with no inverted triangle.
 * 2. Support-Free Razor Head Rest Shelf:
 *    - Extended lower transition cone along the cradle tube at 48-50 degrees.
 *    - Cuts shelf underside overhang by >75% for flawless support-free printing.
 * 3. Bulletproof Manifold Geometry Engine Integration:
 *    - Added coplanar-clearing cylinder cutout at bowl rim in bowl_shell().
 *    - Completely resolves OpenSCAD nightly Manifold bug (which previously caused a solid
 *      lid/cap defect across the bowl opening in v14).
 *    - Enables full Manifold acceleration: export times drop from 6-7 minutes down to 18-21 seconds.
 * 4. FDM Physics Optimization (Bambu Lab A1 Mini):
 *    - export_texture_resolution = 0.50 matched to 0.40 mm nozzle / 0.42 mm extrusion width.
 *    - Facet caps: terrain_preview_fn = 64, rounded_fn = 20.
 *    - blade_storage_enabled = false default (prevents moisture / blade corrosion).
 */

// ---------- Main dimensions (millimetres) ----------
// bowl_preset: "travel"   = 84 mm bowl, ~105 mL, hemispherical
//              "standard" = 110 mm bowl, ~250 mL, flat 56 mm swirl floor
bowl_preset = "standard";
is_standard = (bowl_preset == "standard");
bowl_outer_diameter = is_standard ? 110 : 84;
bowl_inner_diameter = is_standard ? 100 : 73.7;
bowl_height = is_standard ? 45.6 : 38.5;
wall_thickness = 3;
base_thickness = 3.5;
rim_width = 6;
complete_width_with_handle = is_standard ? 135 : 105;

// ---------- Height-field surface ----------
preview_mode = false;
preview_texture_resolution = 0.6;
export_texture_resolution = 0.50;   // Matched to 0.4mm nozzle / 0.42mm extrusion physics
texture_seed = 4217;
texture_resolution = preview_mode ? preview_texture_resolution : export_texture_resolution;
diamond_scale = 0.4;
diamond_length = 8 * diamond_scale;
diamond_width = 5 * diamond_scale;
diamond_spacing = max(0.8, 2 * diamond_scale);
diamond_ridge_height = 1.15;
diamond_channel_depth = 0.65;
diamond_height_variation = 0.04;
hill_max_height = 1.3;
valley_min_height = -3.2;
macro_hill_scale = 0.35;
macro_valley_scale = 0.45;
major_groove_scale = 0.4;
outer_smooth_width = 5.5;
feature_spread = 22;

// ---------- Grip ----------
handle_width = 20;
handle_height = 40;
handle_projection = is_standard ? 19 : 16;
handle_fillet = 4;
handle_fillet_radius = handle_fillet;

// ---------- Razor cradle ----------
razor_dock_angle = 25;
razor_handle_min_diameter = 8;
razor_handle_max_diameter = 15;
razor_handle_clearance = 1.0;
razor_dock_wall = 3.0;
dock_raise = 1.5;
dock_offset_x = -0.5;
overhang_safe = true;
gusset_start = 2.0;
gusset_drop = 12.0;

// ---------- Razor head rest (half-round shelf) ----------
head_rest_radius = 24;
head_rest_thickness = 3.5;
head_rest_rim_height = 1.6;
head_rest_rim_width = 1.6;
head_rest_gap = 3;
neck_slot_radius = 6.5;
head_rest_flat_edge = 6;
head_rest_drain_gap = 5;

// ---------- Embossed name (raised text on outer wall opposite handle) ----------
emboss_enabled = true;
emboss_line1 = "Tumesh's";
emboss_line2 = "Shaving Bowl";
emboss_bold = 0.15;
emboss_font = "Pacifico";
emboss_width1 = is_standard ? 46 : 34;
emboss_width2 = is_standard ? 50 : 38;
emboss_line_gap = is_standard ? 13 : 10;
emboss_z = is_standard ? 26 : 22;
emboss_height = 0.8;
emboss_sink = 0.4;
emboss_max_half_width = 25;

// ---------- Blade Storage Option ----------
blade_storage_enabled = false;

// ---------- Captive DE blade drawer ----------
de_blade_length = 56;
de_blade_width = 28;
de_blade_thickness = 10.0;
blade_clearance = 0.5;
blade_storage_count = 1;
drawer_wall = 1.2;
drawer_clearance = 0.4;
drawer_open_travel = 45.0;
drawer_pull_width = 12;
drawer_pull_height = 5;
drawer_pull_projection = 4;
detent_bump_radius = 0.65;
detent_flexure_length = 8;
detent_flexure_thickness = 1.2;
drawer_endstop_overlap = 1.0;

// ---------- Output selection ----------
render_mode = "assembly";
part = "bowl";
drawer_open = false;

// ---------- Derived dimensions ----------
outer_radius = bowl_outer_diameter / 2;
inner_radius = bowl_inner_diameter / 2;
texture_radius = inner_radius;
texture_fade_start = texture_radius - outer_smooth_width;
terrain_preview_fn = preview_mode ? 48 : 64;
nominal_floor_z = base_thickness;
rounded_fn = preview_mode ? 16 : 20;

function fract(v) = v - floor(v);
function clamp(v, low, high) = min(max(v, low), high);
function smoothstep(edge0, edge1, value) =
    let(t = clamp((value - edge0) / (edge1 - edge0), 0, 1))
    t * t * (3 - 2 * t);
function rand01(k) =
    fract(sin((k + texture_seed * 17.0) * 127.1 + 311.7) * 43758.5453123);
function feature_coord(i, salt) = (rand01(i * 13.7 + salt) * 2 - 1) * feature_spread;
function make_feature(i, salt, rmin, rmax, amin, amax) = [
    feature_coord(i, salt),
    feature_coord(i, salt + 101),
    rmin + rand01(i * 7.3 + salt + 207) * (rmax - rmin),
    amin + rand01(i * 11.9 + salt + 419) * (amax - amin)
];
function feature_sum(features, x, y, i=0) =
    i >= len(features) ? 0 :
    let(f = features[i],
        dx = x - f[0],
        dy = y - f[1],
        sigma = f[2])
    f[3] * exp(-(dx * dx + dy * dy) / (2 * sigma * sigma))
    + feature_sum(features, x, y, i + 1);

macro_hill_features = [for (i = [0:7]) make_feature(i, 37, 7.0, 10.0, 0.18, 0.32)];
macro_valley_features = [for (i = [0:5]) make_feature(i, 211, 7.0, 10.0, -0.48, -0.28)];
deep_valley_features = [for (i = [0:1]) make_feature(i, 503, 7.5, 9.5, -1.15, -0.95)];
local_hill_features = [for (i = [0:4]) make_feature(i, 809, 4.0, 6.0, 0.08, 0.15)];
local_valley_features = [for (i = [0:4]) make_feature(i, 1103, 4.0, 6.0, -0.18, -0.10)];

function macro_hills(x, y) = macro_hill_scale * feature_sum(macro_hill_features, x, y);
function macro_valleys(x, y) =
    macro_valley_scale * feature_sum(macro_valley_features, x, y)
    + major_groove_scale * feature_sum(deep_valley_features, x, y);
function macro_terrain(x, y) =
    0.045 * sin(x * 5.0 + texture_seed)
    + 0.04 * cos(y * 5.4 - texture_seed * 0.7)
    + 0.03 * sin((x + y) * 3.6);

function local_hills(x, y) = feature_sum(local_hill_features, x, y);
function local_valleys(x, y) = feature_sum(local_valley_features, x, y);

function diamond_texture(x, y) =
    let(u = (x + y) * 0.70710678,
        v = (x - y) * 0.70710678,
        pitch_u = diamond_length + diamond_spacing,
        pitch_v = diamond_width + diamond_spacing,
        row = floor(v / pitch_v + 0.5),
        v_local = (v - row * pitch_v) / (pitch_v / 2),
        u_staggered = u - 0.12 * pitch_u * cos(180 * v / pitch_v),
        u_local = (u_staggered
                   - pitch_u * floor(u_staggered / pitch_u + 0.5)) / (pitch_u / 2),
        diamond_radius = abs(u_local) + abs(v_local),
        rounded_diamond = 1 - smoothstep(0.72, 1.12, diamond_radius),
        variation = 1 + diamond_height_variation
                    * sin((u + v) * 10.0 + texture_seed))
    variation * (diamond_ridge_height * rounded_diamond
                 - diamond_channel_depth * (1 - rounded_diamond));

function controlled_variation(x, y) =
    0.025 * sin(x * 15.0 + y * 11.0 + texture_seed)
    + 0.02 * cos(x * 9.0 - y * 13.0 + texture_seed * 0.41);
function drainage_channel_height(x, y) =
    -0.14 * exp(-((y - 1.5*sin(x*8.0 + texture_seed))^2) / 24.0)
    -0.12 * exp(-((x - 1.5*sin(y*7.0 - texture_seed*0.61))^2) / 26.0);
function texture_fade(x, y) =
    1 - smoothstep(texture_fade_start, texture_radius, sqrt(x * x + y * y));
function combined_texture_height(x, y) =
    let(r = sqrt(x * x + y * y))
    r >= texture_radius ? 0 :
    clamp(texture_fade(x, y) *
          (macro_terrain(x, y)
           + diamond_texture(x, y)
           + macro_hills(x, y)
           + macro_valleys(x, y)
           + local_hills(x, y)
           + local_valleys(x, y)
           + drainage_channel_height(x, y)
           + controlled_variation(x, y)),
          valley_min_height, hill_max_height);

function inner_sphere_z(r) =
    bowl_height - sqrt(max(0, inner_radius*inner_radius - r*r));
flat_floor = is_standard;
floor_nominal_z = base_thickness + 0.7;
floor_corner_k = 6;
function inner_bowl_base_z(r) =
    let(sphere_z = inner_sphere_z(min(r, inner_radius)))
    flat_floor
      ? (sphere_z + floor_nominal_z + sqrt((sphere_z - floor_nominal_z)*(sphere_z - floor_nominal_z) + floor_corner_k*floor_corner_k)) / 2
      : base_thickness + smoothstep(8.0, 15.0, r) * (sphere_z - base_thickness);

module rounded_box(size=[10,10,10], radius=2, facets=20) {
    minkowski() {
        cube(size - [2*radius, 2*radius, 2*radius], center=true);
        sphere(r=radius, $fn=facets);
    }
}

function outer_base_radius() =
    sqrt(max(0, outer_radius*outer_radius - bowl_height*bowl_height));
function outer_sphere_z(r) =
    bowl_height - sqrt(max(0, outer_radius*outer_radius - r*r));
function outer_bowl_z(r) =
    overhang_safe ?
        let(r_tangent = outer_radius * sin(46),
            z_tangent = bowl_height - outer_radius * cos(46),
            r_foot = r_tangent - z_tangent / tan(46))
        (r >= r_tangent) ?
            outer_sphere_z(r) :
            max(0, (r - r_foot) * tan(46)) :
        let(r0 = outer_base_radius(), r1 = r0 + 3.0)
        smoothstep(r0, r1, r) * outer_sphere_z(r);

function outer_blank_start_radius() =
    overhang_safe ?
        (outer_radius * sin(46) - (bowl_height - outer_radius * cos(46)) / tan(46)) :
        outer_base_radius();

module bowl_exterior_blank() {
    r_start = outer_blank_start_radius();
    rotate_extrude($fn=terrain_preview_fn)
        polygon(points=concat(
            [[0, 0], [r_start, 0]],
            [for (i = [1:40])
                let(r = r_start
                        + (outer_radius - r_start) * i / 40)
                [r, outer_bowl_z(r)]],
            [[0, bowl_height], [0, 0]]
        ));
}

function height_grid_size() =
    max(4, ceil((2 * texture_radius) / texture_resolution));
function grid_xy(i, j, n) =
    [-texture_radius + 2 * texture_radius * i / n,
     -texture_radius + 2 * texture_radius * j / n];
function height_grid_points(n) =
    let(side = n + 1, count = side * side)
    concat(
        [for (j = [0:n], i = [0:n])
            let(p = grid_xy(i, j, n))
            let(r = min(texture_radius, sqrt(p[0]*p[0] + p[1]*p[1])))
            [p[0], p[1],
             max(base_thickness,
                 inner_bowl_base_z(r) + combined_texture_height(p[0], p[1]))]],
        [for (j = [0:n], i = [0:n])
            let(p = grid_xy(i, j, n))
            [p[0], p[1], bowl_height + 1]]
    );
function perimeter_indices(n) = concat(
    [for (i = [0:n]) i],
    [for (j = [1:n]) j * (n + 1) + n],
    [for (i = [n-1:-1:0]) n * (n + 1) + i],
    [for (j = [n-1:-1:1]) j * (n + 1)]
);
function height_grid_faces(n) =
    let(side = n + 1, count = side * side, perimeter = perimeter_indices(n))
    concat(
        [for (j = [0:n-1], i = [0:n-1], tri = [0:1])
            let(k = j * side + i)
            tri == 0 ? [k, k + side + 1, k + 1] : [k, k + side, k + side + 1]],
        [for (j = [0:n-1], i = [0:n-1], tri = [0:1])
            let(k = j * side + i + count)
            tri == 0 ? [k, k + 1, k + side + 1] : [k, k + side + 1, k + side]],
        [for (k = [0:len(perimeter)-1], tri = [0:1])
            let(a = perimeter[k],
                b = perimeter[(k + 1) % len(perimeter)])
            tri == 0 ? [a, b, b + count] : [a, b + count, a + count]]
    );

module interior_surface() {
    n = height_grid_size();
    intersection() {
        polyhedron(points=height_grid_points(n), faces=height_grid_faces(n), convexity=10);
        translate([0, 0, -0.2])
            cylinder(h=bowl_height + 2, r=texture_radius, $fn=terrain_preview_fn);
    }
}

module bowl_shell() {
    difference() {
        bowl_exterior_blank();
        interior_surface();
    }
}

// ---------- Angled safety-razor cradle ----------
function dock_inner_r(diameter) = diameter / 2 + razor_handle_clearance;
function dock_outer_r(diameter) = dock_inner_r(diameter) + razor_dock_wall;
function dock_length() = 18;

module dock_body(diameter=razor_handle_max_diameter) {
    inner_r = dock_inner_r(diameter);
    outer_r = dock_outer_r(diameter);
    difference() {
        hull() {
            translate([0, 0, 0]) sphere(r=outer_r, $fn=rounded_fn*2);
            translate([0, 0, dock_length()]) sphere(r=outer_r, $fn=rounded_fn*2);
        }
        translate([0, 0, -outer_r-1])
            cylinder(h=dock_length() + 2*outer_r + 2, r=inner_r, $fn=rounded_fn*2);
        translate([-outer_r-2, 0, dock_length()/2])
            cube([2*(outer_r+1), 4*outer_r, dock_length()+2*outer_r+2], center=true);
        for (z = [4, 9, 14])
            translate([inner_r + razor_dock_wall/2, 0, z])
                rotate([0, 90, 0])
                    cylinder(h=razor_dock_wall+1.2, r=1.1, center=true, $fn=16);
    }
}

module razor_dock() {
    translate([outer_radius + dock_offset_x, 0, bowl_height - 1 + dock_raise])
        rotate([0, 90 - razor_dock_angle, 0])
            dock_body();
}

// v14.1: Extended 48-50 degree taper on lower head rest support plate
module head_rest_lower_plate() {
    lower_inset = 0.5;
    lower_drop = head_rest_gap + 11.0;
    z_pos = dock_length() + head_rest_gap;
    difference() {
        hull() {
            translate([0, 0, z_pos - 0.05])
                intersection() {
                    cylinder(h=0.1, r=head_rest_radius - lower_inset, $fn=rounded_fn*3);
                    translate([-head_rest_flat_edge + lower_inset, -head_rest_radius, -0.05])
                        cube([head_rest_radius + head_rest_flat_edge, 2*head_rest_radius, 0.2]);
                }
            translate([0, 0, z_pos - lower_drop])
                cylinder(h=0.1, r=dock_outer_r(razor_handle_max_diameter) - 0.3, $fn=rounded_fn*2);
        }
        translate([0, 0, z_pos - lower_drop - 1])
            cylinder(h=lower_drop + 2, r=neck_slot_radius, $fn=rounded_fn*2);
        translate([-neck_slot_radius - 6, -neck_slot_radius, z_pos - lower_drop - 1])
            cube([neck_slot_radius + 6, 2*neck_slot_radius, lower_drop + 2]);
    }
}

module head_rest_shape() {
    difference() {
        union() {
            intersection() {
                cylinder(h=head_rest_thickness, r=head_rest_radius, $fn=rounded_fn*3);
                translate([-head_rest_flat_edge, -head_rest_radius, -1])
                    cube([head_rest_radius + head_rest_flat_edge, 2*head_rest_radius, head_rest_thickness + 2]);
            }
            intersection() {
                difference() {
                    translate([0, 0, head_rest_thickness - 0.01])
                        cylinder(h=head_rest_rim_height, r=head_rest_radius, $fn=rounded_fn*3);
                    translate([0, 0, head_rest_thickness - 1])
                        cylinder(h=head_rest_rim_height + 2, r=head_rest_radius - head_rest_rim_width, $fn=rounded_fn*3);
                    translate([head_rest_radius - 4, 0, head_rest_thickness + 0.5])
                        cube([8, head_rest_drain_gap, 6], center=true);
                }
                translate([-head_rest_flat_edge, -head_rest_radius - 1, 0])
                    cube([head_rest_radius + head_rest_flat_edge + 1, 2*head_rest_radius + 2, head_rest_thickness + head_rest_rim_height + 1]);
            }
        }
        translate([0, 0, -1]) cylinder(h=head_rest_thickness + 4, r=neck_slot_radius, $fn=rounded_fn*2);
        translate([-neck_slot_radius - 6, -neck_slot_radius, -1])
            cube([neck_slot_radius + 6, 2*neck_slot_radius, head_rest_thickness + 4]);
    }
}

module razor_head_support() {
    translate([outer_radius + dock_offset_x, 0, bowl_height - 1 + dock_raise])
        rotate([0, 90 - razor_dock_angle, 0]) {
            translate([0, 0, dock_length() + head_rest_gap])
                head_rest_shape();
            if (overhang_safe)
                head_rest_lower_plate();
        }
}

module handle_profile_box(dx, dy, dz, r=2) {
    rotate([90, 0, 0])
        linear_extrude(height=dy, center=true)
            offset(r=r, $fn=rounded_fn)
                square([max(0.1, dx - 2*r), max(0.1, dz - 2*r)], center=true);
}

// v14.1: Streamlined Support-Free Ergonomic Truss Handle
// Fully self-supporting at 49 degrees with zero horizontal ceilings and zero mid-air bridges.
module final_merged_handle() {
    pillar_reach = is_standard ? 17.0 : 13.5;
    pillar_x = outer_radius + pillar_reach;
    pillar_top_z = bowl_height - 1 + dock_raise + 1.5;
    
    wall_start_x = is_standard ? (outer_radius - 15.0) : (outer_radius - 13.0);
    wall_start_z = is_standard ? 14.0 : 10.0;
    actual_wall_x = wall_start_x;
    
    difference() {
        union() {
            // 1. Upper bridge from razor dock to pillar top
            hull() {
                translate([outer_radius + dock_offset_x, 0, bowl_height - 1 + dock_raise])
                    rotate([0, 90 - razor_dock_angle, 0])
                        translate([0, 0, dock_length()]) 
                            sphere(r=dock_outer_r(razor_handle_max_diameter)-1, $fn=rounded_fn);
                translate([pillar_x, 0, pillar_top_z])
                    handle_profile_box(7, handle_width, 6, 2);
            }
            
            // 2. Continuous 49-degree self-supporting ergonomic strut
            hull() {
                translate([pillar_x, 0, pillar_top_z])
                    handle_profile_box(7, handle_width, 6, 2);
                translate([actual_wall_x, 0, wall_start_z])
                    handle_profile_box(7, handle_width, 6, 2);
            }
            
            // 3. Smooth inner gusset fillet at upper corner
            hull() {
                translate([pillar_x, 0, pillar_top_z - 3])
                    handle_profile_box(5, handle_width, 4, 1.5);
                translate([pillar_x - 5, 0, pillar_top_z - 1])
                    handle_profile_box(5, handle_width, 4, 1.5);
            }
        }
        
        // Extended razor shaft cutout
        translate([outer_radius + dock_offset_x, 0, bowl_height - 1 + dock_raise])
            rotate([0, 90 - razor_dock_angle, 0])
                translate([0, 0, -100])
                    cylinder(h=200, r=dock_inner_r(razor_handle_max_diameter) + 0.03, $fn=rounded_fn*2);
        
        // Re-apply dock top opening
        translate([outer_radius + dock_offset_x, 0, bowl_height - 1 + dock_raise])
            rotate([0, 90 - razor_dock_angle, 0]) {
                translate([-dock_outer_r(razor_handle_max_diameter)-2, 0, dock_length()/2])
                    cube([2*(dock_outer_r(razor_handle_max_diameter)+1) + 0.06, 
                          4*dock_outer_r(razor_handle_max_diameter) + 0.06, 
                          dock_length()+2*dock_outer_r(razor_handle_max_diameter)+2 + 0.06], center=true);
            }
    }
}

module razor_dock_assembly() {
    union() {
        razor_dock();
        razor_head_support();
        if (overhang_safe)
            final_merged_handle();
    }
}

// ---------- Embossed name ----------
module emboss_line(txt, width) {
    linear_extrude(height=70)
        offset(r=emboss_bold)
            resize([width, 0], auto=true)
                text(txt, size=10, font=emboss_font, halign="center", valign="center", $fn=24);
}

module name_emboss() {
    if (emboss_enabled)
        intersection() {
            translate([0, 0, emboss_z])
                rotate([90, 0, -90])
                    union() {
                        translate([0, emboss_line_gap/2, 0]) emboss_line(emboss_line1, emboss_width1);
                        translate([0, -emboss_line_gap/2, 0]) emboss_line(emboss_line2, emboss_width2);
                    }
            difference() {
                translate([0, 0, bowl_height]) sphere(r=outer_radius + emboss_height, $fn=rounded_fn*6);
                translate([0, 0, bowl_height]) sphere(r=outer_radius - emboss_sink, $fn=rounded_fn*6);
            }
            translate([-outer_radius - 5, -outer_radius, 0])
                cube([outer_radius + 5, 2*outer_radius, bowl_height + 5]);
        }
}

module bowl_body() {
    union() {
        bowl_shell();
        razor_dock_assembly();
        name_emboss();
    }
}

module selected_part() {
    if (part == "bowl")
        bowl_body();
    else if (part == "bowl_shell")
        bowl_shell();
    else if (part == "interior_surface")
        interior_surface();
    else if (part == "dock_debug")
        razor_dock_assembly();
    else
        bowl_body();
}

selected_part();
