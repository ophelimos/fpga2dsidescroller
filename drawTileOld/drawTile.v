module drawTile(draw, drawDone, plot, clock, resetn, draw_x, draw_y, y_D, y_Q);
	input draw, clock, resetn;
	output [7:0] draw_x;
	output [6:0] draw_y;
	output drawDone, plot;
	output [1:0] y_D, y_Q;
	
	// X drawing counter - 0-7
	reg draw_cnt_en_x, draw_cnt_reset_x;
	wire [2:0] draw_x;
	
	counter3b draw_counterx(
	.clock(clock),
	.cnt_en(draw_cnt_en_x),
	.sclr(draw_cnt_reset_x),
	.q(draw_x));
	
	// Y drawing counter - 0-7
	reg draw_cnt_en_y, draw_cnt_reset_y;
	wire [3:0] draw_y;
	
	counter4b draw_countery(
	.clock(clock),
	.cnt_en(draw_cnt_en_y),
	.sclr(draw_cnt_reset_y),
	.q(draw_y));

	//------------------------------------------
	// 8x8 Tile Drawing State Machine
	//------------------------------------------
	
	// Signals --- always reg
	wire draw;
	reg drawDone;
	reg plot_output;
	assign plot = plot_output;
	
	// State flipflops for tile drawing machine
	reg [2:0] y_Q, y_D;
	always @ (posedge clock or negedge resetn)
	begin: pixel_state_FFs
		if (!resetn)
			y_Q <= 2'b00;
		else
			y_Q <= y_D;
	end

	// 8x8 pixel drawing State Machine
	// Simply draws a 8x8 bitmap onto the screen at a location
	parameter WAIT_TILE = 2'b00, DRAW_TILE = 2'b01, DROP_TILE = 2'b10, INCREMENTX_TILE = 2'b11;//states
	always @ (*)
	begin: pixel_state_table
		case (y_Q)
			WAIT_TILE: if (draw == 1) y_D <= DRAW_TILE;
			else y_D <= WAIT_TILE;
			DRAW_TILE: if (draw_x == 3'd7) y_D <= DROP_TILE;
			else y_D <= INCREMENTX_TILE;
			INCREMENTX_TILE: y_D <= DRAW_TILE;
			DROP_TILE: if (draw_y == 3'd7) y_D <= WAIT_TILE;
			else y_D <= DRAW_TILE;
			default: y_D <= 2'bx;
		endcase
	end	
			
	// 8x8 pixel drawing State Machine Datapath
	always @ (y_D)
	begin: pixel_datapath
		case (y_D)
			WAIT_TILE: 			begin 	drawDone = 1'b1; plot_output = 1'b0; draw_cnt_en_x = 1'b0; draw_cnt_en_y = 1'b0; draw_cnt_reset_x = 1'b1; draw_cnt_reset_y = 1'b1; end
			DROP_TILE: 			begin 	drawDone = 1'b0; plot_output = 1'b0; draw_cnt_en_x = 1'b0; draw_cnt_en_y = 1'b1; draw_cnt_reset_x = 1'b1; draw_cnt_reset_y = 1'b0; end
			DRAW_TILE: 			begin 	drawDone = 1'b0; plot_output = 1'b1; draw_cnt_en_x = 1'b0; draw_cnt_en_y = 1'b0; draw_cnt_reset_x = 1'b0; draw_cnt_reset_y = 1'b0; end
			INCREMENTX_TILE: 	begin 	drawDone = 1'b0; plot_output = 1'b0; draw_cnt_en_x = 1'b1; draw_cnt_en_y = 1'b0; draw_cnt_reset_x = 1'b0; draw_cnt_reset_y = 1'b0; end
			default: 			begin 	drawDone = 1'bx; plot_output = 1'bx; draw_cnt_en_x = 1'bx; draw_cnt_en_y = 1'bx; draw_cnt_reset_x = 1'bx; draw_cnt_reset_y = 1'bx; end
		endcase
	end
	
endmodule