// 3D-printable case for the Extron S-Video Adapter.
//
// Two shells split at the top surface of the PCB. The board drops into the
// bottom shell and rests on ledges along its two short (connector-free)
// edges; walls in the top shell clamp those same strips from above. Four M3
// screws pass through the top shell into heat-set inserts in the bottom
// shell. The bottom shell has ears for screwing the case to a surface.
//
// Render a part with: openscad -D 'part="bottom"' -o bottom.stl case.scad
//   part = "bottom"   bottom shell, print orientation
//          "top"      top shell, print orientation (roof on the bed)
//          "assembly" both shells with the board and connector envelopes
//          "exploded" as assembly, shells pulled apart
//          "shells"   both shells assembled, without the board
//          "check"    intersection of the case with the board and
//                     connectors; must render empty
//
// Coordinates: X/Y match the PCB with the origin at its lower-left corner as
// seen from the top (KiCad x - 104.14, 114.3 - KiCad y). Z = 0 is the
// underside of the case. All dimensions in mm.

part = "assembly";

/* [Fit] */
clr        = 0.3;   // gap between board edge and walls
notch_clr  = 0.4;   // extra clearance around connector openings

/* [Shell] */
wall       = 2.0;
floor_t    = 2.0;
roof_t     = 2.0;
under      = 4.0;   // space below the PCB for leads (longest is ~2.9 mm)
above      = 21.5;  // space above the PCB (J4 tab reaches 20.2 mm)
end_zone   = 8.0;   // space past each short board edge for the screw bosses
corner_r   = 2.0;

/* [Board clamp] */
// Bare strips along the short edges that the ledges and clamp walls touch.
strip_lo   = 1.2;   // Y 0 .. 1.2 (J3/J4 start at Y 1.41)
strip_hi   = 1.3;   // Y 62.2 .. 63.5 (J1 courtyard ends at Y 61.58)

/* [Fasteners] */
boss_d     = 8.0;
insert_d   = 4.0;   // M3 heat-set insert hole (use ~2.6 to self-tap)
insert_h   = 6.0;
screw_d    = 3.4;   // M3 clearance
head_d     = 6.5;   // M3 socket head counterbore
head_h     = 3.5;
ear_len    = 10.0;
ear_t      = 3.0;
ear_hole_d = 4.5;   // #8 / M4 mounting screws

$fn = 48;

// ---------------------------------------------------------------- board ----
pcb_w = 43.18;
pcb_l = 63.5;
pcb_t = 1.6;

z_pcb_bot = floor_t + under;
z_pcb_top = z_pcb_bot + pcb_t;
z_split   = z_pcb_top;
z_roof    = z_pcb_top + above;
z_top     = z_roof + roof_t;

// Case outline
x0 = -clr - wall;
x1 = pcb_w + clr + wall;
y0 = -clr - end_zone - wall;
y1 = pcb_l + clr + end_zone + wall;

boss_x = [x0 + wall + boss_d / 2 + 1, x1 - wall - boss_d / 2 - 1];
// bosses sink 1 mm into the end walls and stay clear of the board ledges
boss_y = [y0 + wall + boss_d / 2 - 1, y1 - wall - boss_d / 2 + 1];

// ----------------------------------------------------------- connectors ---
// Envelopes from the manufacturer drawings, heights above the PCB top.

// J1: Amphenol L77HDE15SD1CH4F, HD-15 with #4-40 screwlocks, flange at the
// left board edge. D shell and hex standoffs protrude 6.05 mm.
j1_y = 45.555;      // centre
j1_zc = 6.5;        // shell/standoff centre height
j1_notch = [29.6, 61.5, 11.0];   // y_min, y_max, height of wall opening

// J2: TE 5749181-1 Mini-DIN, face flush with the right board edge.
j2_y = [38.05, 52.15];
j2_h = 13.0;

// J3: TE 284512-5 header, face flush with the left board edge. The opening
// is oversized to pass the mating plug's body.
j3_y = [2.54, 22.34];
j3_h = 7.3;
j3_notch = [1.6, 23.3, 14.0];  // mating plug (TE 284506-5) drawing not checked

// J4: CUI RCJ-2123 dual RCA, face at the right board edge.
j4_y = [2.49, 29.99];
j4_h = 14.05;
j4_jack_y = [9.24, 23.24];
j4_jack_z = 7.7;
j4_collar_d = 10.2;
j4_barrel_d = 8.3;
j4_slot_w = 11.0;

module rounded_box(xa, xb, ya, yb, za, zb, r = corner_r) {
    hull() for (x = [xa + r, xb - r], y = [ya + r, yb - r])
        translate([x, y, za]) cylinder(r = r, h = zb - za);
}

module box(xa, xb, ya, yb, za, zb) {
    translate([xa, ya, za]) cube([xb - xa, yb - ya, zb - za]);
}

module board() {
    color("darkgreen") board_only();
}

module board_only(e = 0) {
    box(e, pcb_w - e, e, pcb_l - e, z_pcb_bot + e, z_pcb_top - e);
}

module connectors() {
    z = z_pcb_top;
    color("dimgray") {
        // J1 body behind the flange, flange, D shell, standoffs
        box(-0.05, 16.1, 30.1, 61.01, z, z + 12.55);
        hull() {
            translate([-6.05, j1_y - 16.33 / 2, z + j1_zc + 3.95 - 0.01])
                cube([6.05, 16.33, 0.01]);
            translate([-6.05, j1_y - 14.0 / 2, z + j1_zc - 3.95])
                cube([6.05, 14.0, 0.01]);
        }
        for (dy = [-12.495, 12.495])
            translate([-6.05, j1_y + dy, z + j1_zc]) rotate([0, 90, 0])
                cylinder(d = 5.5, h = 6.05, $fn = 6);
        // J2
        box(30.3, pcb_w, j2_y[0], j2_y[1], z, z + j2_h);
        // J3
        box(0, 10.3, j3_y[0], j3_y[1], z, z + j3_h);
        // J4 housing, top tab, collars, barrels
        box(32.88, pcb_w, j4_y[0], j4_y[1], z, z + j4_h);
        box(36.0, pcb_w, 16.24 - 3.5, 16.24 + 3.5, z, z + 20.2);
        for (y = j4_jack_y) translate([pcb_w, y, z + j4_jack_z])
            rotate([0, 90, 0]) {
                cylinder(d = j4_collar_d, h = 1.5);
                cylinder(d = j4_barrel_d, h = 7.8);
            }
    }
}

// --------------------------------------------------------------- shells ----
module bottom_shell() {
    difference() {
        union() {
            difference() {
                rounded_box(x0, x1, y0, y1, 0, z_split);
                box(x0 + wall, x1 - wall, y0 + wall, y1 - wall, floor_t, z_split + 1);
            }
            // board ledges along the short edges
            box(x0, x1, -clr, strip_lo, 0, z_pcb_bot);
            box(x0, x1, pcb_l - strip_hi, pcb_l + clr, 0, z_pcb_bot);
            // support post under the middle of the board (clear of leads)
            translate([22, 30, 0]) cylinder(d = 5, h = z_pcb_bot);
            // screw bosses
            for (x = boss_x, y = boss_y)
                translate([x, y, 0]) cylinder(d = boss_d, h = z_split);
            // mounting ears
            for (e = [[y0 - ear_len, y0 + wall], [y1 - wall, y1 + ear_len]])
                rounded_box(x0, x1, e[0], e[1], 0, ear_t);
        }
        // board pocket between the ledges (keeps the walls clear of the PCB)
        box(-clr, pcb_w + clr, -clr, pcb_l + clr, z_pcb_bot, z_split + 1);
        // insert holes
        for (x = boss_x, y = boss_y)
            translate([x, y, z_split - insert_h]) cylinder(d = insert_d, h = insert_h + 1);
        // ear holes
        for (y = [y0 - ear_len / 2, y1 + ear_len / 2], x = [x0 + 9, x1 - 9])
            translate([x, y, -1]) cylinder(d = ear_hole_d, h = ear_t + 2);
    }
}

module top_shell() {
    zb = z_split;
    difference() {
        union() {
            difference() {
                rounded_box(x0, x1, y0, y1, zb, z_top);
                box(x0 + wall, x1 - wall, y0 + wall, y1 - wall, zb - 1, z_roof);
            }
            // clamp walls pressing on the board's short-edge strips
            box(x0, x1, -clr, strip_lo, zb, z_top);
            box(x0, x1, pcb_l - strip_hi, pcb_l + clr, zb, z_top);
            // screw bosses
            for (x = boss_x, y = boss_y)
                translate([x, y, zb]) cylinder(d = boss_d, h = z_top - zb);
        }
        // screw clearance and head counterbores
        for (x = boss_x, y = boss_y) translate([x, y, 0]) {
            translate([0, 0, zb - 1]) cylinder(d = screw_d, h = z_top);
            translate([0, 0, z_top - head_h]) cylinder(d = head_d, h = head_h + 1);
        }
        connector_openings();
    }
}

// Openings in the top shell's long walls, open at the bottom so the shell
// can be lowered over connectors that protrude through the walls.
module connector_openings() {
    z = z_split - 1;
    zt = z_pcb_top;
    // left wall: J1, J3
    box(x0 - 1, 0.5, j1_notch[0], j1_notch[1], z, zt + j1_notch[2]);
    box(x0 - 1, 0.5, j3_notch[0], j3_notch[1], z, zt + j3_notch[2]);
    // right wall: J2 face
    box(pcb_w - 0.5, x1 + 1, j2_y[0] - notch_clr, j2_y[1] + notch_clr, z, zt + j2_h + notch_clr);
    // right wall: J4 jacks, U-shaped slots
    for (y = j4_jack_y) {
        box(pcb_w - 0.5, x1 + 1, y - j4_slot_w / 2, y + j4_slot_w / 2, z, zt + j4_jack_z);
        translate([pcb_w - 0.5, y, zt + j4_jack_z]) rotate([0, 90, 0])
            cylinder(d = j4_slot_w, h = x1 - pcb_w + 2);
    }
}

// ----------------------------------------------------------------- parts ---
if (part == "bottom") {
    bottom_shell();
} else if (part == "top") {
    // flip so the roof sits on the bed
    translate([0, 0, z_top]) mirror([0, 0, 1]) top_shell();
} else if (part == "assembly" || part == "exploded") {
    lift = part == "exploded" ? 30 : 0;
    color("lightsteelblue") bottom_shell();
    translate([0, 0, lift / 2]) { board(); connectors(); }
    translate([0, 0, lift]) color("lightsteelblue", 0.6) top_shell();
} else if (part == "shells") {
    color("lightsteelblue") { bottom_shell(); top_shell(); }
} else if (part == "check") {
    // Shrink the board slightly so its intended contact with the ledges
    // and clamp walls doesn't count as a collision.
    intersection() {
        union() { bottom_shell(); top_shell(); }
        union() {
            board_only(0.01);
            connectors();
        }
    }
}
