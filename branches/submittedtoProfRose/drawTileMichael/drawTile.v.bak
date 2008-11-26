module drawTile (Xin, Yin, TileSel, Enable, Clock, Resetn, DataIn, Address, X, Y, Color, VGA_Draw, Done);
	input [7:0] Xin;
	input [6:0] Yin;
	input [3:0] TileSel;	// 4 bits -> 16 tiles maximum
	input Enable;
	input Clock;
	input Resetn;
	input [8:0] DataIn;	// 9 bits per pixel (rgb333)
	output [9:0] Address;	// need to address 16 tiles (1024 pixels = 10 bits)
	output [7:0] X;
	output [6:0] Y;
	output [8:0] Color;
	output VGA_Draw;
	output Done;
	
	reg Done, VGA_Draw, EnableX, EnableY, ResetX, ResetY;
	
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
				VGA_Draw = 0;
			end
			
			IDLE:
			begin
				Done 	= 1;
				EnableX	= 0;
				EnableY	= 0;
				ResetX 	= 1;
				ResetY	= 1;
				VGA_Draw = 0;
			end
			
			READ:
			begin
				Done 	= 0;
				EnableX	= 0;
				EnableY	= 0;
				ResetX 	= 0;
				ResetY	= 0;
				VGA_Draw = 0;
			end
			
			DRAW:
			begin
				Done 	= 0;
				EnableX	= 0;
				EnableY	= 0;
				ResetX 	= 0;
				ResetY	= 0;
				VGA_Draw = 1;
			end
			
			INC_X:
			begin
				Done 	= 0;
				EnableX	= 1;
				EnableY	= 0;
				ResetX 	= 0;
				ResetY	= 0;
				VGA_Draw = 0;
			end
			
			INC_Y:
			begin
				Done 	= 0;
				EnableX	= 0;
				EnableY	= 1;
				ResetX 	= 1;
				ResetY	= 0;
				VGA_Draw = 0;
			end
		endcase
	end
	
	//
	// Datapath
	// - handle tile retrieval and writing to vga adapter
	//
	
	// tile width/height counters
	wire [7:0] D_Xoff, Q_Xoff;
	wire [6:0] D_Yoff, Q_Yoff;
	
	addx XoffAdder(1'b1, Q_Xoff, 8'b1, D_Xoff);		// counts to 8
	
	nBitRegister XOffsetReg (D_Xoff, Clock, Q_Xoff, ~ResetX, EnableX);
	defparam XOffsetReg.n = 8;
	
	addy YoffAdder(1'b1, Q_Yoff, 7'b1, D_Yoff);		// counts to 8
	
	nBitRegister YOffsetReg (D_Yoff, Clock, Q_Yoff, ~ResetY, EnableY);
	defparam YOffsetReg.n = 7;
	
	// X, Y and outputs to VGA Adapter
	
	addx XoutAdder(1'b1, Q_Xoff, Xin, X);
	
	addy YoutAdder(1'b1, Q_Yoff, Yin, Y);

	// memory address tile-offset counter
	
	wire [6:0] D_AdrsOff, Q_AdrsOff;
	wire EnableMemCounter;
	
	addy AddressOffsetCounter (1'b1, Q_AdrsOff, 7'b1, D_AdrsOff);	// increment address by one
	
	or (EnableMemCounter, EnableX, EnableY);
	nBitRegister AddressReg (D_AdrsOff, Clock, Q_AdrsOff, ~ResetY, EnableMemCounter);	// enabled by (enableX | enableY) and reset by ResetY
	defparam AddressReg.n = 7;
	
	// tile selection multiplier
	reg [9:0] TileSel_Offset;
	always @(TileSel)
	begin
		TileSel_Offset <= TileSel * 7'd64;
	end
	
	// memory address tile-offset + tile selection counter
	
	memCount AddressCounter (Q_AdrsOff, TileSel_Offset, Address);	// 10 bit counter (64 pixels/tile * 16 tiles = 1024 addresses)
	
	// Completion Comparators
	reg DoneX, DoneY;
	always @*
	begin
		// check if we've got 8x8 pixels from memory
		if (Q_AdrsOff == 63)	DoneY <= 1'b1;
		else					DoneY <= 1'b0;
		// check if the x offset equals tile width
		if (Q_Xoff == 7)		DoneX <= 1'b1;
		else					DoneX <= 1'b0;
	end
	
	// Color output
	assign Color = DataIn;
	
endmodule
