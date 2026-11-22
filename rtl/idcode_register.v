module idcode_register #(parameter IDCODE_VALUE = 32'h1234_5679)(
    input wire tck,
    input wire trst,
    input wire capture_dr,
    input wire shift_dr,
    input wire tdi,
    output wire tdo
);

    reg [31:0] idcode_shift; //32 bit idcode shift register

    always @(posedge tck or posedge trst)begin
	if(trst)begin
            idcode_shift <= IDCODE_VALUE;
        end
        else begin
            if(capture_dr)begin
                idcode_shift <= IDCODE_VALUE;
            end
            else if(shift_dr)begin
                idcode_shift <= {tdi,idcode_shift[31:1]};
            end
        end
    end

    assign tdo = shift_dr ? idcode_shift[0] : 1'b0;

endmodule