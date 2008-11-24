module drawSprite (Xin, Yin, Sprite, AnimStep, Width, Height, DataIn, Enable, Resetn, Clock, MemSel, Address, Xout, Yout, Color, Done, VGA_Draw);
	input [7:0] Xin;
	input [6:0] Yin;
	input [4:0] Width, Height;
	input Enable, Clock, Resetn;
	input [2:0] AnimStep;			// which tile to draw based on the current animation step
	input [8:0] DataIn;				// color received from memory
	input [2:0]	Sprite;				// analogue to MemSel, chooses which memory to draw from (should be same width)
	output [2:0] MemSel;			// enable for 'external' memory (2:0 allows for 8 memories)
	output [11:0] Address;			// really wide memory address line - for 32*32 sprites with 4 animation steps
	output [7:0] Xout;				// vga output
	output [6:0] Yout;				//		"
	output [8:0] Color;				//		"
	output Done;					// asserted when drawing to vga adapter is finished
	output VGA_Draw;

	reg Done, VGA_Draw_D, EnableX, EnableY, ResetX, ResetY;
	
	//
	// State Machine
	//
	
	reg [2:0] D, Q /*synthesis keep*/;
	parameter	START 	= 3'b000,
				IDLE	= 3'b001,
				DRAW	= 3'b010,
				INC_X	= 3'b011,
				INC_Y	= 3'b100,
				READ	= 3'b101;
				
	// State Register
	always @(posedge Clock)
	begin
		if (~Resetn)
			Q <= 0;
		else
			Q <= D;
	end
	
	// Next-State Logic
	always @*
	begin
		case (Q)
			START:		D <= IDLE;
			
			IDLE:
			begin
					if (Enable)
						D <= DRAW;
					else
						D <= IDLE;
			end
			
			READ:	D <= DRAW;
			
			DRAW:
			begin
					if (DoneX & ~DoneY)
						D <= INC_Y;
					else if (~DoneX)
						D <= INC_X;
					else //DoneX & DoneY
						D <= IDLE;
			end
			
			INC_X:		D <= READ;
	
			INC_Y:		D <= READ;
			
			default:	D <= IDLE;
		endcase
	end
	
	// Output Logic
	always @*
	begin
		case (Q)
			START:
			begin
				Done 	= 0;
				EnableX	= 0;
				EnableY	= 0;
				ResetX 	= 1;
				ResetY	= 1;
				VGA_Draw_D = 0;
			end
			
			IDLE:
			begin
				Done 	= 1;
				EnableX	= 0;
				EnableY	= 0;
				ResetX 	= 1;
				ResetY	= 1;
				VGA_Draw_D = 0;
			end
			
			READ:
			begin
				Done 	= 0;
				EnableX	= 0;
				EnableY	= 0;
				ResetX 	= 0;
				ResetY	= 0;
				VGA_Draw_D = 0;
			end
			
			DRAW:
			begin
				Done 	= 0;
				EnableX	= 0;
				EnableY	= 0;
				ResetX 	= 0;
				ResetY	= 0;
				VGA_Draw_D = 1;
			end
			
			INC_X:
			begin
				Done 	= 0;
				EnableX	= 1;
				EnableY	= 0;
				ResetX 	= 0;
				ResetY	= 0;
				VGA_Draw_D = 0;
			end
			
			INC_Y:
			begin
				Done 	= 0;
				EnableX	= 0;
				EnableY	= 1;
				ResetX 	= 1;
				ResetY	= 0;
				VGA_Draw_D = 0;
			end
		endcase
	end
	
	//
	// Datapath
	//
	
	// sprite width/height counters
	wire [7:0] D_Xoff, Q_Xoff;
	wire [6:0] D_Yoff, Q_Yoff;
	
	addx XoffAdder(1'b1, Q_Xoff, 8'b1, D_Xoff);		// counts to width
	
	nBitRegister XOffsetReg (D_Xoff, Clock, Q_Xoff, ~ResetX, EnableX);
	defparam XOffsetReg.n = 8;
	
	addy YoffAdder(1'b1, Q_Yoff, 7'b1, D_Yoff);		// counts to height
	
	nBitRegister YOffsetReg (D_Yoff, Clock, Q_Yoff, ~ResetY, EnableY);
	defparam YOffsetReg.n = 7;
	
	// X, Y and outputs to VGA Adapter
	
	addx XoutAdder(1'b1, Q_Xoff, Xin, Xout);
	
	addy YoutAdder(1'b1, Q_Yoff, Yin, Yout);
	
	// Address offset Calculation:
	//
	// X + [(Y * height) + (AnimStep * width * height)]
	assign Address = Q_Xoff + ((Q_Yoff * Width) + (AnimStep * Width * Height));
	
	// Completion Comparators
	reg DoneX, DoneY;
	always @*
	begin
		// check if we've got 8x8 pixels from memory
		if (Q_Yoff == (Height-1))		DoneY <= 1'b1;
		else						DoneY <= 1'b0;
		// check if the x offset equals tile width
		if (Q_Xoff == (Width-1))		DoneX <= 1'b1;
		else						DoneX <= 1'b0;
	end
	
	// Color output
	assign Color = DataIn;
	
	// VGA_Draw output 
	// (essentially a comparator + mux)
	reg VGA_Draw;
	always @*
	begin
		if (DataIn == 9'b100101110)		// transparency colour <--
			VGA_Draw <= 0;
		else 
			VGA_Draw <= VGA_Draw_D;
	end
	
	// MemSel output
	assign MemSel = Sprite;

endmodule
