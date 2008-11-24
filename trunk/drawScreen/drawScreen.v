module drawScreen (Enable, Clock, Resetn, DataIn, Address, X, Y, Color, VGA_Draw, Done);
	input Enable;
	input Clock;
	input Resetn;
	input [8:0] DataIn;	// 9 bits per pixel (rgb333)
	output [14:0] Address;	// need to address 160*120 = 19200 pixels = 15 bits
	output [7:0] X;
	output [6:0] Y;
	output [8:0] Color;
	output VGA_Draw;
	output Done;
	
	reg Done, VGA_Draw, EnableX, EnableY, ResetX, ResetY;
	
	//
	// State Machine
	//
	
	reg [2:0] D, Q;
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
	// - handle memory retrieval and writing to vga adapter
	//
	
	// tile width/height counters
	wire [7:0] D_Xoff, Q_Xoff;
	wire [6:0] D_Yoff, Q_Yoff;
	assign X = Q_Xoff;
	assign Y = Q_Yoff;
	
	counter8b XOffsetCounter( // 160 = 8 bits
	.clock(Clock),
	.cnt_en(EnableX),
	.sclr(ResetX),
	.q(Q_Xoff));

	counter7b YOffsetCounter( // 120 = 7 bits
	.clock(Clock),
	.cnt_en(EnableY),
	.sclr(ResetY),
	.q(Q_Yoff));

	// memory address tile-offset counter
	
	wire [14:0] D_AdrsOff, Q_AdrsOff;
	wire EnableMemCounter;
	assign EnableMemCounter = EnableX | EnableY;
	
	counter15b MemoryCounter(// 19200 = 15 bits
	.clock(Clock),
	.cnt_en(EnableMemCounter),
	.sclr(ResetY),
	.q(Address));

	// Completion Comparators
	reg DoneX, DoneY;
	always @*
	begin
		// check if we've got 19200 pixels from memory
		if (Address == 19200)	DoneY <= 1'b1;
		else					DoneY <= 1'b0;
		// check if the x offset equals tile width
		if (Q_Xoff == 160)		DoneX <= 1'b1;
		else					DoneX <= 1'b0;
	end
	
	// Color output
	assign Color = DataIn;
	
endmodule
