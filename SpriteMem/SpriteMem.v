module SpriteMem(MemSel, Address, DataOut, Clock, Resetn, Width, Height, AnimSteps);
	input Clock, Resetn;
	input [2:0] MemSel;				// enable for 'external' memory (2:0 allows for 8 memories)
	input [11:0] Address;			// really wide memory address line - for 32*32 sprites with 4 animation steps
	output [8:0] DataOut;			// color received from memory
	output [4:0] Width, Height;
	output [2:0] AnimSteps;
	
	//
	// Multiplexers for Sprite Width, Height and Animation Steps parameters
	//
	// these values can be hard-coded below, and should correspond to the mif file
	// initialized in the memories below. numbered 0 -> 7
	//
	W_H_Mux InfoWidthMux (5'd8, 5'd16, 5'd16, 5'd16, 5'd16, 5'd16, 5'd16, 5'd16, MemSel, Width);
	
	W_H_Mux InfoHeightMux (5'd16, 5'd16, 5'd16, 5'd16, 5'd16, 5'd16, 5'd16, 5'd16, MemSel, Height);
	
	AStep_Mux AnimStepsMux (3'd0, 3'd0, 3'd0, 3'd0, 3'd0, 3'd0, 3'd0, 3'd0, MemSel, AnimSteps);
	
	// Memories can go here:
	wire [8:0] MemOut[7:0];		// 8 sets of 9 wires
/*	genvar i;
	generate
		for (i=0; i <= 7 ;i=i+1)
		begin: sprite_memory
			SpriteRAM MEM0 (Address, Clock, 9'b0, 1'b0, MemOut[i]);	// wren always zero
		end
	endgenerate
*/
	// remember to initialize these!
	spriteROM0 MEM0 (Address, Clock, MemOut[0]);
		
	// multiplex the data (color) output
	DataOut_Mux ColorMux (MemOut[0], MemOut[1], MemOut[2], MemOut[3], MemOut[4], MemOut[5], MemOut[6], MemOut[7], MemSel, DataOut);
	
	
endmodule

