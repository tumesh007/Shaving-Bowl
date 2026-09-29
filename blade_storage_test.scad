/*
 * blade_storage_test.scad
 * Blade drawer and storage validation fixture.
 */

de_blade_length = 43;
de_blade_width = 22;
de_blade_thickness = 0.25;
blade_clearance = 0.4;

module drawer_for(blade_count) {
    difference() {
        cube([de_blade_width + 4, 24, 8], center=true);
        translate([0,0,1])
            cube([de_blade_width, 20, 6], center=true);
    }

    if (blade_count > 0) {
        translate([0, -8, 1.5])
            for (i = [0:blade_count-1]) {
                translate([0, i * 0.7, 0])
                    cube([de_blade_width, de_blade_length, de_blade_thickness], center=true);
            }
    }
}

// Empty drawer
translate([-30,0,0]) drawer_for(0);
// 3 blades
translate([0,0,0]) drawer_for(3);
// 5 blades
translate([30,0,0]) drawer_for(5);
