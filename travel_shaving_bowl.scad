use <fonts/Pacifico-Regular.ttf>

/*
 * Compact travel shaving bowl
 * Parametric, open bowl with a blended height-field lather surface, ergonomic
 * side grip, angled razor cradle, and an enclosed captive blade drawer.
 *
 * No lid or bowl-cover geometry is present.
 */

// ---------- Main dimensions (millimetres) ----------
bowl_outer_diameter = 88;
bowl_inner_diameter = 73.7;
bowl_height = 35;
wall_thickness = 3;
base_thickness = 3.5;
rim_width = 6;
complete_width_with_handle = 113;

// ---------- Height-field surface ----------
preview_mode = true;
preview_texture_resolution = 1.6;
export_texture_resolution = 0.8;
texture_seed = 4217;
texture_resolution = preview_mode ? preview_texture_resolution : export_texture_resolution;
diamond_length = 8;
diamond_width = 5;
diamond_spacing = 2;
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
handle_projection = 22;
handle_fillet = 4;
handle_fillet_radius = handle_fillet;

// ---------- Razor cradle ----------
razor_dock_angle = 25;
razor_handle_min_diameter = 8;
razor_handle_max_diameter = 15;
razor_handle_clearance = 1.0;
razor_dock_wall = 3.0;
dock_raise = 8;

// ---------- Razor head rest (half-round shelf) ----------
head_rest_radius = 24;
head_rest_thickness = 3.5;
head_rest_rim_height = 1.6;
head_rest_rim_width = 1.6;
head_rest_gap = 3;
neck_slot_radius = 6.5;
head_rest_flat_edge = 6;
head_rest_drain_gap = 5;

// ---------- Embossed name (raised text on the outer wall, side opposite the handle) ----------
// To change the font, edit emboss_font (any installed font name, e.g. "Liberation Sans:style=Bold").
emboss_enabled = true;
emboss_line1 = "Tumesh's";
emboss_line2 = "Travel Shaving Bowl";
emboss_bold = 0.15;
emboss_font = "Pacifico";
emboss_width1 = 34;
emboss_width2 = 48;
emboss_line_gap = 10;
emboss_z = 22;
emboss_height = 0.8;
emboss_sink = 0.4;
emboss_max_half_width = 25;

// ---------- Captive DE blade drawer ----------
de_blade_length = 43;
de_blade_width = 22;
de_blade_thickness = 0.25;
blade_clearance = 0.5;
blade_storage_count = 5;
drawer_wall = 1.2;
drawer_clearance = 0.3;
drawer_open_travel = 11.9;
drawer_pull_width = 12;
drawer_pull_height = 5;
drawer_pull_projection = 4;
detent_bump_radius = 0.65;
detent_flexure_length = 8;
detent_flexure_thickness = 0.9;
drawer_endstop_overlap = 1.0;

// ---------- Output selection ----------
// assembly, texture_test_coupon, razor_dock_test, blade_storage_test,
// handle_strength_test, top, side, bottom, texture_closeup, texture_section,
// handle_section, blade_section, razor_parked, blades_inside, emboss_test
render_mode = "assembly";
// assembly, bowl, bowl_shell, blade_drawer, texture_test, razor_dock_test,
// blade_storage_test, handle_strength_test, emboss_test
part = "assembly";
drawer_open = false;

// ---------- Derived dimensions ----------
outer_radius = bowl_outer_diameter / 2;
inner_radius = bowl_inner_diameter / 2;
texture_radius = inner_radius;
texture_fade_start = texture_radius - outer_smooth_width;
terrain_preview_fn = preview_mode ? 72 : 144;
rounded_fn = preview_mode ? 18 : 28;

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

// Broad, low-amplitude seeded features soften the regular drum pattern.
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

// A rotated, staggered rhombus field with smooth seeded size/height variation.
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
function inner_bowl_base_z(r) =
    let(sphere_z = inner_sphere_z(min(r, inner_radius)),
        blend = smoothstep(8.0, 15.0, r))
    base_thickness + blend * (sphere_z - base_thickness);

// ---------- Rounded primitives ----------
module rounded_box(size=[10,10,10], radius=2, facets=20) {
    minkowski() {
        cube(size - [2*radius, 2*radius, 2*radius], center=true);
        sphere(r=radius, $fn=facets);
    }
}

// ---------- Near-hemispherical bowl shell and textured cavity ----------
function outer_base_radius() =
    sqrt(max(0, outer_radius*outer_radius - bowl_height*bowl_height));
function outer_sphere_z(r) =
    bowl_height - sqrt(max(0, outer_radius*outer_radius - r*r));
function outer_bowl_z(r) =
    let(r0 = outer_base_radius(), r1 = r0 + 3.0)
    smoothstep(r0, r1, r) * outer_sphere_z(r);

module bowl_exterior_blank() {
    rotate_extrude($fn=terrain_preview_fn)
        polygon(points=concat(
            [[0, 0], [outer_base_radius(), 0]],
            [for (i = [1:40])
                let(r = outer_base_radius()
                        + (outer_radius - outer_base_radius()) * i / 40)
                [r, outer_bowl_z(r)]],
            [[0, bowl_height], [0, 0]]
        ));
}

// ---------- Closed height-field cavity cutter ----------
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

module macro_terrain() {
    interior_surface();
}
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
// ---------- Handle and its two attachment pads ----------
function grip_height() = min(handle_height, bowl_height);
function grip_center_z() = grip_height() / 2;
function grip_center_x() = outer_radius + handle_projection / 2;

module handle_junctions() {
    // The blade vault sits below these separated upper/lower structural pads.
    translate([outer_radius - 2.2, 0, 17.5])
        rounded_box([13, handle_width + 8, 11], 4, rounded_fn);
    translate([outer_radius - 1.8, 0, bowl_height - 6.5])
        rounded_box([14, handle_width + 8, 11], 4, rounded_fn);
}

module handle() {
    difference() {
        translate([grip_center_x(), 0, grip_center_z()])
            rounded_box([handle_projection + 7, handle_width, grip_height()], handle_fillet_radius, rounded_fn);
        translate([grip_center_x() + 0.8, 0, grip_center_z() + 1.2])
            rounded_box([handle_projection - 2, handle_width + 2, max(8, grip_height() - 10)], 3, rounded_fn);
    }
}

// ---------- Open-top angled safety-razor cradle ----------
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
        // Up-facing opening: the local negative-X direction rotates toward +Z.
        translate([-outer_r-2, 0, dock_length()/2])
            cube([2*(outer_r+1), 4*outer_r, dock_length()+2*outer_r+2], center=true);
        // Open drainage ports pass only to the exterior, never to the blade vault.
        for (z = [4, 9, 14])
            translate([inner_r + razor_dock_wall/2, 0, z])
                rotate([0, 90, 0])
                    cylinder(h=razor_dock_wall+1.2, r=1.1, center=true, $fn=16);
    }
}

module razor_dock() {
    translate([outer_radius + 2.0, 0, bowl_height - 1 + dock_raise])
        rotate([0, 90 - razor_dock_angle, 0])
            dock_body();
}

module razor_retention() {
    translate([outer_radius + 2.0, 0, bowl_height - 1 + dock_raise])
        rotate([0, 90 - razor_dock_angle, 0])
            for (side = [-1, 1])
                translate([-0.4, side * dock_inner_r(razor_handle_max_diameter) * 0.86, 8])
                    sphere(r=1.5, $fn=rounded_fn);
}

module razor_support_mounts() {
    for (side = [-1, 1])
        translate([outer_radius + 2.0, side * (handle_width/2 - 1), bowl_height - 1 + dock_raise])
            rounded_box([12, 4, 8], 1.5, rounded_fn);
}

module razor_head_support() {
    translate([outer_radius + 2.0, 0, bowl_height - 1 + dock_raise])
        rotate([0, 90 - razor_dock_angle, 0])
            translate([0, 0, dock_length() + head_rest_gap])
                head_rest_shape();
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

module razor_dock_assembly() {
    union() {
        razor_dock();
        razor_retention();
        razor_support_mounts();
        razor_head_support();
    }
}

// ---------- Dry blade vault and sliding tray ----------
function vault_center_x() = grip_center_x() + 2.5;
function vault_center_y() = 0;
function vault_width() = 30;
function vault_length() = 52;
function vault_height() = 13;
function drawer_inner_width() = de_blade_width + 2*blade_clearance;
function drawer_outer_width() = drawer_inner_width() + 2*drawer_wall;
function drawer_inner_length() = de_blade_length + 2*blade_clearance;
function drawer_outer_length() = drawer_inner_length() + 2*drawer_wall;
function drawer_outer_height() = 6.8;
function drawer_center_y(open=false) =
    vault_center_y()
    + (open ? min(drawer_open_travel, drawer_stop_travel()) : 0);
function drawer_z() = vault_height()/2 + 0.3;
function drawer_cavity_width() = drawer_outer_width() + 2*drawer_clearance;
function drawer_cavity_length() = drawer_outer_length() + 2*drawer_clearance;
function drawer_front_closed_y() = drawer_center_y(false) + drawer_outer_length()/2;
function vault_front_y() = vault_center_y() + vault_length()/2;
function drawer_channel_start_y() = drawer_center_y(false) + 12.0;
function drawer_channel_end_y() = vault_front_y() - 2.2;
function drawer_stop_travel() =
    drawer_channel_end_y() - 0.9 - drawer_center_y(false) - 13.0;
function drawer_tab_z() = drawer_z() + 1.9;
function drawer_tab_x() = drawer_outer_width()/2 + drawer_endstop_overlap;

module blade_storage_shell() {
    translate([vault_center_x(), vault_center_y(), vault_height()/2])
        rounded_box([vault_width(), vault_length(), vault_height()], 2.2, rounded_fn);
}

module blade_vault_void() {
    cavity_w = drawer_cavity_width();
    cavity_l = drawer_cavity_length();
    cavity_h = 7.8;
    cavity_front_y = drawer_center_y(false) + cavity_l/2;
    passage_length = vault_front_y() - cavity_front_y + 2.0;
    passage_center_y = (vault_front_y() + cavity_front_y)/2 + 1.0;
    translate([vault_center_x(), drawer_center_y(false), drawer_z()])
        cube([cavity_w, cavity_l, cavity_h], center=true);
    translate([vault_center_x(), passage_center_y, drawer_z()])
        cube([cavity_w, passage_length, cavity_h], center=true);
    // Side rails clear the drawer's stop tabs and terminate before the outlet.
    for (side = [-1, 1])
        translate([vault_center_x() + side*(cavity_w/2 + 0.35),
                   (drawer_channel_start_y() + drawer_channel_end_y())/2,
                   drawer_tab_z()])
            cube([1.4, drawer_channel_end_y() - drawer_channel_start_y(),
                  3.2], center=true);
    // The passive detent recesses are isolated from the wet razor dock.
    for (side = [-1, 1])
        translate([vault_center_x() + side*(cavity_w/2 + 0.32),
                   drawer_center_y(false), drawer_tab_z()])
            sphere(r=detent_bump_radius + 0.45, $fn=rounded_fn);
}

module blade_storage() {
    difference() {
        blade_storage_shell();
        blade_vault_void();
    }
}

module blade_drawer_detent() {
    for (side = [-1, 1]) {
        // Integral cantilever carries the bump; no separate spring or hardware.
        translate([vault_center_x() + side*(drawer_outer_width()/2
                                             - detent_flexure_thickness/2),
                   drawer_center_y(drawer_open) - 0.4,
                   drawer_z() + 1.7])
            cube([detent_flexure_thickness, detent_flexure_length, 2.6], center=true);
        translate([vault_center_x() + side*(drawer_outer_width()/2 + 0.16),
                   drawer_center_y(drawer_open), drawer_tab_z()])
            sphere(r=detent_bump_radius, $fn=rounded_fn);
    }
}

module blade_drawer_endstop() {
    for (side = [-1, 1])
        translate([vault_center_x() + side*(drawer_outer_width()/2
                                             + drawer_endstop_overlap/2),
                   drawer_center_y(drawer_open) + 13.0, drawer_tab_z()])
            rounded_box([drawer_endstop_overlap, 1.8, 2.4], 0.4, rounded_fn);
}

module blade_drawer_pull_tab() {
    translate([vault_center_x(), drawer_center_y(drawer_open)
                                  + drawer_outer_length()/2
                                  + drawer_pull_projection/2 - 0.4,
               drawer_z()])
        rounded_box([drawer_pull_width, drawer_pull_projection + 0.8,
                     drawer_pull_height], min(1.8, drawer_pull_height/2 - 0.1), rounded_fn);
}

module blade_drawer() {
    tray_w = drawer_outer_width();
    tray_l = drawer_outer_length();
    tray_h = drawer_outer_height();
    tray_z = drawer_z();
    tray_y = drawer_center_y(drawer_open);
    union() {
        difference() {
            translate([vault_center_x(), tray_y, tray_z])
                rounded_box([tray_w, tray_l, tray_h], 1.0, rounded_fn);
            // Recess leaves a robust floor while keeping the blades below the rim.
            translate([vault_center_x(), tray_y, tray_z + 1.3])
                cube([drawer_inner_width(), drawer_inner_length(), tray_h + 1], center=true);
            // Slots isolate two passive cantilevers carrying the detent bumps.
            for (side = [-1, 1])
                translate([vault_center_x() + side*tray_w/2, tray_y + 0.4,
                           tray_z])
                    cube([drawer_wall + 0.5, detent_flexure_length + 0.8,
                          tray_h + 0.6], center=true);
        }
        blade_drawer_detent();
        blade_drawer_endstop();
        blade_drawer_pull_tab();
    }
}

module blade_stack(count, tray_y, tray_z) {
    stack_spacing = de_blade_thickness + 0.12;
    for (i = [0:count-1])
        translate([vault_center_x(), tray_y,
                   tray_z - drawer_outer_height()/2 + 1.3
                   + de_blade_thickness/2 + i*stack_spacing])
            cube([de_blade_width - 0.4, de_blade_length - 0.4, de_blade_thickness], center=true);
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

module emboss_test() {
    intersection() {
        bowl_body();
        translate([-outer_radius - 2, -30, emboss_z - 12]) cube([14, 60, 24]);
    }
}

module bowl_body() {
    difference() {
        union() {
            bowl_shell();
            handle_junctions();
            handle();
            blade_storage_shell();
            razor_dock_assembly();
            name_emboss();
        }
        blade_vault_void();
    }
}

module assembly_preview() {
    union() {
        bowl_body();
        blade_drawer();
    }
}

// ---------- Independent test coupons ----------
function coupon_id(x, y) =
    let(col = min(3, max(0, floor((x + 20) / 10))),
        row = min(1, max(0, floor((y + 20) / 20))))
    row * 4 + col;
function coupon_lx(x) = x - (-15 + 10 * min(3, max(0, floor((x + 20) / 10))));
function coupon_ly(y) = y - (-10 + 20 * min(1, max(0, floor((y + 20) / 20))));
function coupon_height(x, y) =
    let(id = coupon_id(x, y),
        lx = coupon_lx(x),
        ly = coupon_ly(y),
        hill = 1.5 * exp(-((lx+0.5)^2 + (ly-1)^2) / 18),
        valley = -1.5 * exp(-((lx-0.5)^2 + (ly+1)^2) / 12),
        deep = -3.0 * exp(-((lx+0.8)^2 + (ly-0.5)^2) / 18),
        diamond = 0.72 * diamond_texture(lx, ly),
        fade = 1 - smoothstep(5.0, 9.5, sqrt(lx*lx + ly*ly)))
    id == 0 ? 0 :
    id == 1 ? hill :
    id == 2 ? valley :
    id == 3 ? deep :
    id == 4 ? diamond :
    id == 5 ? hill + diamond :
    id == 6 ? valley + 0.55*diamond :
    fade * (macro_hills(lx*0.55, ly*0.55) + diamond);

function coupon_points(n) =
    let(side = n+1, count = side*side, step = 40/n)
    concat(
        [for (j = [0:n], i = [0:n])
            let(x = -20+i*step, y = -20+j*step)
            [x, y, 10 + coupon_height(x, y)]],
        [for (j = [0:n], i = [0:n])
            let(x = -20+i*step, y = -20+j*step)
            [x, y, 0]]
    );
function coupon_faces(n) =
    let(side = n+1, count = side*side,
        perimeter = concat(
            [for (i = [0:n]) i],
            [for (j = [1:n]) j*(n+1)+n],
            [for (i = [n-1:-1:0]) n*(n+1)+i],
            [for (j = [n-1:-1:1]) j*(n+1)]))
    concat(
        [for (j = [0:n-1], i = [0:n-1], tri = [0:1])
            let(k = j*side+i)
            tri == 0 ? [k,k+1,k+side+1] : [k,k+side+1,k+side]],
        [for (j = [0:n-1], i = [0:n-1], tri = [0:1])
            let(k = j*side+i+count)
            tri == 0 ? [k,k+side+1,k+1] : [k,k+side,k+side+1]],
        [for (k = [0:len(perimeter)-1], tri = [0:1])
            let(a = perimeter[k], b = perimeter[(k+1)%len(perimeter)])
            tri == 0 ? [a,b+count,b] : [a,a+count,b+count]]
    );

module texture_test_coupon() {
    n = max(24, ceil(40 / texture_resolution));
    polyhedron(points=coupon_points(n), faces=coupon_faces(n), convexity=10);
}

module dock_sample(diameter, x_offset) {
    translate([x_offset, 0, 0])
        rotate([0, 90 - razor_dock_angle, 0])
            union() {
                dock_body(diameter);
                for (side = [-1, 1])
                    translate([-0.4, side*dock_inner_r(diameter)*0.86, 8])
                        sphere(r=1.5, $fn=rounded_fn);
                translate([0,0,dock_length()+head_rest_gap])
                    head_rest_shape();
            }
}

module razor_dock_test() {
    diameters = [8,10,12,15];
    for (i = [0:3])
                dock_sample(diameters[i], i*54);
}

module blade_storage_test() {
    for (i = [1:3]) {
        offset_x = (i-2) * 34;
        translate([offset_x-vault_center_x(), 0, 0]) {
            blade_storage();
            blade_drawer();
            blade_stack(i == 1 ? 1 : i == 2 ? 3 : 5,
                        drawer_center_y(false), drawer_z());
        }
    }
}

module handle_strength_test() {
    bowl_body();
}

module parked_razor() {
    translate([outer_radius + 2.0, 0, bowl_height - 1 + dock_raise])
        rotate([0, 90 - razor_dock_angle, 0]) {
            translate([0,0,3])
                cylinder(h=dock_length() + head_rest_gap + 2, r=5.4, $fn=48);
            translate([0,0,dock_length() + head_rest_gap + head_rest_thickness + 0.2 + 3.5])
                rounded_box([9, 42, 7], 1.4, 24);
        }
}

// ---------- View and section modes ----------
module scene() {
    if (render_mode == "texture_test_coupon")
        texture_test_coupon();
    else if (render_mode == "razor_dock_test")
        razor_dock_test();
    else if (render_mode == "blade_storage_test")
        blade_storage_test();
    else if (render_mode == "handle_strength_test")
        handle_strength_test();
    else if (render_mode == "razor_parked") {
        assembly_preview();
        parked_razor();
    }
    else if (render_mode == "blades_inside") {
        assembly_preview();
        blade_stack(blade_storage_count, drawer_center_y(drawer_open), vault_height()/2 + 0.3);
    }
    else if (render_mode == "texture_section")
        difference() {
            assembly_preview();
            translate([0, 50, 24]) cube([120, 100, 60], center=true);
        }
    else if (render_mode == "handle_section")
        difference() {
            assembly_preview();
            translate([grip_center_x() + 45, 0, 24])
                cube([90, 100, 60], center=true);
        }
    else if (render_mode == "blade_section")
        difference() {
            union() {
                assembly_preview();
                blade_stack(blade_storage_count, drawer_center_y(false), vault_height()/2 + 0.3);
            }
            translate([vault_center_x()+50, 0, 7]) cube([100, 100, 30], center=true);
        }
    else
        assembly_preview();
}

module selected_part() {
    if (part == "bowl")
        bowl_body();
    else if (part == "bowl_shell")
        bowl_shell();
    else if (part == "blade_drawer")
        blade_drawer();
    else if (part == "texture_test")
        texture_test_coupon();
    else if (part == "razor_dock_test")
        razor_dock_test();
    else if (part == "blade_storage_test")
        blade_storage_test();
    else if (part == "handle_strength_test")
        handle_strength_test();
    else if (part == "emboss_test")
        emboss_test();
    else
        scene();
}

if (render_mode == "texture_closeup" && part == "assembly")
    intersection() {
        selected_part();
        translate([0, 0, nominal_floor_z + 0.5]) cube([48, 48, 24], center=true);
    }
else
    selected_part();
