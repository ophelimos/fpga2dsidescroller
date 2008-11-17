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

	wire [8:0] color;
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
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 3;
		defparam VGA.BACKGROUND_IMAGE = "display.mif";

	//------------------------------------------
	// Level Memory
	//------------------------------------------
	
	// Signals
	wire [14:0] level_address;
	// We agreed on 4-bit, but 3-bit works for now
	wire [2:0] tile_code;
	
	// Instance declaration
	level1 level_mem (
	.address(level_address),
	.clock(clock),
	.data(3'bx),
	.wren(1'b0),
	.q(tile_code));

	//------------------------------------------
	// DrawBackground instantiation
	//------------------------------------------
	
	assign Clock = CLOCK_50;
	
	wire [7:0] x_background;
	wire [6:0] y_background;
	wire [8:0] color_background;
	
	drawBackground draw_background(
	.resetn(resetn),
	.clock(Clock),
	.color(color_background),
	.level_address(level_address),
	.tile_code(tile_code),
	.x(x_background),
	.y(y_background),
	.plot(writeEn_background),
	.x_offset(x_position),
	.enable(draw_background_enable),
	.done(draw_background_done));/*,
	.p_D(LEDR[2:0]),
	.y_D(LEDG[2:0]));*/
	
	//------------------------------------------
	// DrawCharacter instantiation
	//------------------------------------------
	
	wire draw_character_done;
	
	assign draw_character_done = 1;
	
	//------------------------------------------
	// DrawEnemies instantiation
	//------------------------------------------
	
	wire draw_enemies_done;
	
	assign draw_enemies_done = 1;
	
	//------------------------------------------
	// DetectBackgroundCollisions instantiation
	//------------------------------------------
	
	wire detect_background_collisions_done;
	wire detect_collisions_done;
	
	assign detect_background_collisions_done = 1;
	
	assign detect_collisions_done = detect_background_collisions_done;
	
	//------------------------------------------
	// Movement and Physics Area
	//------------------------------------------
	
	// Character x position counter - 32bit
	
	reg  x_position_cnt_enable, x_position_cnt_reset;
	wire [31:0] x_position;
	
	counter32b x_position_counter(
	.clock(Clock),
	.cnt_en(x_position_cnt_enable & ~KEY[3]),
	.sclr(x_position_cnt_reset),
	.q(x_position));
	
	//------------------------------------------
	// Main State Machine
	//------------------------------------------
	
	// Signals -- always reg
	reg draw_background_enable_out;
	assign draw_background_enable = draw_background_enable_out;
	reg draw_character_enable_out;
	assign draw_character_enable = draw_character_enable_out;
	reg draw_enemies_enable_out;
	assign draw_enemies_enable = draw_enemies_enable_out;
	reg detect_collisions_enable_out;
	assign detect_collisions_enable = detect_collisions_enable_out;
	reg [7:0] x_out;
	assign x = x_out;
	reg [6:0] y_out;
	assign y = y_out;
	reg [8:0] color_out;
	assign color = color_out;
	reg writeEn_out;
	assign writeEn = writeEn_out;
	
	// Main State flipflops
	reg [2:0] main_Q, main_D;
	always @ (posedge Clock or negedge resetn)
	begin: main_state_FFs
		if (!resetn)
			main_Q <= 'b0;
		else
			main_Q <= main_D;
	end
	
	// Main State Machine
	parameter DRAW_BACKGROUND = 0, DRAW_CHARACTER = 1, DRAW_ENEMIES = 2, DETECT_COLLISIONS = 3, MOVEMENT = 4;//states
	always @ (*)
	begin: main_state_table
		case (main_Q)
			DRAW_BACKGROUND: if (draw_background_done == 1) main_D <= DRAW_CHARACTER;
			else main_D <= DRAW_BACKGROUND;
			DRAW_CHARACTER: if (draw_character_done == 1) main_D <= DRAW_ENEMIES;
			else main_D <= DRAW_CHARACTER;
			DRAW_ENEMIES: if (draw_enemies_done == 1) main_D <= DETECT_COLLISIONS;
			else main_D <= DRAW_ENEMIES;
			DETECT_COLLISIONS: if (detect_collisions_done == 1) main_D <= MOVEMENT;
			MOVEMENT: main_D <= DRAW_BACKGROUND;
			default: main_D <= 'bx;
		endcase
	end
	
	// Main Datapath
	always @ (*)
	begin: main_datapath
		case (main_D)
			DRAW_BACKGROUND: 
				begin 	x_position_cnt_enable = 0; 
						draw_background_enable_out = 1;
						draw_character_enable_out = 0;
						draw_enemies_enable_out = 0;
						detect_collisions_enable_out = 0;
						x_out = x_background; 
						y_out = y_background; 
						color_out = color_background; 
						writeEn_out = writeEn_background;
				end
			DRAW_CHARACTER:
				begin 	x_position_cnt_enable = 0; 
						draw_background_enable_out = 0;
						draw_character_enable_out = 1;
						draw_enemies_enable_out = 0;
						detect_collisions_enable_out = 0;
						x_out = x_background; 
						y_out = y_background; 
						color_out = color_background; 
						writeEn_out = writeEn_background;
				end
			DRAW_ENEMIES:
				begin 	x_position_cnt_enable = 0; 
						draw_background_enable_out = 0;
						draw_character_enable_out = 0;
						draw_enemies_enable_out = 1;
						detect_collisions_enable_out = 0;
						x_out = x_background; 
						y_out = y_background; 
						color_out = color_background; 
						writeEn_out = writeEn_background;
				end
			DETECT_COLLISIONS:
				begin 	x_position_cnt_enable = 0; 
						draw_background_enable_out = 0;
						draw_character_enable_out = 0;
						draw_enemies_enable_out = 0;
						detect_collisions_enable_out = 1;
						x_out = x_background; 
						y_out = y_background; 
						color_out = color_background; 
						writeEn_out = writeEn_background;
				end
			MOVEMENT:
				begin 	x_position_cnt_enable = 1; 
						draw_background_enable_out = 0;
						draw_character_enable_out = 0;
						draw_enemies_enable_out = 0;
						detect_collisions_enable_out = 0;
						x_out = x_background; 
						y_out = y_background; 
						color_out = color_background; 
						writeEn_out = writeEn_background;
				end
			default: 
				begin 	x_position_cnt_enable = 1'bx; 
						draw_background_enable_out = 1'bx;
						draw_character_enable_out = 1'bx;
						draw_enemies_enable_out = 1'bx;
						detect_collisions_enable_out = 1'bx;
						x_out = 'bx; 
						y_out = 'bx; 
						color_out = 'bx; 
						writeEn_out = 'bx;
				end
			endcase
	end

endmodule