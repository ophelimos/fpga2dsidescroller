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
	
	assign LEDR[3:0] = tile_code;
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
	// Screen Memory
	//------------------------------------------
	
	// Signals
	wire [14:0] screen_address;
	// 9-bit
	wire [8:0] lose_screen_pixel;
	wire [8:0] win_screen_pixel;
	
	// Instance declaration
   
	loseScreen lose_screen (
	.address(screen_address),
	.clock(CLOCK_50),
	.q(lose_screen_pixel));

	winScreen win_screen (
	.address(screen_address),
	.clock(CLOCK_50),
	.q(win_screen_pixel));

	//------------------------------------------
	// DrawBackground instantiation
	//------------------------------------------
	
	wire draw_background_done;
	wire [7:0] x_background;
	wire [6:0] y_background;
	wire [8:0] color_background;
	wire writeEn_background;
	wire [14:0] level_address_background;
	
	drawBackground draw_background(
	.resetn(resetn),
	.clock(CLOCK_50),
	.color(color_background),
	.level_address(level_address_background),
	.tile_code(tile_code),			// input - which tile to draw
	.x(x_background),
	.y(y_background),
	.plot(writeEn_background),
	.x_tile_offset(x_tile_position),
	.x_pixel_offset(x_pixel_on_tile_position),
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
	reg [2:0] AnimStep;		// animation 'frame' we are on, determined in Character Movement section
	wire [4:0] SpriteHeight, SpriteWidth;	// width and height of the selected sprite
	
	drawSprite draw_character(
	.Xin(x_character_position), 
	.Yin(y_character_position), 
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
	// drawScreen Instantiation
	//------------------------------------------

        wire screen_enable;
   	wire draw_screen_done;
	wire [7:0] x_screen;			// x position on screen (pixel)
	wire [6:0] y_screen;			// y position on screen (pixel)
	wire [8:0] color_screen;		// color output
	wire writeEn_screen;			// 'plot' signal
	wire [8:0] screen_pixel;

	drawScreen draw_screen(
						.Enable(screen_enable), 
						.Clock(CLOCK_50), 
						.Resetn(resetn),
						.DataIn(screen_pixel),
						.Address(screen_address), 
						.X(x_screen), 
						.Y(y_screen), 
						.Color(color_screen), 
						.VGA_Draw(writeEn_screen),
						.Done(draw_screen_done));
		
	//------------------------------------------
	// Collision Detection Area
	//------------------------------------------
	
	wire left_blocked;
	wire right_blocked;
	wire up_blocked;
	wire down_blocked;
	wire [14:0] level_address_collisions;
	
	detectBackgroundCollision background_collision_detector(
	.resetn(resetn), 
	.clock(CLOCK_50), 
	.enable(detect_collisions_enable),
	// Character position is in pixels on the screen, but we detect collisions based on tiles
	// in the tilemap (non screen-oriented)
        // Formula:
	// Character_position (tiles) = x_location (tiles) + character_position on screen (tiles)
	// In the y-direction though, we currently don't have this problem
	.x_location( (x_tile_position + (x_character_position / 4'd8)) ),
	.y_location( (y_character_position / 4'd8) ), 
	.memory_input(tile_code), 
	.memory_address(level_address_collisions), 
	.left(left_blocked), 
	.right(right_blocked), 
	.up(up_blocked), 
	.down(down_blocked), 
	.done(detect_background_collisions_done));
	
	wire detect_background_collisions_done;
	wire detect_collisions_done;
	
//	assign detect_background_collisions_done = 1;
	
	assign detect_collisions_done = detect_background_collisions_done;
	
	//------------------------------------------
	// Character Movement Area
	//------------------------------------------
	
	wire movement_enable;
	
	wire [7:0] x_character_position;
	wire [6:0] y_character_position;
	
	reg jump;
	
	// Jumping logic
	always @(*)
		if (movement_enable == 1 && KEY[1] == 0 && down_blocked == 1)
			jump = 1;
		else
			jump = 0;
	
	characterMovement character_movement (
	.clock(CLOCK_50),
	.enable(movement_enable),
	.resetn(resetn),
	.jump(jump),
	.left_blocked(left_blocked),
	.right_blocked(right_blocked), 
	.up_blocked(up_blocked), 
	.down_blocked(down_blocked),
	.x_position(x_character_position),
	.y_position(y_character_position));
	
	//------------------------------------------
	// Level Movement Area
	//------------------------------------------
	
	// Level x-offset tile position counter - 32bit
	
	reg x_tile_position_cnt_enable;
	reg x_tile_position_cnt_reset;
	reg x_tile_position_cnt_left;
	wire [31:0] x_tile_position;
	
	counter32b x_tile_position_counter(
	.clock(CLOCK_50),
	.cnt_en(x_tile_position_cnt_enable),
	.sclr(x_tile_position_cnt_reset),
	.updown(x_tile_position_cnt_left),
	.q(x_tile_position));
	
	// pixel offset per tile 0-7
	reg x_pixel_on_tile_cnt_enable;
//	reg x_pixel_on_tile_cnt_reset;
	reg x_pixel_on_tile_cnt_left;
	wire [2:0] x_pixel_on_tile_position;
	
	counter3b_updwn x_pixel_on_tile_counter(
	.clock(CLOCK_50),
	.cnt_en(x_pixel_on_tile_cnt_enable),
	.sclr(1'b0),
	.updown(x_pixel_on_tile_cnt_left),
	.q(x_pixel_on_tile_position));
	
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
				
	
	// Moving left or right logic
	always @(*)
		if (movement_enable == 1 && KEY[3] == 0 && right_blocked == 0)
			begin
				x_tile_position_cnt_left = 1'b0;	// move right
				x_pixel_on_tile_cnt_left = 1'b0;	//
				
				if (x_pixel_on_tile_position == 7)	// increment tile
						x_tile_position_cnt_enable = 1'b1;
				else
						x_tile_position_cnt_enable = 1'b0;
						
				x_pixel_on_tile_cnt_enable = 1'b1;	// increment pixel on tile

			end
		else if (movement_enable == 1 && KEY[0] == 0 && left_blocked == 0)	
			begin
				x_pixel_on_tile_cnt_left = 1'b1;	// move left
				x_tile_position_cnt_left = 1'b1;	//
				
				if (x_pixel_on_tile_position == 0)	// decrement tile
						x_tile_position_cnt_enable = 1'b1;
				else
						x_tile_position_cnt_enable = 1'b0;

				x_pixel_on_tile_cnt_enable = 1'b1;	// decrement pixel on tile

			end
		else
			begin
				x_tile_position_cnt_enable = 1'b0;
				x_pixel_on_tile_cnt_enable = 1'b0;
				x_tile_position_cnt_left = 1'bx;
				x_pixel_on_tile_cnt_left = 1'bx;
			end
			
	//-----------------------------------------
	// Character Animation
	//-----------------------------------------
	
	reg character_facing_left; 
	wire [4:0] char_anim_cnt_value;
	reg character_moving;
	
	// determine if character is moving
	// and direction
	always @(*)
	begin
		if (~KEY[0] || ~KEY[3])
			character_moving = 1'b1;
		else
			character_moving = 1'b0;
			
		if (~KEY[0])
			character_facing_left = 1'b1;
		if (~KEY[3])
			character_facing_left = 1'b0;
	end
	
	// used to toggle frames when running
	// - counts to 32 (each tick represents 1/60th sec)
	counter5b char_anim_counter (
	.clock(time_cnt_enable),	// linked to 60fps counter (essentially incremented each drawBG)
	.cnt_en(character_moving),
	.sclr(resetn),
	.q(char_anim_cnt_value));
	
	// determine which animation frame to draw
	//
	// AnimStep	0 - facing right, step/jump
	//			1 - facing right, still
	//			2 - facing left, step/jump
	//			3 - facing left, still
	always @(*)
	begin
		if (jump == 1)	// jumping
			begin
				if (character_facing_left == 1)
					AnimStep = 3'd2;
				else
					AnimStep = 3'd0;
			end
		else if	(character_moving == 1)	// running
			begin		
				if (char_anim_cnt_value > 15)
				begin
					if (character_facing_left == 1)
						AnimStep = 3'd2;
					else
						AnimStep = 3'd0;
				end
				else
				begin
					if (character_facing_left == 1)
						AnimStep = 3'd3;
					else
						AnimStep = 3'd1;
				end
			end
		else			// standing still
			begin
				if (character_facing_left == 1)
					AnimStep = 3'd3;
				else
					AnimStep = 3'd1;
			end	
	end
	
	//------------------------------------------
	// Scoring
	//------------------------------------------
	
	// Score Counters --- 0-9 on 3 hexadecimal displays
	reg score_cnt_reset;
	wire [25:0] score_cnt;
	wire score_enable;
	
	counter26b score_counter (
		.clock(CLOCK_50),
		.cnt_en(score_enable),
		.sclr(score_cnt_reset || ~resetn),
		.q(score_cnt));
		
	always @(posedge CLOCK_50)
		if (score_cnt == 5)	// 50_000_000
			begin
				score_cnt_reset = 0;
				score_out0_enable = 1;
			end
		else if (score_out0_enable == 1)
			begin
				score_out0_enable = 0;
				score_cnt_reset = 1;
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
	wire [3:0] score_out0/*synthesis keep*/;
	
	counter4b score_cnt_out0 (
		.clock(CLOCK_50),
		.cnt_en(score_out0_enable),
		.sclr(score_out0_reset || ~resetn),
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
	wire [3:0] score_out1/*synthesis keep*/;
	
	counter4b score_cnt_out1 (
		.clock(CLOCK_50),
		.cnt_en(score_out1_enable),
		.sclr(score_out1_reset || ~resetn),
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
	wire [3:0] score_out2/*synthesis keep*/;
	
	counter4b score__cnt_out2 (
		.clock(CLOCK_50),
		.cnt_en(score_out2_enable),
		.sclr(score_out2_reset || ~resetn),
		.q(score_out2));
	
		
	hex_digits hex0 (score_out0, HEX0);
	hex_digits hex1 (score_out1, HEX1);
	hex_digits hex2 (score_out2, HEX2);
	
	always @(*)
		if (score_out2 == 10)
			begin
				score_out2_reset = 1;
			end
		else
			begin
				score_out2_reset = 0;
			end
	
	//------------------------------------------
	// Main State Machine
	//------------------------------------------
	
	// Signals -- always reg
	reg draw_background_enable_out/*synthesis keep*/;
	wire draw_background_enable;
	assign draw_background_enable = draw_background_enable_out;
	reg draw_character_enable_out/*synthesis keep*/;
	wire draw_character_enable;
	assign draw_character_enable = draw_character_enable_out;
	reg draw_enemies_enable_out/*synthesis keep*/;
	wire draw_enemies_enable;
	assign draw_enemies_enable = draw_enemies_enable_out;
	reg detect_collisions_enable_out/*synthesis keep*/;
	wire detect_collisions_enable;
	assign detect_collisions_enable = detect_collisions_enable_out;
	reg [7:0] x_out/*synthesis keep*/;
	assign x = x_out;
	reg [6:0] y_out/*synthesis keep*/;
	assign y = y_out;
	reg [8:0] color_out/*synthesis keep*/;
	assign color = color_out;
	reg writeEn_out/*synthesis keep*/;
	assign writeEn = writeEn_out;
	reg [14:0] level_address_out/*synthesis keep*/;
	assign level_address = level_address_out;
	reg movement_enable_out/*synthesis keep*/;
	assign movement_enable = movement_enable_out;
        reg score_enable_out;
        assign score_enable = score_enable_out;
        reg screen_enable_out;
        assign screen_enable = screen_enable_out;
	reg [8:0] screen_pixel_out;
        assign screen_pixel = screen_pixel_out;
	
	// Main State flipflops
	reg [2:0] main_Q, main_D /*synthesis keep*/; 
	always @ (posedge CLOCK_50)
	begin: main_state_FFs
		if (~resetn)
			main_Q <= WAIT;		// state to reset to
		else
			main_Q <= main_D;
	end
	
	// Main State Machine
	parameter DRAW_BACKGROUND = 0, DRAW_CHARACTER = 1, DRAW_ENEMIES = 2, DETECT_COLLISIONS = 3, MOVEMENT = 4, WAIT = 5, LOSE = 6, WIN = 7;//states
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
			WAIT: if (y == 7'd121) main_D <= LOSE; // Off the bottom of the screen
                        else if (x_tile_position == 32'd1980) main_D <= WIN; // This should NOT be hardcoded!  We need a way of parameterizing how big these levels are
                        else if (time_cnt_enable == 0) main_D <= DRAW_BACKGROUND;
			else main_D <= WAIT;
                        LOSE: main_D <= LOSE;
                        WIN: main_D <= WIN;
			default: main_D <= 3'bx;
		endcase
	end
	
	// Main Datapath
	always @ (*)
	begin: main_datapath
		case (main_Q)
			DRAW_BACKGROUND: 
				begin 	
						movement_enable_out = 0; 
						draw_background_enable_out = 1;
						draw_character_enable_out = 0;
						draw_enemies_enable_out = 0;
						detect_collisions_enable_out = 0;
						x_out = x_background; 
						y_out = y_background; 
						color_out = color_background; 
						writeEn_out = writeEn_background;
						time_cnt_reset = 1'b1;
						level_address_out = level_address_background;
                                                screen_enable_out = 1'b0;
                                                score_enable_out = 1'b0;
                                                screen_pixel_out = 9'bx;
				end
			DRAW_CHARACTER:
				begin 	
						movement_enable_out = 0; 
						draw_background_enable_out = 0;
						draw_character_enable_out = 1;
						draw_enemies_enable_out = 0;
						detect_collisions_enable_out = 0;
						x_out = x_character; 
						y_out = y_character; 
						color_out = color_character; 
						writeEn_out = writeEn_character;
						time_cnt_reset = 1'b0;
						level_address_out = 4'bx;
                                                screen_enable_out = 1'b0;
                                                score_enable_out = 1'b0;
                                                screen_pixel_out = 9'bx;
				end
			DRAW_ENEMIES:
				begin 	
						movement_enable_out = 0; 
						draw_background_enable_out = 0;
						draw_character_enable_out = 0;
						draw_enemies_enable_out = 1;
						detect_collisions_enable_out = 0;
						x_out = 8'bx; 
						y_out = 7'bx; 
						color_out = 9'bx; 
						writeEn_out = 0;
						time_cnt_reset = 1'b0;
						level_address_out = 4'bx;
                                                screen_enable_out = 1'b0;
                                                score_enable_out = 1'b0;
                                                screen_pixel_out = 9'bx;
				end
			DETECT_COLLISIONS:
				begin 	
						movement_enable_out = 0; 
						draw_background_enable_out = 0;
						draw_character_enable_out = 0;
						draw_enemies_enable_out = 0;
						detect_collisions_enable_out = 1;
						x_out = 8'bx; 
						y_out = 7'bx; 
						color_out = 9'bx; 
						writeEn_out = 0;
						time_cnt_reset = 1'b0;
						level_address_out = level_address_collisions;
                                                screen_enable_out = 1'b0;
                                                score_enable_out = 1'b0;
                                                screen_pixel_out = 9'bx;
				end
			MOVEMENT:
				begin 	
						movement_enable_out = 1; 
						draw_background_enable_out = 0;
						draw_character_enable_out = 0;
						draw_enemies_enable_out = 0;
						detect_collisions_enable_out = 0;
						x_out = 8'bx; 
						y_out = 7'bx; 
						color_out = 9'bx; 
						writeEn_out = 0;
						time_cnt_reset = 1'b0;
						level_address_out = 4'bx;
                                                screen_enable_out = 1'b0;
                                                score_enable_out = 1'b0;
                                                screen_pixel_out = 9'bx;
				end
			WAIT:
				begin 	
						movement_enable_out = 0; 
						draw_background_enable_out = 0;
						draw_character_enable_out = 0;
						draw_enemies_enable_out = 0;
						detect_collisions_enable_out = 0;
						x_out = 8'bx; 
						y_out = 7'bx; 
						color_out = 9'bx; 
						writeEn_out = 0;
						time_cnt_reset = 1'b0;
						level_address_out = 4'bx;
                                                screen_enable_out = 1'b0;
                                                score_enable_out = 1'b0;
                                                screen_pixel_out = 9'bx;
				end
			LOSE:
				begin 	
						movement_enable_out = 0; 
						draw_background_enable_out = 0;
						draw_character_enable_out = 0;
						draw_enemies_enable_out = 0;
						detect_collisions_enable_out = 0;
						x_out = x_screen; 
						y_out = y_screen; 
						color_out = color_screen; 
						writeEn_out = writeEn_screen;
						time_cnt_reset = 1'b0;
						level_address_out = 4'bx;
                                                screen_enable_out = 1'b1;
                                                score_enable_out = 1'b0;
                                                screen_pixel_out = lose_screen_pixel;
                          
				end
			WIN:
				begin 	
						movement_enable_out = 0; 
						draw_background_enable_out = 0;
						draw_character_enable_out = 0;
						draw_enemies_enable_out = 0;
						detect_collisions_enable_out = 0;
						x_out = x_screen; 
						y_out = y_screen; 
						color_out = color_screen; 
						writeEn_out = writeEn_screen;
						time_cnt_reset = 1'b0;
						level_address_out = 4'bx;
                                                screen_enable_out = 1'b1;
                                                score_enable_out = 1'b0;
                                                screen_pixel_out = win_screen_pixel;
                          
				end
			default: 
				begin 	
						movement_enable_out = 1'bx; 
						draw_background_enable_out = 1'bx;
						draw_character_enable_out = 1'bx;
						draw_enemies_enable_out = 1'bx;
						detect_collisions_enable_out = 1'bx;
						x_out = 8'bx; 
						y_out = 7'bx; 
						color_out = 9'bx; 
						writeEn_out = 1'bx;
						time_cnt_reset = 1'bx;
						level_address_out = 4'bx;
                                                screen_enable_out = 1'bx;
                                                score_enable_out = 1'bx;
                                                screen_pixel_out = 9'bx;
				end
			endcase
	end

endmodule
