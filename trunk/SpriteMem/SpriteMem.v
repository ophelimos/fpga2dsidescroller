module SpriteMem(MemSel, Address, DataOut, Clock, Resetn, Width, Height, AnimSteps);
	input Clock, Resetn;
	input [2:0] MemSel;				// enable for 'external' memory (2:0 allows for 8 memories)
	input [15:0] Address;			// really wide memory address line - for 64*64 sprites with 16 animation steps
	output [8:0] DataOut;			// color received from memory
	output [5:0] Width, Height;
	output [2:0] AnimSteps;
	
	wire [7:0] En;	// memory enables
	
	// Binary decoder
	assign En[0] = ~MemSel[0] & ~MemSel[1] & ~MemSel[2];
	assign En[1] = ~MemSel[0] & ~MemSel[1] & MemSel[2];
	assign En[2] = ~MemSel[0] & MemSel[1] & ~MemSel[2];
	assign En[3] = ~MemSel[0] & MemSel[1] & MemSel[2];
	assign En[4] = MemSel[0] & ~MemSel[1] & ~MemSel[2];
	assign En[5] = MemSel[0] & ~MemSel[1] & MemSel[2];
	assign En[6] = MemSel[0] & MemSel[1] & ~MemSel[2];
	assign En[7] = MemSel[0] & MemSel[1] & MemSel[2];
	
	// 8 memory information blocks
	// which are to contain width, height, and animation step
	// info for each sprite in memory
	TristateRegBlock SpriteInfo0 (1,2,3, Width, Height, AnimSteps, En[0]);
	TristateRegBlock SpriteInfo1 (1,2,3, Width, Height, AnimSteps, En[1]);
	TristateRegBlock SpriteInfo2 (1,2,3, Width, Height, AnimSteps, En[2]);
	TristateRegBlock SpriteInfo3 (1,2,3, Width, Height, AnimSteps, En[3]);
	TristateRegBlock SpriteInfo4 (1,2,3, Width, Height, AnimSteps, En[4]);
	TristateRegBlock SpriteInfo5 (1,2,3, Width, Height, AnimSteps, En[5]);
	TristateRegBlock SpriteInfo6 (1,2,3, Width, Height, AnimSteps, En[6]);
	TristateRegBlock SpriteInfo7 (1,2,3, Width, Height, AnimSteps, En[7]);
	
	// Memories can go here:


endmodule

module TristateRegBlock (inWidth, inHeight, inAnimSteps, outWidth, outHeight, outAnimSteps, oe);
	input oe;	// output enable
	input [5:0] inWidth, inHeight;
	input [2:0] inAnimSteps;
	output [5:0] outWidth, outHeight;
	output [2:0] outAnimSteps;

	NBitTristate TriWidth (inWidth, oe, outWidth);
	defparam TriWidth.n = 6;
	NBitTristate TriHeight (inHeight, oe, outHeight);
	defparam TriHeight.n = 6;
	NBitTristate TriAnimSteps (inAnimSteps, oe, outAnimSteps);
	defparam TriAnimSteps.n = 3;

endmodule
