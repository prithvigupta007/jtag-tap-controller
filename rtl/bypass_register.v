module bypass_register(
    input wire tck,
    input wire trst,
    input wire capture_dr,
    input wire shift_dr,
    input wire update_dr,
    input wire tdi,
    output wire tdo
);
    reg bypass_shift; //bypass shift register
    reg bypass_latched; //bypass update register

    always @(posedge tck or posedge trst)begin
	if(trst)begin
    	    bypass_shift <= 1'b0;
  	    bypass_latched <= 1'b0;
    	end
   	else begin
	    if(capture_dr)begin
		bypass_shift <= 1'b0;
	    end
	    else if(shift_dr)begin
		bypass_shift <= tdi;
	    end
	    else if(update_dr)begin
		bypass_latched <= bypass_shift;
	    end
 	end
    end

    assign tdo = shift_dr ? bypass_shift : 1'b0;

endmodule