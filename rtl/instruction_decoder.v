
module instruction_decoder (
    input  wire [3:0] instruction,
    output wire       select_idcode,
    output wire       select_extest,
    output wire       select_sample,
    output wire       select_bypass
);

    localparam IDCODE = 4'b0001;
    localparam EXTEST = 4'b0010;
    localparam SAMPLE = 4'b0011;
    localparam BYPASS = 4'b1111;

    assign select_idcode = (instruction == IDCODE);
    assign select_extest = (instruction == EXTEST);
    assign select_sample = (instruction == SAMPLE);

    // Select BYPASS for the explicit BYPASS opcode and
    // for instructions not implemented by this decoder.
    assign select_bypass =
        (instruction == BYPASS) ||
        !((instruction == IDCODE) ||
          (instruction == EXTEST) ||
          (instruction == SAMPLE));

endmodule
