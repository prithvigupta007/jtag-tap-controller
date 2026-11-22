`timescale 1ns/1ps

module tb_tap_controller;

    reg tck;
    reg trst;
    reg tms;

    wire [3:0] state;

    // DUT
    tap_controller dut (
        .tck   (tck),
        .trst  (trst),
        .tms   (tms),
        .state (state)
    );

    // TCK generation
    initial begin
        tck = 0;
        forever #5 tck = ~tck;
    end

    // Test sequence
    initial begin

        trst = 1;
        tms  = 0;

        #12;

        trst = 0;

        // TEST_LOGIC_RESET -> RUN_TEST_IDLE
        tms = 0;
        #10;

        // RUN_TEST_IDLE -> SELECT_DR_SCAN
        tms = 1;
        #10;

        // SELECT_DR_SCAN -> CAPTURE_DR
        tms = 0;
        #10;

        // CAPTURE_DR -> SHIFT_DR
        tms = 0;
        #10;

        // SHIFT_DR -> SHIFT_DR
        tms = 0;
        #10;

        // SHIFT_DR -> EXIT1_DR
        tms = 1;
        #10;

        // EXIT1_DR -> UPDATE_DR
        tms = 1;
        #10;

        // UPDATE_DR -> RUN_TEST_IDLE
        tms = 0;
        #10;

        $finish;

    end

endmodule