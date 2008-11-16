module drawBackground(resetn, clock, color, x, y, x_offset, enable, plot, done, p_Q, p_D, y_Q, y_D);
	//------------------------------------------
	// Parameters
	//------------------------------------------
	parameter tilemap_length = 100; // In tiles
	parameter color_depth = 9;
	//------------------------------------------
	// Inputs
	//------------------------------------------
	input clock;
	input [(tilemap_length / 15):0] x_offset; // In tiles
	input enable;
	input resetn;
	//------------------------------------------
	// Outputs
	//------------------------------------------
	output [7:0] x;
	output [6:0] y;
	output [(color_depth - 1):0] color;
	output plot;
	output done;
	output [2:0] p_Q;
	output [2:0] p_D;
	output [2:0] y_D;
	output [2:0] y_Q;
	
	//------------------------------------------
	// Level Memory
	//------------------------------------------
	
	// Signals
	wire [14:0] level_address;
	wire tile_code;
	
	// Instance declaration
	level1 level_mem (
	.address(level_address),
	.clock(clock),
	.data(1'bx),
	.wren(1'b0),
	.q(tile_code));
	
	//------------------------------------------
	// Tile Memory
	//------------------------------------------
	
	// Signals
	wire [9:0] tile_address;
	wire [(color_depth - 1):0] tileset0_out;
	
	// Instance declaration
/*	tile0 grass_tile (
	.address(tile_address),
	.clock(clock),
	.data(3'bx),
	.wren(1'b0),
	.q(tile0_out));
	
	tile1 sky_tile (
	.address(tile_address),
	.clock(clock),
	.data(3'bx),
	.wren(1'b0),
	.q(tile1_out));*/
	
	tileset tileset0 (
	.address(tile_address),
	.clock(clock),
	.data(9'bx),
	.wren(1'b0),
	.q(tileset0_out));
	
	//------------------------------------------
	// Location Counters
	//------------------------------------------
	
	// X tile-counter - 0-19
	
	reg tile_cnt_en_x, tile_cnt_reset_x;
	wire [4:0] tile_x;
	
	counter5b tile_counterx(
	.clock(clock),
	.cnt_en(tile_cnt_en_x),
	.sclr(tile_cnt_reset_x),
	.q(tile_x));
	
	// Y tile-counter - 0-14
	reg tile_cnt_en_y, tile_cnt_reset_y;
	wire [3:0] tile_y;
	
	counter4b tile_countery(
	.clock(clock),
	.cnt_en(tile_cnt_en_y),
	.sclr(tile_cnt_reset_y),
	.q(tile_y));

	// X drawing counter - 0-7
	reg draw_cnt_en_x, draw_cnt_reset_x;
	wire [2:0] draw_x;
	
	counter3b draw_counterx(
	.clock(clock),
	.cnt_en(draw_cnt_en_x),
	.sclr(draw_cnt_reset_x),
	.q(draw_x));
	
	// Y drawing counter - 0-8
	reg draw_cnt_en_y, draw_cnt_reset_y;
	wire [3:0] draw_y;
	
	counter4b draw_countery(
	.clock(clock),
	.cnt_en(draw_cnt_en_y),
	.sclr(draw_cnt_reset_y),
	.q(draw_y));
	
	// Actual x and y value calculations
//	assign x = (tile_x * 8) + draw_x;
//	assign y = (tile_y * 8) + draw_y;
	
	// Memory address calculations
	assign level_address = x_offset + tile_x + (tile_y * tilemap_length);
//	assign tile_address = (draw_x + (draw_y * 4'd8)) + 1;
	
	//------------------------------------------
	// PickTile State Machine
	//------------------------------------------
	
	// Signals -- always reg
	reg done_output;
	assign done = done_output;
	reg [(color_depth - 1):0] color_output;
	assign color = color_output;
	
	// PickTile state flipflops
	reg [2:0] p_Q, p_D;
	always @ (posedge clock or negedge resetn)
	begin: picktile_state_FFs
		if (!resetn)
			p_Q <= 3'b0;
		else
			p_Q <= p_D;
	end
	
	// PickTile State Machine
	// Picks which tile to draw at which location by reading from a tilemap
	parameter WAIT_PT = 0, READ_PT = 1, DRAW_PT_0 = 2, DRAW_PT_1 = 3, CHECK_PT = 4, INCREMENT_PT = 5, DROP_PT = 6; //states
	always @ (*)
	begin: picktile_state_table
		case (p_Q)
 			WAIT_PT: if (enable) p_D <= READ_PT;
 			else p_D <= WAIT_PT;
 			READ_PT: if (tile_code == 0) p_D <= DRAW_PT_0;
 			else /*(tile_code == 1)*/ p_D <= DRAW_PT_1;
 			DRAW_PT_0: if (drawDone == 1) p_D <= CHECK_PT;
 			else p_D <= DRAW_PT_0;
 			DRAW_PT_1: if (drawDone == 1) p_D <= CHECK_PT;
 			else p_D <= DRAW_PT_1;
			// Stop at 19, because we draw before we check
 			CHECK_PT: if (tile_x == 19) p_D <= DROP_PT;
 			else p_D <= INCREMENT_PT;
 			INCREMENT_PT: p_D <= READ_PT;
 			DROP_PT: if (tile_y == 15) p_D <= WAIT_PT;
 			else p_D <= READ_PT;
/*                  WAIT_PT: if (enable) p_D <= READ_PT;
                  else p_D <= WAIT_PT;
                  INCREMENT_PT: if (tile_x == 20) p_D <= DROP_PT;
                  else p_D <= READ_PT;
                  READ_PT: if (tile_code == 0) p_D <= DRAW_PT_0;
                  else p_D <= DRAW_PT_1;
                  DROP_PT: if (tile_y == 15) p_D <= WAIT_PT;
                  else p_D <= READ_PT;
                  DRAW_PT_0: if (drawDone == 1) p_D <= INCREMENT_PT;
                  else p_D <= DRAW_PT_0;
                  DRAW_PT_1: if (drawDone == 1) p_D <= INCREMENT_PT;
                  else p_D <= DRAW_PT_1;*/
			default: p_D <= 'bx;
		endcase
	end
	
	// PickTile Datapath
	always @ (*)
	begin: picktile_datapath
		case (p_D)
			WAIT_PT: 		begin done_output = 1'b1; tile_cnt_en_x = 1'b0; tile_cnt_en_y = 1'b0; tile_cnt_reset_x = 1'b1; tile_cnt_reset_y = 1'b1; draw = 1'b0; color_output = 3'bx; end
			CHECK_PT: 		begin done_output = 1'b0; tile_cnt_en_x = 1'b0; tile_cnt_en_y = 1'b0; tile_cnt_reset_x = 1'b0; tile_cnt_reset_y = 1'b0; draw = 1'b0; color_output = 3'bx; end
			INCREMENT_PT:	begin done_output = 1'b0; tile_cnt_en_x = 1'b1; tile_cnt_en_y = 1'b0; tile_cnt_reset_x = 1'b0; tile_cnt_reset_y = 1'b0; draw = 1'b0; color_output = 3'bx; end
			READ_PT:		begin done_output = 1'b0; tile_cnt_en_x = 1'b0; tile_cnt_en_y = 1'b0; tile_cnt_reset_x = 1'b0; tile_cnt_reset_y = 1'b0; draw = 1'b0; color_output = 3'bx; end
			DROP_PT:		begin done_output = 1'b0; tile_cnt_en_x = 1'b0; tile_cnt_en_y = 1'b1; tile_cnt_reset_x = 1'b1; tile_cnt_reset_y = 1'b0; draw = 1'b0; color_output = 3'bx; end
			DRAW_PT_0: 		begin done_output = 1'b0; tile_cnt_en_x = 1'b0; tile_cnt_en_y = 1'b0; tile_cnt_reset_x = 1'b0; tile_cnt_reset_y = 1'b0; draw = 1'b1; color_output = tile0_out; end
			DRAW_PT_1: 		begin done_output = 1'b0; tile_cnt_en_x = 1'b0; tile_cnt_en_y = 1'b0; tile_cnt_reset_x = 1'b0; tile_cnt_reset_y = 1'b0; draw = 1'b1; color_output = tile1_out; end
			default: 		begin done_output = 1'bx; tile_cnt_en_x = 1'bx; tile_cnt_en_y = 1'bx; tile_cnt_reset_x = 1'bx; tile_cnt_reset_y = 1'bx; draw = 1'bx; color_output = 3'bx; end
		endcase
	end
	
	// drawTile instantiation
	
	wire draw, drawDone;
	
	drawTile drawTileInst1 (
	.Xin(tile_x * 8), 
	.Yin(tile_y * 8),
	.TileSel(tile_code), 
	.Enable(draw), 
	.Clock(clock), 
	.Resetn(resetn), 
	.DataIn(color_output), 
	.Address(tile_address), 
	.X(x), 
	.Y(y), 
	.Color(color), 
	.VGA_Draw(plot),
	.Done(drawDone));
	
endmodule
