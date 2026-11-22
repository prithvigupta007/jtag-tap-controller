
module jtag_top (
    input  wire       tck,
    input  wire       trst,
    input  wire       tms,
    input  wire       tdi,

    input  wire [3:0] boundary_pin_in,
    output wire [3:0] boundary_pin_out,

    output wire        tdo,
    output wire [3:0] tap_state,
    output wire [3:0] instruction,

    output wire select_idcode,
    output wire select_extest,
    output wire select_sample,
    output wire select_bypass
);

    // =========================================================
    // TAP state encodings
    // =========================================================

    localparam TEST_LOGIC_RESET = 4'd0;
    localparam RUN_TEST_IDLE    = 4'd1;
    localparam SELECT_DR_SCAN   = 4'd2;
    localparam CAPTURE_DR       = 4'd3;
    localparam SHIFT_DR         = 4'd4;
    localparam EXIT1_DR         = 4'd5;
    localparam PAUSE_DR         = 4'd6;
    localparam EXIT2_DR         = 4'd7;
    localparam UPDATE_DR        = 4'd8;
    localparam SELECT_IR_SCAN   = 4'd9;
    localparam CAPTURE_IR       = 4'd10;
    localparam SHIFT_IR         = 4'd11;
    localparam EXIT1_IR         = 4'd12;
    localparam PAUSE_IR         = 4'd13;
    localparam EXIT2_IR         = 4'd14;
    localparam UPDATE_IR        = 4'd15;

    // =========================================================
    // TAP controller
    // =========================================================

    tap_controller u1 (
        .tck   (tck),
        .trst  (trst),
        .tms   (tms),
        .state (tap_state)
    );

    // =========================================================
    // State decoding
    // =========================================================

    wire capture_ir = (tap_state == CAPTURE_IR);
    wire shift_ir   = (tap_state == SHIFT_IR);
    wire update_ir  = (tap_state == UPDATE_IR);

    wire capture_dr = (tap_state == CAPTURE_DR);
    wire shift_dr   = (tap_state == SHIFT_DR);
    wire update_dr  = (tap_state == UPDATE_DR);

    // =========================================================
    // Scan path outputs
    // =========================================================

    wire ir_tdo;
    wire bypass_tdo;
    wire idcode_tdo;
    wire boundary_tdo;

    // Instruction register
    instruction_register u2 (
        .tck         (tck),
        .trst        (trst),
        .capture_ir  (capture_ir),
        .shift_ir    (shift_ir),
        .update_ir   (update_ir),
        .tdi         (tdi),
        .tdo         (ir_tdo),
        .instruction (instruction)
    );

    // Instruction decoder
    instruction_decoder u3 (
        .instruction   (instruction),
        .select_idcode (select_idcode),
        .select_extest (select_extest),
        .select_sample (select_sample),
        .select_bypass (select_bypass)
    );

    // BYPASS data register
    bypass_register u4 (
        .tck        (tck),
        .trst       (trst),
        .capture_dr (capture_dr),
        .shift_dr   (shift_dr),
        .update_dr  (update_dr),
        .tdi        (tdi),
        .tdo        (bypass_tdo)
    );

    // IDCODE data register
    idcode_register u5 (
        .tck        (tck),
        .trst       (trst),
        .capture_dr (capture_dr),
        .shift_dr   (shift_dr),
        .tdi        (tdi),
        .tdo        (idcode_tdo)
    );

    // Boundary-scan data register
    boundary_scan #(
        .NUM_PINS (4)
    ) u6 (
        .tck           (tck),
        .trst          (trst),
        .capture_dr    (capture_dr),
        .shift_dr      (shift_dr),
        .update_dr     (update_dr),
        .extest_active (select_extest),
        .pin_in        (boundary_pin_in),
        .pin_out       (boundary_pin_out),
        .tdi           (tdi),
        .tdo           (boundary_tdo)
    );

    // =========================================================
    // TDO multiplexer
    // Select one active scan path
    // =========================================================

    wire tdo_next;

    assign tdo_next =
        shift_ir ? ir_tdo :
        (shift_dr && select_idcode) ? idcode_tdo :
        (shift_dr && select_bypass) ? bypass_tdo :
        (shift_dr && (select_extest || select_sample))
            ? boundary_tdo :
        1'b0;

    // =========================================================
    // TDO output register
    // Update TDO on falling edge of TCK
    // =========================================================

    assign tdo = tdo_next;
endmodule