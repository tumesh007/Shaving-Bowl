/*
 * razor_dock_test.scad
 * Test four handle diameters in a single dock validation fixture.
 */

razor_dock_angle = 25;
razor_handle_clearance = 1.0;

module dock_for(diameter) {
    translate([diameter * 2.0, 0, 0])
    rotate([0, -razor_dock_angle, 0])
        difference() {
            hull() {
                translate([0, 0, 0])
                    rotate([90,0,0])
                        cylinder(h = 4, r = diameter/2 + razor_handle_clearance, center=true, $fn=48);
                translate([0, 0, 16])
                    rotate([90,0,0])
                        cylinder(h = 4, r = diameter/2 + razor_handle_clearance, center=true, $fn=48);
            }
            translate([0, 0, 0])
                rotate([90,0,0])
                    cylinder(h = 6, r = diameter/2, center=true, $fn=48);
            translate([0,0,6])
                cube([diameter + 5, 5, 20], center=true);
        }
}

for (d = [8,10,12,15]) {
    dock_for(d);
}
