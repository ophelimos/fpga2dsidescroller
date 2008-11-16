// a positive edge triggered N bit register
// 		use defparam <instanceName>.n = 5; 
//		for a 5 bit register
module nBitRegister (D, Clock, Q, Resetn, Enable);
	parameter n = 5;
	
	input [n-1:0] D;
	input Clock, Resetn, Enable;
	output reg [n-1:0] Q;
	
	integer i;
	always @ (posedge Clock)	// synchronous reset
	begin
		if (~Resetn)
			Q <= 0;
		else if (Enable)
			Q <= D;
	end

endmodule
