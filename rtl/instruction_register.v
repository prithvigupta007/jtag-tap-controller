module instruction_register #(parameter IR_WIDTH=4)(
    input wire tck,
    input wire trst,
    input wire capture_ir,
    input wire shift_ir,
    input wire update_ir,
    input wire tdi,
    output wire tdo,
    output reg [IR_WIDTH-1:0]instruction
);
    reg [IR_WIDTH-1:0]ir_shift; //temporary register to store new instruction

    always @(posedge tck or posedge trst)begin
	if(trst)begin //default instruction after reset
	    ir_shift <= 4'b0001;
            instruction <= 4'b0001;
	end
	else begin
	    if(capture_ir)begin
		ir_shift <= 4'b0001;
	    end
	    else if(shift_ir)begin
		ir_shift <= {tdi,ir_shift[IR_WIDTH-1:1]}; //TDI->1->0->0->0
	    end
	    else if(update_ir)begin
		instruction <= ir_shift;
	    end
	end
    end

    assign tdo = shift_ir ? ir_shift[0] : 1'b0;

endmodule