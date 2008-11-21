module characterMovement(clock, resetn, enable, x_position, y_position);
	//------------------------------------------
	// Inputs
	//------------------------------------------
	input clock;
	input enable;
	input resetn;
	//------------------------------------------
	// Outputs
	//------------------------------------------
	output [7:0] x_position; // Adjust location on-screen, in pixels
	output [6:0] y_position;
	
	// Character x position (probably fixed permanently)	
	assign x_position = 8'd72;	// Right around the center (in pixels)
	
	// Character y position (fixed for now)
	assign y_position = 7'd60;	// just below center on the screen (in pixels)
	
endmodule
