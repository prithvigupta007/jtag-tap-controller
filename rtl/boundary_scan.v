module boundary_scan #(parameter NUM_PINS = 4)(
    input wire tck,
    input wire trst,
    input wire capture_dr,
    input wire shift_dr,
    input wire update_dr,
    input wire extest_active,
    input wire [NUM_PINS-1:0]pin_in,
    output wire [NUM_PINS-1:0]pin_out,
    input wire tdi,
    output wire tdo
);

    reg [NUM_PINS-1:0]boundary_shift;
    reg [NUM_PINS-1:0]boundary_update;

    always @(posedge tck or posedge trst)begin
        if(trst)begin
            boundary_shift <= {NUM_PINS{1'b0}};
            boundary_update <= {NUM_PINS{1'b0}};
        end
        else begin
	    if(capture_dr)begin
                boundary_shift <= pin_in;
            end
            else if(shift_dr)begin
                boundary_shift <= {tdi,boundary_shift[NUM_PINS-1:1]};
            end
            else if(update_dr)begin
                boundary_update <= boundary_shift;
            end
        end
    end

    assign tdo = shift_dr ? boundary_shift[0] : 1'b0;
    assign pin_out = extest_active ? boundary_update : {NUM_PINS{1'b0}};

endmodule