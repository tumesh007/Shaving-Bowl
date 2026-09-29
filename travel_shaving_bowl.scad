/*
 * travel_shaving_bowl.scad
 * Compact travel shaving bowl with side handle, razor dock, and blade drawer.
 * No lid geometry is included.
 */

include_lid = false;
render_mode = "assembly";

// Main bowl dimensions
bowl_outer_diameter = 80;
bowl_inner_diameter = 67;
bowl_height = 35;
wall_thickness = 3;
base_thickness = 3.5;
rim_width = 6;
interior_depth = 22;

// Hybrid terrain
diamond_length = 8;
diamond_width = 5;
diamond_spacing = 2;
diamond_ridge_height = 1.0;
diamond_channel_depth = 1.2;
hill_height = 1.8;
valley_height = -2.5;
deep_valley_height = -4.5;
feature_radius = 6.0;
seed = 42;
edge_attenuation = 5.0;

// Handle
handle_width = 20;
handle_height = 40;
handle_projection = 22;
handle_fillet = 4;
handle_joint_radius = 4;

// Razor dock
razor_dock_angle = 25;
razor_handle_min_diameter = 8;
razor_handle_max_diameter = 15;
razor_handle_clearance = 1.0;
razor_dock_depth = 4;

// Blade drawer
blade_storage_count = 5;
de_blade_length = 43;
de_blade_width = 22;
de_blade_thickness = 0.25;
blade_clearance = 0.4;

function rand01(v) = fract(sin(v * 127.1 + 311.7) * 43758.5453123);
function rand_signed(v) = rand01(v) * 2 - 1;
function fract(v) = v - floor(v);

module rounded_box(size=[10,10,10], r=2, $fn=32) {
    minkowski() {
        cube(size - [2*r,2*r,2*r], center=true);
        sphere(r=r, $fn=$fn);
    }
}

module bowl_profile() {
    outer_r = bowl_outer_diameter / 2;
    inner_r = bowl_inner_diameter / 2;
    polygon([
        [outer_r, 0],
        [outer_r, bowl_height - rim_width],
        [outer_r - 1.0, bowl_height],
        [inner_r + wall_thickness, bowl_height],
        [inner_r + wall_thickness - 0.8, bowl_height - 1.0],
        [inner_r + wall_thickness - 0.3, interior_depth],
        [inner_r - 1.0, interior_depth - 2.0],
        [0, interior_depth - 2.4],
        [0, base_thickness],
        [outer_r, base_thickness]
    ]);
}

module bowl_shell() {
    difference() {
        rotate_extrude($fn=180)
            bowl_profile();

        // Hollow inner volume
        translate([0, 0, base_thickness])
            cylinder(h = bowl_height, r = bowl_inner_diameter/2 - 0.3, $fn=180);

        // Slightly trim the underside to create a flat stable base
        translate([0,0,-0.1])
            cylinder(h = base_thickness + 0.2, r = bowl_outer_diameter/2 - 1.0, $fn=180);
    }
}

module interior_base() {
    translate([0,0,base_thickness])
        cylinder(h = 0.8, r = bowl_inner_diameter/2 - wall_thickness - 0.4, $fn=180);
}

module macro_hills() {
    inner_r = bowl_inner_diameter/2 - wall_thickness;
    for (i = [0:11]) {
        ang = i * (360/12) + rand_signed(seed + i * 19) * 22;
        dist = inner_r * (0.25 + rand01(seed + i * 13) * 0.56);
        x = cos(ang) * dist;
        y = sin(ang) * dist;
        translate([x, y, interior_depth - 1.4])
            sphere(r = feature_radius * (0.8 + rand01(seed + i * 17) * 0.5), $fn=24);
    }
}

module macro_valleys() {
    inner_r = bowl_inner_diameter/2 - wall_thickness;
    for (i = [0:9]) {
        ang = i * (360/9) + rand_signed(seed + 100 + i * 23) * 18;
        dist = inner_r * (0.28 + rand01(seed + 200 + i * 15) * 0.54);
        x = cos(ang) * dist;
        y = sin(ang) * dist;
        translate([x, y, interior_depth - 2.8])
            sphere(r = feature_radius * (0.65 + rand01(seed + 300 + i * 11) * 0.8), $fn=20);
    }
}

module diamond_texture() {
    inner_r = bowl_inner_diameter/2 - wall_thickness;
    for (y = [-18:18]) {
        for (x = [-18:18]) {
            px = x * (diamond_length + diamond_spacing);
            py = y * (diamond_length + diamond_spacing);
            if (px*px + py*py > inner_r*inner_r) continue;
            offset = (y % 2 == 0) ? 0 : (diamond_length + diamond_spacing) / 2.0;

            translate([px + offset, py, interior_depth - 1.7])
                rotate([0, 0, 45])
                    scale([diamond_length * 0.55, diamond_width * 0.55, 1])
                        cylinder(h = 1.0, r = 1.2, $fn=4, center=true);
        }
    }
}

module hybrid_texture() {
    union() {
        macro_hills();
        macro_valleys();
        diamond_texture();
    }
}

module texture_transition() {
    inner_r = bowl_inner_diameter/2 - wall_thickness;
    difference() {
        cylinder(h = 1.8, r = inner_r, center=true, $fn=180);
        cylinder(h = 2.0, r = inner_r - edge_attenuation, center=true, $fn=180);
    }
}

module drainage_channels() {
    for (a = [0:120:360]) {
        rotate([0,0,a])
            translate([0, -2.0, interior_depth - 2.0])
                scale([1, 4.0, 0.25])
                    cylinder(h = 1.5, r = 4.0, $fn=24, center=true);
    }
}

module handle() {
    hull() {
        translate([0, -handle_projection * 0.8, bowl_height - 12])
            rounded_box([handle_width + 8, handle_projection * 0.9, 12], r = 4, $fn=36);
        translate([0, -handle_projection * 0.25, bowl_height - 18])
            rounded_box([handle_width, handle_projection * 0.7, 14], r = 3, $fn=36);
        translate([0, -handle_projection * 0.8, bowl_height - 30])
            rounded_box([handle_width + 8, handle_projection * 0.9, 12], r = 4, $fn=36);
    }
}

module handle_junctions() {
    translate([0, -handle_projection * 0.8, bowl_height - 12])
        rounded_box([handle_width + 12, handle_projection * 1.15, 14], r = 5, $fn=36);
    translate([0, -handle_projection * 0.8, bowl_height - 29])
        rounded_box([handle_width + 12, handle_projection * 1.15, 14], r = 5, $fn=36);
}

module razor_dock() {
    translate([0, -handle_projection * 0.55, bowl_height - 11])
    rotate([0, -razor_dock_angle, 0])
        difference() {
            hull() {
                translate([0, 0, 0])
                    rotate([90,0,0])
                        cylinder(h = razor_dock_depth, r = razor_handle_max_diameter / 2 + razor_handle_clearance, center=true, $fn=64);
                translate([0, 0, 18])
                    rotate([90,0,0])
                        cylinder(h = razor_dock_depth, r = razor_handle_max_diameter / 2 + razor_handle_clearance, center=true, $fn=64);
            }
            translate([0, 0, 0])
                rotate([90,0,0])
                    cylinder(h = razor_dock_depth + 2, r = razor_handle_max_diameter / 2, center=true, $fn=64);
            translate([0, 0, 7])
                cube([12, razor_dock_depth + 3, 24], center=true);
        }
}

module razor_retention() {
    translate([0, -handle_projection * 0.55, bowl_height - 11])
    rotate([0, -razor_dock_angle, 0]) {
        for (x = [-1, 1]) {
            translate([x * (razor_handle_max_diameter / 2 + 1), 0, 9])
                rotate([90,0,0])
                    cylinder(h = 3.5, r = 1.4, center=true, $fn=24);
        }
    }
}

module razor_head_support() {
    translate([0, -handle_projection * 0.55, bowl_height - 11])
    rotate([0, -razor_dock_angle, 0])
        translate([0, 0, 16])
            cube([9, 3, 4], center=true);
}

module blade_storage() {
    translate([0, -handle_projection * 0.3, 4])
        rounded_box([de_blade_width + 2, 28, 11], r=2, $fn=28);
}

module blade_drawer() {
    difference() {
        translate([0, -handle_projection * 0.3, 5])
            rounded_box([de_blade_width + blade_clearance * 2, 24, 8], r=2, $fn=28);
        translate([0, -handle_projection * 0.3, 6])
            rounded_box([de_blade_width, 20, 6], r=1.6, $fn=28);
    }
}

module blade_retainer() {
    translate([0, -handle_projection * 0.45, 5])
        cube([de_blade_width + 5, 2.5, 11], center=true);
}

module assembly_preview() {
    color([0.8,0.84,0.9,1]) bowl_shell();
    color([0.7,0.9,0.95,0.7]) translate([0,0,base_thickness]) hybrid_texture();
    color([0.7,0.72,0.74,1]) handle();
    color([0.74,0.76,0.8,1]) handle_junctions();
    color([0.97,0.74,0.33,1]) razor_dock();
    color([0.94,0.68,0.25,1]) razor_retention();
    color([0.88,0.60,0.20,1]) razor_head_support();
    color([0.55,0.58,0.62,1]) blade_drawer();
}

if (render_mode == "assembly") {
    assembly_preview();
} else if (render_mode == "texture_coupon") {
    // This file is used for bowl texture preview; kept intentionally simple.
    cube([40,40,2], center=true);
} else if (render_mode == "dock_test") {
    for (d = [8,10,12,15]) {
        translate([d*2.0, 0, 0]) razor_dock();
    }
} else if (render_mode == "blade_test") {
    blade_drawer();
    translate([30,0,0]) blade_storage();
} else if (render_mode == "handle_test") {
    handle();
    handle_junctions();
} else {
    assembly_preview();
}

// required public modules
// bowl_profile();
// bowl_shell();
// interior_base();
// macro_hills();
// macro_valleys();
// diamond_texture();
// hybrid_texture();
// texture_transition();
// drainage_channels();
// handle();
// handle_junctions();
// razor_dock();
// razor_retention();
// razor_head_support();
// blade_storage();
// blade_drawer();
// blade_retainer();
// assembly_preview();
