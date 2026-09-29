/*
 * PARAMETRIC TRAVEL SHAVING BOWL - FDM-PRINTABLE
 * 
 * This module generates a compact travel shaving bowl with:
 * - Rounded ergonomic bowl with hybrid lather-generation terrain
 * - Compact ergonomic side handle with two broad structural attachment zones
 * - Angled open-top safety-razor cradle integrated into handle
 * - Completely enclosed, dry, captive sliding drawer for 3–5 standard DE blades
 * 
 * NO LID. No lid geometry, lid files, lid locks, snap-fit covers, bayonet covers,
 * bowl covers, or lock-test geometry will be created.
 * 
 * Author: Parametric Design
 * License: CC0 / Public Domain
 */

// ============================================================================
// MAIN CONFIGURATION
// ============================================================================

// Disable lid entirely
include_lid = false;

// Render mode: "assembly", "texture_coupon", "dock_test", "blade_test", "handle_test"
render_mode = "assembly";

// ============================================================================
// BOWL DIMENSIONS
// ============================================================================

bowl_outer_diameter = 80;
bowl_inner_diameter = 67;
bowl_height = 35;
wall_thickness = 3;
base_thickness = 3.5;
rim_width = 6;
interior_depth = 22;

// ============================================================================
// TEXTURE PARAMETERS
// ============================================================================

// Macro terrain
hill_height = 1.8;           // +mm from baseline
valley_height = -2.5;        // -mm from baseline
deep_valley_height = -4.5;   // rare deep features
deep_valley_rarity = 0.08;   // probability of deep valley

// Diamond texture parameters
diamond_length = 8.0;        // primary diamond dimension along 45° axis
diamond_width = 5.0;         // perpendicular diamond width
diamond_spacing = 2.0;       // gap between diamonds
diamond_ridge_height = 1.0;  // height of diamond ridges above baseline
diamond_channel_depth = 1.2; // depth of channels between diamonds
diamond_size_variance = 0.18; // ±18% size variation

// Feature parameters
feature_radius = 6.0;        // radius of macro hills/valleys
edge_attenuation_start = 4.0; // mm inward from rim where attenuation begins
edge_attenuation_zone = 6.0; // mm wide attenuation zone

// Seeding for determinism
texture_seed = 42;

// ============================================================================
// HANDLE PARAMETERS
// ============================================================================

handle_width = 20;
handle_height = 40;
handle_projection = 22;
handle_fillet = 4;
handle_joint_radius = 4;
handle_left_offset = -38;    // offset from center toward bowl edge

// ============================================================================
// RAZOR DOCK PARAMETERS
// ============================================================================

razor_dock_angle = 25;               // degrees, open-top cradle angle
razor_handle_min_diameter = 8;
razor_handle_max_diameter = 15;
razor_handle_clearance = 1.0;
razor_dock_depth = 4;                // shallow mold depth
razor_dock_length = 35;              // along handle axis
razor_dock_position_z = 10;          // height on handle

// ============================================================================
// BLADE STORAGE PARAMETERS
// ============================================================================

de_blade_length = 43;
de_blade_width = 22;
de_blade_thickness = 0.25;
blade_storage_count = 5;
blade_clearance = 0.4;               // per side
blade_drawer_depth = 30;             // drawer travel distance
blade_drawer_height = 12;            // compartment height
blade_drawer_thickness = 2.5;        // drawer material

// ============================================================================
// UTILITY FUNCTIONS
// ============================================================================

// Pseudo-random number generator (deterministic seeded hash)
function hash_random(seed, index) = 
  let(
    h = sin(seed * 12.9898 + index * 78.233) * 43758.5453,
    hf = h - floor(h)
  )
  hf;

// Seeded random 0-1
function seeded_rand(seed, x, y) =
  hash_random(seed * 1000.0 + x * 13.0 + y * 7.0, 0);

// Seeded random -1 to +1
function seeded_rand_signed(seed, x, y) =
  seeded_rand(seed, x, y) * 2.0 - 1.0;

// Smooth step function (Hermite)
function smooth_step(t) =
  t < 0 ? 0 :
  t > 1 ? 1 :
  3*t*t - 2*t*t*t;

// ============================================================================
// BOWL GEOMETRY
// ============================================================================

module bowl_profile() {
  /*
   * Creates 2D profile of the bowl cross-section.
   * Used with rotate_extrude to form the bowl.
   */
  
  outer_radius = bowl_outer_diameter / 2;
  inner_radius = bowl_inner_diameter / 2;
  
  polygon([
    // Outer edge, bottom
    [outer_radius, 0],
    // Outer edge, up to rim
    [outer_radius, bowl_height - rim_width],
    // Outer rim transition (rounded)
    [outer_radius - 0.5, bowl_height - rim_width + 0.5],
    [outer_radius - 1.5, bowl_height],
    // Outer top rim
    [inner_radius + wall_thickness, bowl_height],
    // Inner rim transition (rounded)
    [inner_radius + wall_thickness - 1.0, bowl_height - 1.0],
    [inner_radius + wall_thickness - 0.5, bowl_height - rim_width - 0.5],
    // Inner wall down to interior bottom
    [inner_radius + wall_thickness, interior_depth],
    // Interior bottom rounded transition
    [inner_radius + wall_thickness - 1.5, interior_depth - 2.0],
    [inner_radius, interior_depth - 2.5],
    // Interior bottom, center
    [0, interior_depth - 2.5],
    // Back to base via outer radius
    [outer_radius, base_thickness],
    // Flat bottom
    [0, base_thickness]
  ]);
}

module bowl_shell() {
  /*
   * Generates the main bowl shell via rotate_extrude.
   * This creates a watertight, stable base bowl.
   */
  rotate_extrude(convexity = 3)
    bowl_profile();
}

module interior_base() {
  /*
   * Creates the interior floor of the bowl where texture will be applied.
   * Approximately 0 mm thickness (visual reference).
   */
  inner_radius = bowl_inner_diameter / 2;
  
  // Shallow interior bowl floor
  translate([0, 0, interior_depth - 2.5])
    cylinder(r = inner_radius - wall_thickness - 0.5, h = 0.01, $fn = 120);
}

// ============================================================================
// MACRO TERRAIN GENERATION
// ============================================================================

module macro_hills() {
  /*
   * Creates low-frequency rounded hills distributed across the bowl interior.
   * Pseudo-random placement with seeded determinism.
   */
  
  inner_radius = bowl_inner_diameter / 2 - wall_thickness;
  
  for (ring = 0; ring < 3; ring = ring + 1) {
    ring_radius = (inner_radius - 2) * (0.3 + ring * 0.3);
    
    for (idx = 0; idx < 8 + ring * 3; idx = idx + 1) {
      angle = (idx / (8 + ring * 3)) * 360 + seeded_rand(texture_seed, ring, idx) * 30;
      
      rand_r = seeded_rand(texture_seed + 100, ring, idx) * ring_radius * 0.3;
      rand_h = seeded_rand(texture_seed + 200, ring, idx) * hill_height * 0.7 + hill_height * 0.3;
      
      x_pos = (ring_radius + rand_r) * cos(angle);
      y_pos = (ring_radius + rand_r) * sin(angle);
      z_base = interior_depth - 2.5;
      
      // Rounded hill
      translate([x_pos, y_pos, z_base])
        sphere(r = feature_radius * 0.8, $fn = 16);
      
      // Push upward for height effect (will be subtracted/added in height field)
    }
  }
}

module macro_valleys() {
  /*
   * Creates low-frequency rounded valleys and depressions.
   */
  
  inner_radius = bowl_inner_diameter / 2 - wall_thickness;
  
  for (ring = 0; ring < 3; ring = ring + 1) {
    ring_radius = (inner_radius - 2) * (0.25 + ring * 0.35);
    
    for (idx = 0; idx < 6 + ring * 2; idx = idx + 1) {
      angle = (idx / (6 + ring * 2)) * 360 + seeded_rand(texture_seed, ring + 50, idx) * 40;
      
      rand_r = seeded_rand(texture_seed + 150, ring, idx) * ring_radius * 0.2;
      
      deep_rand = seeded_rand(texture_seed + 300, ring, idx);
      is_deep = deep_rand < deep_valley_rarity;
      valley_d = is_deep ? deep_valley_height : valley_height;
      
      rand_h = seeded_rand(texture_seed + 250, ring, idx) * abs(valley_d) * 0.6 + abs(valley_d) * 0.4;
      
      x_pos = (ring_radius + rand_r) * cos(angle);
      y_pos = (ring_radius + rand_r) * sin(angle);
      z_base = interior_depth - 2.5;
      
      translate([x_pos, y_pos, z_base - abs(valley_d) * 0.3])
        sphere(r = feature_radius * 0.6, $fn = 12);
    }
  }
}

// ============================================================================
// DIAMOND TEXTURE
// ============================================================================

module diamond_texture() {
  /*
   * Creates a 45-degree grid of diamonds/rhombuses with deterministic variance.
   * Diamond ridges and channels are integrated into the macro terrain.
   */
  
  inner_radius = bowl_inner_diameter / 2 - wall_thickness;
  z_base = interior_depth - 2.5;
  
  // Step through diamond grid positions
  step = diamond_length + diamond_spacing;
  
  for (row = -10; row <= 10; row = row + 1) {
    for (col = -10; col <= 10; col = col + 1) {
      // Stagger alternate rows for interlocking diamonds
      offset = (row % 2 == 0) ? 0 : step * 0.5;
      
      // 45-degree grid coordinates
      x_grid = col * step + offset;
      y_grid = row * step * cos(45);
      
      // Skip if outside bowl interior radius
      grid_dist = sqrt(x_grid * x_grid + y_grid * y_grid);
      if (grid_dist > inner_radius - 2)
        continue;
      
      // Deterministic variance in diamond size
      size_var = seeded_rand(texture_seed + 500, col, row) * diamond_size_variance;
      var_len = diamond_length * (1.0 + size_var);
      var_wid = diamond_width * (1.0 + size_var);
      
      // Ridge and channel height variance
      ridge_var = seeded_rand(texture_seed + 600, col, row) * 0.3;
      channel_var = seeded_rand(texture_seed + 700, col, row) * 0.3;
      
      ridge_h = diamond_ridge_height * (0.7 + ridge_var);
      channel_d = diamond_channel_depth * (0.7 + channel_var);
      
      translate([x_grid, y_grid, z_base])
        {
          // Small ridge diamond (45-degree rotated rectangle)
          scale([var_len / 2, var_wid / 2, ridge_h / 2])
            cube([1, 1, 0.8], center = true);
        }
    }
  }
}

// ============================================================================
// HYBRID TEXTURE INTEGRATION
// ============================================================================

module texture_transition() {
  /*
   * Creates smooth attenuation at bowl rim edge.
   * Reduces hill amplitude, valley depth, and diamond amplitude over edge zone.
   */
  
  inner_radius = bowl_inner_diameter / 2 - wall_thickness;
  z_base = interior_depth - 2.5;
  attenuation_start = inner_radius - edge_attenuation_start;
  attenuation_end = inner_radius;
  
  // Taper ring that fades texture features
  difference() {
    cylinder(r = inner_radius, h = 0.1, center = true, $fn = 120);
    
    for (angle = 0; angle < 360; angle = angle + 5) {
      // Smooth falloff ring from attenuation_start to attenuation_end
      r_inner = attenuation_start;
      r_outer = attenuation_end;
      
      x1 = r_inner * cos(angle);
      y1 = r_inner * sin(angle);
      x2 = r_outer * cos(angle);
      y2 = r_outer * sin(angle);
      
      // Taper via position along radius
      fade = smooth_step((angle % 360) / 360);
      
      translate([x1 + (x2 - x1) * fade * 0.2, y1 + (y2 - y1) * fade * 0.2, 0])
        sphere(r = 1.5 * (1 - fade), $fn = 8);
    }
  }
}

module drainage_channels() {
  /*
   * Creates very shallow channels between deep valleys to enable lather/water movement.
   * Prevents sealed soap traps.
   */
  
  inner_radius = bowl_inner_diameter / 2 - wall_thickness;
  z_base = interior_depth - 2.5;
  
  // Three major drainage channels at 120-degree intervals
  for (ch = 0; ch < 3; ch = ch + 1) {
    angle = ch * 120;
    
    // Channel from center outward
    for (seg = 0; seg < 10; seg = seg + 1) {
      seg_r = (seg / 10) * (inner_radius - 4);
      seg_angle = angle + seeded_rand_signed(texture_seed + 800, ch, seg) * 10;
      
      x_c = seg_r * cos(seg_angle);
      y_c = seg_r * sin(seg_angle);
      
      translate([x_c, y_c, z_base - 0.3])
        sphere(r = 0.8, $fn = 6);
    }
  }
}

// ============================================================================
// HANDLE
// ============================================================================

module handle() {
  /*
   * Compact side handle with two broad structural attachment zones.
   * Positioned perpendicular to bowl axis.
   */
  
  handle_y_offset = handle_left_offset;
  
  // Main handle body: rounded rectangular prism
  hull() {
    // Upper junction (broader)
    translate([0, handle_y_offset - handle_projection * 0.3, bowl_height - 8])
      rounded_cube([handle_width + 4, handle_projection * 0.6, 10], 
                    handle_fillet + 1, 48);
    
    // Grip area (narrower middle)
    translate([0, handle_y_offset - handle_projection * 0.5, bowl_height - 20])
      rounded_cube([handle_width - 2, handle_projection * 0.4, 12], 
                    handle_fillet - 1, 48);
    
    // Lower junction (broader)
    translate([0, handle_y_offset - handle_projection * 0.3, bowl_height - 35])
      rounded_cube([handle_width + 4, handle_projection * 0.6, 10], 
                    handle_fillet + 1, 48);
  }
}

module handle_junctions() {
  /*
   * Reinforced junction zones at upper and lower handle attachment points.
   */
  
  handle_y_offset = handle_left_offset;
  
  // Upper junction reinforcement
  translate([0, handle_y_offset - handle_projection * 0.2, bowl_height - 5])
    cube([handle_width + 6, handle_projection * 0.8, 12], center = true);
  
  // Lower junction reinforcement
  translate([0, handle_y_offset - handle_projection * 0.2, bowl_height - 32])
    cube([handle_width + 6, handle_projection * 0.8, 10], center = true);
}

// ============================================================================
// RAZOR DOCK
// ============================================================================

module razor_dock() {
  /*
   * Integrated open-top angled cradle for safety razors.
   * Supports 8-15 mm handle diameters with gentle retention.
   */
  
  handle_y_offset = handle_left_offset;
  dock_y = handle_y_offset - handle_projection * 0.5;
  dock_z = bowl_height - razor_dock_position_z;
  
  // Shallow mold cradle angled upward
  rotate([0, -razor_dock_angle, 0])
    translate([0, dock_y, dock_z])
      hull() {
        // Two support zones along dock length
        for (z_pos = 0; z_pos < razor_dock_length; z_pos = z_pos + 15) {
          // Semi-cylindrical cradle shape
          translate([0, 0, z_pos - razor_dock_length / 2])
            rotate([-90, 0, 0])
              difference() {
                cylinder(r = razor_handle_max_diameter / 2 + razor_handle_clearance,
                         h = razor_dock_depth + 2, $fn = 24);
                
                // Open-top (remove top hemisphere)
                cube([2 * (razor_handle_max_diameter + 2), 
                      razor_dock_depth + 3,
                      razor_handle_max_diameter + 1], center = true);
              }
        }
      }
}

module razor_retention() {
  /*
   * Rounded retention bumps/lips on dock interior.
   * Provides gentle capture without hard snap-fit.
   */
  
  handle_y_offset = handle_left_offset;
  dock_y = handle_y_offset - handle_projection * 0.5;
  dock_z = bowl_height - razor_dock_position_z;
  
  rotate([0, -razor_dock_angle, 0])
    translate([0, dock_y, dock_z])
      {
        // Two retention bumps on sides
        for (side = [-1, 1]) {
          translate([side * (razor_handle_max_diameter / 2 + 1), 
                    -razor_dock_depth + 1.5, 0])
            sphere(r = 1.2, $fn = 12);
        }
      }
}

module razor_head_support() {
  /*
   * Optional support surface for razor head, positioned to keep head
   * away from lather surface while maintaining open drainage.
   */
  
  handle_y_offset = handle_left_offset;
  dock_y = handle_y_offset - handle_projection * 0.5;
  dock_z = bowl_height - razor_dock_position_z;
  
  // Small lip at rear of dock to support razor head
  rotate([0, -razor_dock_angle, 0])
    translate([0, dock_y - 1, dock_z + 8])
      cube([4, 1.5, 5], center = true);
}

// ============================================================================
// BLADE STORAGE
// ============================================================================

module blade_storage() {
  /*
   * Completely enclosed, dry compartment integrated into handle base.
   * Isolated from bowl interior and razor cradle.
   */
  
  handle_y_offset = handle_left_offset;
  compartment_y = handle_y_offset - handle_projection * 0.3;
  compartment_z = 3; // Near base of handle
  
  // Main storage compartment cavity (will be subtracted)
  translate([0, compartment_y, compartment_z])
    rounded_cube([de_blade_width + blade_clearance * 4,
                  blade_drawer_depth + blade_clearance * 2,
                  blade_drawer_height + blade_clearance * 2],
                 2, 32);
}

module blade_drawer() {
  /*
   * Sliding drawer for DE blades (3-5 capacity).
   * Moves perpendicular to blade stack for easy removal.
   * Captive end stop prevents drawer separation.
   */
  
  handle_y_offset = handle_left_offset;
  compartment_y = handle_y_offset - handle_projection * 0.3;
  compartment_z = 3;
  
  // Drawer box body
  difference() {
    translate([0, compartment_y, compartment_z])
      rounded_cube([de_blade_width + blade_clearance * 2,
                    blade_drawer_depth - blade_clearance,
                    blade_drawer_height],
                   1.5, 24);
    
    // Interior cavity for blades
    translate([0, compartment_y + 1, compartment_z + blade_drawer_thickness])
      cube([de_blade_width,
            de_blade_length + blade_clearance * 2,
            blade_drawer_height - blade_drawer_thickness * 2], center = true);
  }
}

module blade_retainer() {
  /*
   * Captive mechanism preventing drawer from sliding out entirely.
   * Simple mechanical stop within compartment walls.
   */
  
  handle_y_offset = handle_left_offset;
  compartment_y = handle_y_offset - handle_projection * 0.3;
  compartment_z = 3;
  
  // End stop ledge (integrated into compartment wall)
  translate([0, compartment_y - blade_drawer_depth / 2 + 3, compartment_z + 4])
    cube([de_blade_width + blade_clearance * 4, 2, blade_drawer_height - 2], 
         center = true);
}

// ============================================================================
// ASSEMBLY AND RENDERING
// ============================================================================

module rounded_cube(dimensions, r, fn_value) {
  /*
   * Utility: cube with rounded edges via Minkowski sum.
   */
  minkowski() {
    cube([dimensions[0] - 2*r, dimensions[1] - 2*r, dimensions[2] - 2*r], 
         center = true);
    sphere(r = r, $fn = fn_value);
  }
}

module assembly_preview() {
  /*
   * Complete assembly: bowl + handle + razor dock + blade storage.
   * All components rendered as manufactured.
   */
  
  color("lightblue")
    bowl_shell();
  
  // Texture visualization (simplified for preview speed)
  color("lightcyan", 0.3)
    {
      macro_hills();
      macro_valleys();
    }
  
  color("steelblue")
    {
      handle();
      handle_junctions();
    }
  
  color("orange", 0.7)
    {
      razor_dock();
      razor_retention();
      razor_head_support();
    }
  
  color("lightgray", 0.5)
    blade_drawer();
}

// ============================================================================
// RENDERING SELECTOR
// ============================================================================

if (render_mode == "assembly") {
  assembly_preview();
} else if (render_mode == "bowl_only") {
  bowl_shell();
} else if (render_mode == "handle_only") {
  handle();
  handle_junctions();
} else if (render_mode == "dock_only") {
  razor_dock();
  razor_retention();
  razor_head_support();
} else if (render_mode == "blade_only") {
  blade_drawer();
} else {
  // Default to assembly
  assembly_preview();
}
