/*
 * handle_strength_test.scad
 * Simplified test for broad upper/lower junctions and grip region.
 */

module broad_junction() {
    cube([30, 18, 12], center=true);
}

module grip_section() {
    cube([20, 14, 18], center=true);
}

union() {
    translate([0, 0, 16]) broad_junction();
    grip_section();
    translate([0, 0, -16]) broad_junction();
}
