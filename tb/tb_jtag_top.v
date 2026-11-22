
`timescale 1ns/1ps

module tb_jtag_top;

    // DUT inputs
    reg         tck;
    reg         trst;
    reg         tms;
    reg         tdi;
    reg  [3:0]  boundary_pin_in;

    // DUT outputs
    wire        tdo;
    wire [3:0]  boundary_pin_out;
    wire [3:0]  tap_state;
    wire [3:0]  instruction;
    wire        select_idcode;
    wire        select_extest;
    wire        select_sample;
    wire        select_bypass;

    // Test counters and temporary variables
    integer pass_count;
    integer fail_count;
    integer i;

    reg first_tdo;
    reg second_tdo;
    reg [31:0] captured_idcode;
    reg [3:0] captured_sample;
    reg [3:0] instruction_before_shift;

    // TAP state encodings
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

    // Device under test
    jtag_top dut (
        .tck              (tck),
        .trst             (trst),
        .tms              (tms),
        .tdi              (tdi),
        .boundary_pin_in  (boundary_pin_in),
        .tdo              (tdo),
        .boundary_pin_out (boundary_pin_out),
        .tap_state        (tap_state),
        .instruction      (instruction),
        .select_idcode    (select_idcode),
        .select_extest    (select_extest),
        .select_sample    (select_sample),
        .select_bypass    (select_bypass)
    );

    // Initialize signals
    initial begin
        tck = 1'b0;
        trst = 1'b0;
        tms = 1'b1;
        tdi = 1'b0;
        boundary_pin_in = 4'b0000;

        pass_count = 0;
        fail_count = 0;

        $dumpfile("jtag_top.vcd");
        $dumpvars(0, tb_jtag_top);
    end

    // One JTAG clock cycle
    task jtag_clock;
        input tms_value;
        input tdi_value;
        begin
            tck = 1'b0;
            tms = tms_value;
            tdi = tdi_value;
            #5;
            tck = 1'b1;
            #1;
            tck = 1'b0;
            #4;
        end
    endtask

    // Check and report a result
    task check_result;
        input condition;
        input [8*100-1:0] message;
        begin
            if (condition === 1'b1) begin
                $display("PASS: %0s", message);
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: %0s", message);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // Reset TAP using at least five TMS=1 clocks,
    // then enter RUN_TEST_IDLE.
    task reset_tap;
        integer k;
        begin
            for (k = 0; k < 6; k = k + 1)
                jtag_clock(1'b1, 1'b0);

            jtag_clock(1'b0, 1'b0);
        end
    endtask

    // Navigate from RUN_TEST_IDLE to SHIFT_IR.
    task goto_shift_ir;
        begin
            jtag_clock(1'b1, 1'b0); // SELECT_DR_SCAN
            jtag_clock(1'b1, 1'b0); // SELECT_IR_SCAN
            jtag_clock(1'b0, 1'b0); // CAPTURE_IR
            jtag_clock(1'b0, 1'b0); // SHIFT_IR
        end
    endtask

    // Navigate from RUN_TEST_IDLE to SHIFT_DR.
    task goto_shift_dr;
        begin
            jtag_clock(1'b1, 1'b0); // SELECT_DR_SCAN
            jtag_clock(1'b0, 1'b0); // CAPTURE_DR
            jtag_clock(1'b0, 1'b0); // SHIFT_DR
        end
    endtask

    // Load a 4-bit instruction, least-significant bit first.
    // The fourth bit is shifted while TMS=1, taking the TAP
    // from SHIFT_IR to EXIT1_IR.
    task load_instruction;
        input [3:0] instruction_value;
        integer k;
        begin
            $display("");
            $display("---------------------------------------------");
            $display("Loading instruction = %04b", instruction_value);
            $display("---------------------------------------------");

            goto_shift_ir;

            for (k = 0; k < 4; k = k + 1) begin
                if (k == 3)
                    jtag_clock(1'b1, instruction_value[k]);
                else
                    jtag_clock(1'b0, instruction_value[k]);
            end

            jtag_clock(1'b1, 1'b0); // EXIT1_IR -> UPDATE_IR
            jtag_clock(1'b0, 1'b0); // UPDATE_IR -> IDLE; latch IR
        end
    endtask

    // =================================================
    // TEST 5: TAP STATE TRANSITIONS
    // =================================================
    task test_tap_states;
        begin
            $display("");
            $display("=============================================");
            $display("TEST 5: TAP STATE TRANSITIONS");
            $display("=============================================");

            reset_tap;
            check_result(tap_state === RUN_TEST_IDLE,
                         "Starting in RUN_TEST_IDLE.");

            jtag_clock(1,0);
            check_result(tap_state === SELECT_DR_SCAN,
                         "RUN_TEST_IDLE -> SELECT_DR_SCAN.");

            jtag_clock(1,0);
            check_result(tap_state === SELECT_IR_SCAN,
                         "SELECT_DR_SCAN -> SELECT_IR_SCAN.");

            jtag_clock(1,0);
            check_result(tap_state === TEST_LOGIC_RESET,
                         "SELECT_IR_SCAN -> TEST_LOGIC_RESET.");

            jtag_clock(0,0);
            check_result(tap_state === RUN_TEST_IDLE,
                         "TEST_LOGIC_RESET -> RUN_TEST_IDLE.");

            jtag_clock(1,0);
            check_result(tap_state === SELECT_DR_SCAN,
                         "Entered SELECT_DR_SCAN.");

            jtag_clock(0,0);
            check_result(tap_state === CAPTURE_DR,
                         "SELECT_DR_SCAN -> CAPTURE_DR.");

            jtag_clock(0,0);
            check_result(tap_state === SHIFT_DR,
                         "CAPTURE_DR -> SHIFT_DR.");

            jtag_clock(1,0);
            check_result(tap_state === EXIT1_DR,
                         "SHIFT_DR -> EXIT1_DR.");

            jtag_clock(0,0);
            check_result(tap_state === PAUSE_DR,
                         "EXIT1_DR -> PAUSE_DR.");

            jtag_clock(1,0);
            check_result(tap_state === EXIT2_DR,
                         "PAUSE_DR -> EXIT2_DR.");

            jtag_clock(0,0);
            check_result(tap_state === SHIFT_DR,
                         "EXIT2_DR -> SHIFT_DR.");

            jtag_clock(1,0);
            check_result(tap_state === EXIT1_DR,
                         "SHIFT_DR -> EXIT1_DR again.");

            jtag_clock(1,0);
            check_result(tap_state === UPDATE_DR,
                         "EXIT1_DR -> UPDATE_DR.");

            jtag_clock(0,0);
            check_result(tap_state === RUN_TEST_IDLE,
                         "UPDATE_DR -> RUN_TEST_IDLE.");

            jtag_clock(1,0);
            jtag_clock(1,0);
            check_result(tap_state === SELECT_IR_SCAN,
                         "Entered SELECT_IR_SCAN.");

            jtag_clock(0,0);
            check_result(tap_state === CAPTURE_IR,
                         "SELECT_IR_SCAN -> CAPTURE_IR.");

            jtag_clock(0,0);
            check_result(tap_state === SHIFT_IR,
                         "CAPTURE_IR -> SHIFT_IR.");

            jtag_clock(1,0);
            check_result(tap_state === EXIT1_IR,
                         "SHIFT_IR -> EXIT1_IR.");

            jtag_clock(0,0);
            check_result(tap_state === PAUSE_IR,
                         "EXIT1_IR -> PAUSE_IR.");

            jtag_clock(1,0);
            check_result(tap_state === EXIT2_IR,
                         "PAUSE_IR -> EXIT2_IR.");

            jtag_clock(0,0);
            check_result(tap_state === SHIFT_IR,
                         "EXIT2_IR -> SHIFT_IR.");

            jtag_clock(1,0);
            check_result(tap_state === EXIT1_IR,
                         "SHIFT_IR -> EXIT1_IR again.");

            jtag_clock(1,0);
            check_result(tap_state === UPDATE_IR,
                         "EXIT1_IR -> UPDATE_IR.");

            jtag_clock(0,0);
            check_result(tap_state === RUN_TEST_IDLE,
                         "UPDATE_IR -> RUN_TEST_IDLE.");
        end
    endtask

    // =================================================
    // TEST 6: ASYNCHRONOUS RESET RECOVERY
    // =================================================
    task test_reset_recovery;
        begin
            $display("");
            $display("=============================================");
            $display("TEST 6: ASYNCHRONOUS RESET RECOVERY");
            $display("=============================================");

            reset_tap;
            check_result(tap_state === RUN_TEST_IDLE,
                         "Reset-recovery test starts in RUN_TEST_IDLE.");

            goto_shift_dr;
            check_result(tap_state === SHIFT_DR,
                         "TAP entered SHIFT_DR before reset.");

            // Assert reset without waiting for a TCK edge.
            trst = 1'b1;
            #2;
            check_result(tap_state === TEST_LOGIC_RESET,
                         "Asynchronous reset forces TEST_LOGIC_RESET.");

            trst = 1'b0;
            #2;
            reset_tap;
            check_result(tap_state === RUN_TEST_IDLE,
                         "TAP recovers to RUN_TEST_IDLE after reset.");
        end
    endtask

    // =================================================
    // TEST 7: UNSUPPORTED INSTRUCTION FALLBACK
    // =================================================
    task test_invalid_instruction;
        begin
            $display("");
            $display("=============================================");
            $display("TEST 7: UNSUPPORTED INSTRUCTION FALLBACK");
            $display("=============================================");

            load_instruction(4'b0100);

            check_result(instruction === 4'b0100,
                         "Unsupported instruction loaded into IR.");

            check_result(select_idcode === 1'b0,
                         "Unsupported instruction does not select IDCODE.");

            check_result(select_extest === 1'b0,
                         "Unsupported instruction does not select EXTEST.");

            check_result(select_sample === 1'b0,
                         "Unsupported instruction does not select SAMPLE.");

            check_result(select_bypass === 1'b1,
                         "Unsupported instruction selects BYPASS.");

            goto_shift_dr;

            first_tdo = tdo;
            check_result(first_tdo === 1'b0,
                         "BYPASS TDO starts at zero.");

            jtag_clock(1'b0, 1'b1);
            second_tdo = tdo;

            check_result(second_tdo === 1'b1,
                         "BYPASS shifts in a one.");

            jtag_clock(1'b1, 1'b0);
            jtag_clock(1'b1, 1'b0);
            jtag_clock(1'b0, 1'b0);
        end
    endtask

    // =================================================
    // TEST 8: INSTRUCTION REGISTER VERIFICATION
    // =================================================
    task test_instruction_register;
        begin
            $display("");
            $display("=============================================");
            $display("TEST 8: INSTRUCTION REGISTER VERIFICATION");
            $display("=============================================");

            // Test the asynchronous reset value explicitly.
            trst = 1'b1;
            tms = 1'b1;
            tdi = 1'b0;
            #2;

            check_result(instruction === 4'b0001,
                         "Reset selects the default IDCODE instruction.");

            trst = 1'b0;
            #2;
            reset_tap;

            goto_shift_ir;
            check_result(tap_state === SHIFT_IR,
                         "TAP entered SHIFT_IR.");

            instruction_before_shift = instruction;

            // Shift EXTEST = 0010, LSB first: 0, 1, 0, 0.
            // The final bit uses TMS=1 and exits SHIFT_IR.
            jtag_clock(1'b0, 1'b0);
            jtag_clock(1'b0, 1'b1);
            jtag_clock(1'b0, 1'b0);
            jtag_clock(1'b1, 1'b0);

            check_result(instruction === instruction_before_shift,
                         "Active instruction is unchanged during SHIFT_IR.");

            // The previous clock entered EXIT1_IR.
            // This clock enters UPDATE_IR.
            jtag_clock(1'b1, 1'b0);

            check_result(tap_state === UPDATE_IR,
                         "TAP entered UPDATE_IR.");

            // This edge latches ir_shift into instruction
            // and moves the TAP into RUN_TEST_IDLE.
            jtag_clock(1'b0, 1'b0);

            check_result(instruction === 4'b0010,
                         "EXTEST becomes active after UPDATE_IR.");

            check_result(select_extest === 1'b1,
                         "EXTEST decoder activates after instruction update.");

            trst = 1'b1;
            #2;
            check_result(instruction === 4'b0001,
                         "Asynchronous reset restores IDCODE instruction.");

            trst = 1'b0;
            #2;
            reset_tap;
        end
    endtask

    // =================================================
    // TEST 1: EXTEST / BOUNDARY SCAN
    // =================================================
    task test_extest;
        begin
            $display("");
            $display("=============================================");
            $display("TEST 1: EXTEST / BOUNDARY SCAN");
            $display("=============================================");

            load_instruction(4'b0010);

            check_result(select_extest === 1'b1,
                         "EXTEST instruction decoded.");

            goto_shift_dr;

            // Shift the pattern into the boundary register.
            jtag_clock(1'b0, 1'b0);
            jtag_clock(1'b0, 1'b1);
            jtag_clock(1'b0, 1'b0);
            jtag_clock(1'b1, 1'b1);

            jtag_clock(1'b1, 1'b0); // UPDATE_DR
            jtag_clock(1'b0, 1'b0); // RUN_TEST_IDLE

            #1;
            $display("Boundary output = %04b", boundary_pin_out);

            check_result(boundary_pin_out === 4'b1010,
                         "EXTEST drives boundary output 1010.");
        end
    endtask

    // =================================================
    // TEST 2: BYPASS
    // =================================================
    task test_bypass;
        begin
            $display("");
            $display("=============================================");
            $display("TEST 2: BYPASS");
            $display("=============================================");

            load_instruction(4'b1111);

            check_result(select_bypass === 1'b1,
                         "BYPASS instruction decoded.");

            goto_shift_dr;

            first_tdo = tdo;
            jtag_clock(1'b0, 1'b1);

            second_tdo = tdo;
            jtag_clock(1'b1, 1'b0);

            $display("BYPASS: TDI sequence = 1 -> 0");
            $display("BYPASS: TDO sequence = %b -> %b",
                     first_tdo, second_tdo);

            check_result(first_tdo === 1'b0,
                         "First BYPASS TDO bit is 0.");

            check_result(second_tdo === 1'b1,
                         "Second BYPASS TDO bit is 1.");

            jtag_clock(1'b1, 1'b0);
            jtag_clock(1'b0, 1'b0);
        end
    endtask

    // =================================================
    // TEST 3: IDCODE
    // =================================================
    task test_idcode;
        begin
            $display("");
            $display("=============================================");
            $display("TEST 3: IDCODE");
            $display("=============================================");

            load_instruction(4'b0001);

            check_result(select_idcode === 1'b1,
                         "IDCODE instruction decoded.");

            goto_shift_dr;
            captured_idcode = 32'b0;

            // Read IDCODE LSB first.
            for (i = 0; i < 32; i = i + 1) begin
                captured_idcode[i] = tdo;

                if (i == 31)
                    jtag_clock(1'b1, 1'b0);
                else
                    jtag_clock(1'b0, 1'b0);
            end

            $display("IDCODE read from TDO = %08h",
                     captured_idcode);

            check_result(captured_idcode === 32'h12345679,
                         "IDCODE matches 12345679.");

            jtag_clock(1'b1, 1'b0);
            jtag_clock(1'b0, 1'b0);
        end
    endtask

    // =================================================
    // TEST 4: SAMPLE
    // =================================================
    task test_sample;
        begin
            $display("");
            $display("=============================================");
            $display("TEST 4: SAMPLE");
            $display("=============================================");

            boundary_pin_in = 4'b1101;
            $display("External pins = %04b", boundary_pin_in);

            load_instruction(4'b0011);

            check_result(select_sample === 1'b1,
                         "SAMPLE instruction decoded.");

            goto_shift_dr;
            captured_sample = 4'b0000;

            // Read captured boundary data, LSB first.
            for (i = 0; i < 4; i = i + 1) begin
                captured_sample[i] = tdo;

                if (i == 3)
                    jtag_clock(1'b1, 1'b0);
                else
                    jtag_clock(1'b0, 1'b0);
            end

            $display("Captured value from TDO = %04b",
                     captured_sample);

            check_result(captured_sample === 4'b1101,
                         "SAMPLE captures external pins 1101.");

            check_result(boundary_pin_out === 4'b0000,
                         "SAMPLE does not drive boundary pins.");

            jtag_clock(1'b1, 1'b0);
            jtag_clock(1'b0, 1'b0);
        end
    endtask

    // =================================================
    // MAIN TEST SEQUENCE
    // =================================================
    initial begin
        $display("");
        $display("=============================================");
        $display("       JTAG TAP CONTROLLER TESTBENCH");
        $display("=============================================");

        // Apply active-high asynchronous reset.
        trst = 1'b0;
        #2;
        trst = 1'b1;
        #2;
        trst = 1'b0;
        #2;

        reset_tap;

        check_result(tap_state === RUN_TEST_IDLE,
                     "TAP entered RUN_TEST_IDLE after reset.");

        // State machine and reset tests
        test_tap_states;
        test_reset_recovery;
        test_invalid_instruction;
        test_instruction_register;

        // Functional instruction/data-register tests
        test_extest;
        test_bypass;
        test_idcode;
        test_sample;

        // Final summary
        $display("");
        $display("=============================================");
        $display("               TEST SUMMARY");
        $display("=============================================");
        $display("Total checks passed : %0d", pass_count);
        $display("Total checks failed : %0d", fail_count);

        if (fail_count == 0)
            $display("OVERALL RESULT: PASS");
        else
            $display("OVERALL RESULT: FAIL");

        $display("=============================================");

        $finish;
    end

endmodule

