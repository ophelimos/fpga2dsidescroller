module main_state_machine
	(
		CLOCK_50,						//	On Board 50 MHz
		KEY,							//	Push Buttons
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK,						//	VGA BLANK
		VGA_SYNC,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B,   						//	VGA Blue[9:0]
		SW,								//  Switches
		LEDR,							//  Red LEDs
		LEDG							//  Green LEDs
	);

	input			CLOCK_50;				//	50 MHz
	input	[3:0]	KEY;					//	Buttons
	input   [0:0]   SW;						//  Switches
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK;				//	VGA BLANK
	output			VGA_SYNC;				//	VGA SYNC
	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]
	output 	[17:0] 	LEDR;					//  Red LEDs
	output 	[7:0] 	LEDG;					//  Green LEDs
	
	wire resetn;
	assign resetn = SW[0];
	
	// Create the color, x, y and writeEn wires that are inputs to the controller.

	wire [2:0] color;
	wire [7:0] x;
	wire [6:0] y;
	wire writeEn;

	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(color),
			.x(x),
			.y(y),
			.plot(writeEn),
			/* Signals for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK),
			.VGA_SYNC(VGA_SYNC),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "<put your background image here>";

	//------------------------------------------
	// DrawBackground instantiation
	//------------------------------------------
	
	assign Clock = CLOCK_50;
	
	wire [7:0] x_background;
	wire [6:0] y_background;
	wire [2:0] color_background;
	
	drawBackground draw_background(
	.resetn(resetn),
	.clock(Clock),
	.color(color_background),
	.x(x_background),
	.y(y_background),
	.plot(writeEn_background),
	.x_offset(position),
	.enable(draw_background_enable),
	.done(draw_background_done));/*,
	.p_D(LEDR[2:0]),
	.y_D(LEDG[2:0]));*/
	
	//------------------------------------------
	// Counters
	//------------------------------------------
	
	// Character position counter - 32bit
	
	reg  position_cnt_enable, position_cnt_reset;
	wire [31:0] position;
	
	counter32b position_counter(
	.clock(Clock),
	.cnt_en(position_cnt_enable & ~KEY[3]),
	.sclr(position_cnt_reset),
	.q(position));
	
	//------------------------------------------
	// Main State Machine
	//------------------------------------------
	
	// Signals -- always reg
	reg draw_background_enable_out;
	assign draw_background_enable = draw_background_enable_out;
	reg [7:0] x_out;
	assign x = x_out;
	reg [6:0] y_out;
	assign y = y_out;
	reg [2:0] color_out;
	assign color = color_out;
	reg writeEn_out;
	assign writeEn = writeEn_out;
	
	// Main State flipflops
	reg [2:0] main_Q, main_D;
	always @ (posedge Clock or negedge resetn)
	begin: main_state_FFs
		if (!resetn)
			main_Q <= 2'b00;
		else
			main_Q <= main_D;
	end
	
	// Main State Machine
	parameter PAINT_BACKGROUND = 0, DOSTUFF = 1;//states
	always @ (*)
	begin: main_state_table
		case (main_Q)
			PAINT_BACKGROUND: if (draw_background_done == 1) main_D <= DOSTUFF;
			else main_D <= PAINT_BACKGROUND;
			DOSTUFF: main_D <= PAINT_BACKGROUND;
			default: main_D <= 'bx;
		endcase
	end
	
	// Main Datapath
	always @ (*)
	begin: main_datapath
		case (main_D)
			PAINT_BACKGROUND: 	begin position_cnt_enable = 0; 		draw_background_enable_out = 1; 	x_out = x_background; 	y_out = y_background; 	color_out = color_background; 	writeEn_out = writeEn_background; end
			DOSTUFF:			begin position_cnt_enable = 1; 		draw_background_enable_out = 0; 	x_out = 8'bx; 			y_out = 7'bx; 			color_out = 3'bx; 				writeEn_out = 1'bx; end
			default: 			begin position_cnt_enable = 1'bx; 	draw_background_enable_out = 1'bx; 	x_out = 8'bx; 			y_out = 7'bx; 			color_out = 3'bx; 				writeEn_out = 1'bx; end			
		endcase
	end

endmodule
