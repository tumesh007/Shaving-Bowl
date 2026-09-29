/*
 * texture_test_coupon.scad
 * Flat coupon with hill, valley, deep valley, and diamond texture for inspection.
 */

diamond_length = 8;
diamond_width = 5;
diamond_spacing = 2;

module diamond_pattern() {
    for (y = [-12:3:12]) {
        for (x = [-12:3:12]) {
            translate([x, y, 0])
                rotate([0,0,45])
                    scale([diamond_length * 0.6, diamond_width * 0.6, 1])
                        cylinder(h = 0.9, r = 1.1, $fn = 4, center = true);
        }
    }
}

module hill() {
    translate([-12, 12, 0])
        sphere(r = 8, $fn = 28);
}

module valley() {
    translate([12, -12, 0])
        sphere(r = 9, $fn = 28);
}

module deep_valley() {
    translate([-12, -12, 0])
        sphere(r = 12, $fn = 30);
}

difference() {
    cube([40,40,2], center=true);
    hill();
    valley();
    deep_valley();
    translate([12, 12, 0]) diamond_pattern();
}
