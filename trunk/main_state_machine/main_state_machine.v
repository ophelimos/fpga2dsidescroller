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
		LEDG,							//  Green LEDs
		HEX0, HEX1, HEX2				//  Hexadecimal Displays
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
	output  [6:0] HEX2, HEX1, HEX0;			//  Hexadecimal Displays
	
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
	// Debugging
	//------------------------------------------
	
	assign LEDR[2:0] = tile_code;
	assign LEDR[17:15] = main_Q;
	assign LEDR[14:12] = main_D;
	assign LEDG[0] = draw_background_done;

	//------------------------------------------
	// Level Memory
	//------------------------------------------
	
	// Signals
	wire [14:0] level_address;
	// 4-bit
	wire [3:0] tile_code;
	
	// Instance declaration
	level1 level_mem (
	.address(level_address),
	.clock(CLOCK_50),
	.q(tile_code));						// todo: change to accept 4-bit tile_code

	//------------------------------------------
	// Character Memory
	//------------------------------------------
	
	wire [11:0] character_address;
	wire [8:0] char_color;
	wire [2:0] CharAnimSteps;	// the total number of animation frames (this value is received from memory)
	
	// Sprite Memory
	// contains 8 sprite memory blocks
	SpriteMem character_mem(
		.MemSel(SpriteSelect), 
		.Address(character_address), 
		.DataOut(char_color), 
		.Clock(CLOCK_50), 
		.Resetn(resetn), 
		.Width(SpriteWidth), 	// gets width of SpriteSelect sprite
		.Height(SpriteHeight), 	// " height
		.AnimSteps(CharAnimSteps));	// " number of animation frames
	
	//------------------------------------------
	// DrawBackground instantiation
	//------------------------------------------
	
	wire draw_background_done;
	wire [7:0] x_background;
	wire [6:0] y_background;
	wire [8:0] color_background;
	wire writeEn_background;
	
	drawBackground draw_background(
	.resetn(resetn),
	.clock(CLOCK_50),
	.color(color_background),
	.level_address(level_address),
	.tile_code(tile_code),			// input - which tile to draw
	.x(x_background),
	.y(y_background),
	.plot(writeEn_background),
	.x_offset(x_position),
	.enable(draw_background_enable),
	.done(draw_background_done));
	
	//------------------------------------------
	// DrawCharacter instantiation
	//------------------------------------------
	
	wire draw_character_done;
	wire [7:0] x_character;			// x position on screen (pixel)
	wire [6:0] y_character;			// y position on screen (pixel)
	wire [8:0] color_character;		// color output
	wire writeEn_character;			// 'plot' signal
	
	wire [2:0] SpriteSelect;	// choose which sprite we want to work with (draw)
	assign SpriteSelect = 3'b0;
	wire [2:0] AnimStep;		// animation 'frame' we are on (default 0)
	assign AnimStep = 3'b0;	
	wire [4:0] SpriteHeight, SpriteWidth;	// width and height of the selected sprite
	
	drawSprite draw_character(
	.Xin(72), 
	.Yin(y_position), 
	.Sprite(SpriteSelect), 
	.AnimStep(AnimStep), 
	.Width(SpriteWidth), 
	.Height(SpriteHeight), 
	.DataIn(char_color), 
	.Enable(draw_character_enable), 
	.Resetn(resetn), 
	.Clock(CLOCK_50), 
	.MemSel(SpriteSelect), 
	.Address(character_address), 
	.Xout(x_character), 
	.Yout(y_character), 
	.Color(color_character), 
	.Done(draw_character_done), 
	.VGA_Draw(writeEn_character));
	
	//assign draw_character_done = 1;
	
	//------------------------------------------
	// DrawEnemies instantiation
	//------------------------------------------
	
	wire draw_enemies_done;
	
	assign draw_enemies_done = 1;
	
	//------------------------------------------
	// Collision Detection Area
	//------------------------------------------
	
	wire left_blocked;
	wire right_blocked;
	wire up_blocked;
	wire down_blocked;
	
	/*detectBackgroundCollision background_collision_detector(
	.resetn(resetn), 
	.clock(CLOCK_50), 
	.enable(detect_collisions_enable), 
	.x_location(x_location), 
	.y_location(y_location), 
	.memory_input(tile_code), 
	.memory_address(level_address), 
	.left(left_blocked), 
	.right(right_blocked), 
	.up(up_blocked), 
	.down(down_blocked), 
	.done(detect_background_collisions_done));*/
	
	wire detect_background_collisions_done;
	wire detect_collisions_done;
	
	assign detect_background_collisions_done = 1;
	
	assign detect_collisions_done = detect_background_collisions_done;
	
	//------------------------------------------
	// Movement and Physics Area
	//------------------------------------------
	
	// Character x position counter - 32bit
	
	reg x_position_cnt_enable;
	reg  x_position_cnt_reset;
	wire [31:0] x_position;
	
	counter32b x_position_counter(
	.clock(CLOCK_50),
	.cnt_en(x_position_cnt_enable),
	.sclr(x_position_cnt_reset),
	.q(x_position));
	
	// Character y position (fixed for now)
	wire [6:0] y_position;
	assign y_position = 7'd60;	// just below center on the screen (in pixels)
	
	// 60 fps = 833_333 clocks which needs 20 bits
	reg time_cnt_reset;
	reg time_cnt_enable;
	wire [19:0] time_out;
	
	counter20b count60fps (
		.clock(CLOCK_50),
		.cnt_en(time_cnt_enable),
		.sclr(time_cnt_reset),
		.q(time_out));
	
	// Make the time counter reset appropriately
	always @(*)
		if (time_out == 833_333)
			begin
				time_cnt_enable = 1'b0;
			end
		else
			begin
				time_cnt_enable = 1'b1;
			end
				
	
	// Counter enable logic
	always @(*)
		if ( (x_movement_enable == 1) && (KEY[3] == 0))
			begin
				x_position_cnt_enable = 1'b1;
			end
		else
			begin
				x_position_cnt_enable = 1'b0;
			end
	
		
	//------------------------------------------
	// Scoring
	//------------------------------------------
	
	// Score Counters --- 0-9 on 3 hexadecimal displays
	reg score_cnt_enable;
	reg score_cnt_reset;
	wire [25:0] score_cnt;
	
	counter26b score_counter (
		.clock(CLOCK_50),
		.cnt_en(score_cnt_enable),
		.sclr(score_cnt_reset),
		.q(score_cnt));
		
	always @(*)
		if (score_cnt == 50_000_000)
			begin
				score_cnt_reset = 1;
				score_out0_enable = 1;
			end
		else
			begin
				score_cnt_reset = 0;
				score_out0_enable = 0;
			end
	
	// This should be done with a generate, but I haven't
	// bothered to look up the syntax
	
/*	genvar i;
	parameter numHex = 3;
	
	reg [numHex-1:0] score_out_enable;
	reg [numHex-1:0] score_out_reset;
	wire [numHex-1:0] score_out[3:0];

	generate
		for (i = 0; i < 3; i = i + 1)
		begin: countersto9
			reg score_out_enable;
			reg score_out_reset;
			wire [3:0] score_out;
	
			counter4b score_cnt_out(
				.clock(CLOCK_50),
				.cnt_en(score_out_enable),
				.sclr(score_out_reset),
				.q(score_out));
				
			hex_digits hex (score_out[i], HEX[i]);
		end
	endgenerate
*/	

	reg score_out0_enable;
	reg score_out0_reset;
	wire [3:0] score_out0;
	
	counter4b score_cnt_out0 (
		.clock(CLOCK_50),
		.cnt_en(score_out0_enable),
		.sclr(score_out0_reset),
		.q(score_out0));
		
	always @(*)
		if (score_out0 == 10)
			begin
				score_out0_reset = 1;
				score_out1_enable = 1;
			end
		else
			begin
				score_out0_reset = 0;
				score_out1_enable = 0;
			end
	
	reg score_out1_enable;
	reg score_out1_reset;
	wire [3:0] score_out1;
	
	counter4b score_cnt_out1 (
		.clock(CLOCK_50),
		.cnt_en(score_out1_enable),
		.sclr(score_out1_reset),
		.q(score_out1));
		
	always @(*)
		if (score_out1 == 10)
			begin
				score_out1_reset = 1;
				score_out2_enable = 1;
			end
		else
			begin
				score_out1_reset = 0;
				score_out2_enable = 0;
			end
		
	reg score_out2_enable;
	reg score_out2_reset;
	wire [3:0] score_out2;
	
	counter4b score__cnt_out2 (
		.clock(CLOCK_50),
		.cnt_en(score_out2_enable),
		.sclr(score_out2_reset),
		.q(score_out2));
	
		
	hex_digits hex0 (score_out0, HEX0);
	hex_digits hex1 (score_out1, HEX1);
	hex_digits hex2 (score_out2, HEX2);
	
	//------------------------------------------
	// Main State Machine
	//------------------------------------------
	
	// Signals -- always reg
	reg draw_background_enable_out;
	wire draw_background_enable;
	assign draw_background_enable = draw_background_enable_out;
	reg draw_character_enable_out;
	wire draw_character_enable;
	assign draw_character_enable = draw_character_enable_out;
	reg draw_enemies_enable_out;
	wire draw_enemies_enable;
	assign draw_enemies_enable = draw_enemies_enable_out;
	reg detect_collisions_enable_out;
	wire detect_collisions_enable;
	assign detect_collisions_enable = detect_collisions_enable_out;
	reg [7:0] x_out;
	assign x = x_out;
	reg [6:0] y_out;
	assign y = y_out;
	reg [8:0] color_out;
	assign color = color_out;
	reg writeEn_out;
	assign writeEn = writeEn_out;
	reg  x_movement_enable;
	
	// Main State flipflops
	reg [2:0] main_Q, main_D /*synthesis keep*/; 
	always @ (posedge CLOCK_50 or negedge resetn)
	begin: main_state_FFs
		if (!resetn)
			main_Q <= 0;
		else
			main_Q <= main_D;
	end
	
	// Main State Machine
	parameter DRAW_BACKGROUND = 0, DRAW_CHARACTER = 1, DRAW_ENEMIES = 2, DETECT_COLLISIONS = 3, MOVEMENT = 4, WAIT = 5;//states
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
			else main_D <= DETECT_COLLISIONS;
			MOVEMENT: main_D <= WAIT;
			WAIT: if (time_cnt_enable == 0) main_D <= DRAW_BACKGROUND;
			else main_D <= WAIT;
			default: main_D <= 3'bx;
		endcase
	end
	
	// Main Datapath
	always @ (*)
	begin: main_datapath
		case (main_D)
			DRAW_BACKGROUND: 
				begin 	x_movement_enable = 0; 
						draw_background_enable_out = 1;
						draw_character_enable_out = 0;
						draw_enemies_enable_out = 0;
						detect_collisions_enable_out = 0;
						x_out = x_background; 
						y_out = y_background; 
						color_out = color_background; 
						writeEn_out = writeEn_background;
						time_cnt_reset = 1'b1;
				end
			DRAW_CHARACTER:
				begin 	x_movement_enable = 0; 
						draw_background_enable_out = 0;
						draw_character_enable_out = 1;
						draw_enemies_enable_out = 0;
						detect_collisions_enable_out = 0;
						x_out = x_character; 
						y_out = y_character; 
						color_out = color_character; 
						writeEn_out = writeEn_character;
						time_cnt_reset = 1'b0;
				end
			DRAW_ENEMIES:
				begin 	x_movement_enable = 0; 
						draw_background_enable_out = 0;
						draw_character_enable_out = 0;
						draw_enemies_enable_out = 1;
						detect_collisions_enable_out = 0;
						x_out = x_background; 
						y_out = y_background; 
						color_out = color_background; 
						writeEn_out = writeEn_background;
						time_cnt_reset = 1'b0;
				end
			DETECT_COLLISIONS:
				begin 	x_movement_enable = 0; 
						draw_background_enable_out = 0;
						draw_character_enable_out = 0;
						draw_enemies_enable_out = 0;
						detect_collisions_enable_out = 1;
						x_out = 0; 
						y_out = 0; 
						color_out = 0; 
						writeEn_out = 0;
						time_cnt_reset = 1'b0;
				end
			MOVEMENT:
				begin 	x_movement_enable = 1; 
						draw_background_enable_out = 0;
						draw_character_enable_out = 0;
						draw_enemies_enable_out = 0;
						detect_collisions_enable_out = 0;
						x_out = 0; 
						y_out = 0; 
						color_out = 0; 
						writeEn_out = 0;
						time_cnt_reset = 1'b0;
				end
			WAIT:
				begin 	x_movement_enable = 0; 
						draw_background_enable_out = 0;
						draw_character_enable_out = 0;
						draw_enemies_enable_out = 0;
						detect_collisions_enable_out = 0;
						x_out = 0; 
						y_out = 0; 
						color_out = 0; 
						writeEn_out = 0;
						time_cnt_reset = 1'b0;
				end
			default: 
				begin 	x_movement_enable = 1'bx; 
						draw_background_enable_out = 1'bx;
						draw_character_enable_out = 1'bx;
						draw_enemies_enable_out = 1'bx;
						detect_collisions_enable_out = 1'bx;
						x_out = 'bx; 
						y_out = 'bx; 
						color_out = 'bx; 
						writeEn_out = 1'bx;
						time_cnt_reset = 1'bx;
				end
			endcase
	end

endmodule