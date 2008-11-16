	//------------------------------------------
	// 8x8 Tile Drawing State Machine
	//------------------------------------------
	
	// Signals --- always reg
	reg draw;
	reg drawDone;
	reg plot_output;
	assign plot = plot_output;
	
	// State flipflops for tile drawing machine
	reg [2:0] y_Q, y_D;
	always @ (posedge clock or negedge resetn)
	begin: pixel_state_FFs
		if (!resetn)
			y_Q <= 3'd0;
		else
			y_Q <= y_D;
	end

	// 8x8 pixel drawing State Machine
	// Simply draws a 8x8 bitmap onto the screen at a location
	parameter WAIT_TILE = 0, DRAW_TILE = 1, DROP_TILE = 2, INCREMENTX_TILE = 3, READ_TILE = 4;//states
	always @ (*)
	begin: pixel_state_table
		case (y_Q)
			WAIT_TILE: if (draw == 1) y_D <= DRAW_TILE;
			else y_D <= WAIT_TILE;
			DRAW_TILE: if (draw_x == 3'd7) y_D <= DROP_TILE;
			else y_D <= INCREMENTX_TILE;
			INCREMENTX_TILE: y_D <= READ_TILE;
			DROP_TILE: if (draw_y == 4'd8) y_D <= WAIT_TILE;
			else y_D <= READ_TILE;
			READ_TILE: y_D <= DRAW_TILE;
			default: y_D <= 'bx;
		endcase
	end	
			
	// 8x8 pixel drawing State Machine Datapath
	always @ (*)
	begin: pixel_datapath
		case (y_D)
			WAIT_TILE: 			begin 	drawDone = 1'b1; plot_output = 1'b0; draw_cnt_en_x = 1'b0; draw_cnt_en_y = 1'b0; draw_cnt_reset_x = 1'b1; draw_cnt_reset_y = 1'b1; end
			DROP_TILE: 			begin 	drawDone = 1'b0; plot_output = 1'b0; draw_cnt_en_x = 1'b0; draw_cnt_en_y = 1'b1; draw_cnt_reset_x = 1'b1; draw_cnt_reset_y = 1'b0; end
			DRAW_TILE: 			begin 	drawDone = 1'b0; plot_output = 1'b1; draw_cnt_en_x = 1'b0; draw_cnt_en_y = 1'b0; draw_cnt_reset_x = 1'b0; draw_cnt_reset_y = 1'b0; end
			INCREMENTX_TILE: 	begin 	drawDone = 1'b0; plot_output = 1'b0; draw_cnt_en_x = 1'b1; draw_cnt_en_y = 1'b0; draw_cnt_reset_x = 1'b0; draw_cnt_reset_y = 1'b0; end
			READ_TILE: 			begin 	drawDone = 1'b0; plot_output = 1'b0; draw_cnt_en_x = 1'b0; draw_cnt_en_y = 1'b0; draw_cnt_reset_x = 1'b0; draw_cnt_reset_y = 1'b0; end
			default: 			begin 	drawDone = 1'bx; plot_output = 1'bx; draw_cnt_en_x = 1'bx; draw_cnt_en_y = 1'bx; draw_cnt_reset_x = 1'bx; draw_cnt_reset_y = 1'bx; end
		endcase
	end