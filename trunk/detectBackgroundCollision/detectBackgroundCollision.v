module drawBackground(resetn, clock, enable, x_location, y_location, memory_input, memory_address, left, right, up, down);
   //------------------------------------------
   // Parameters
   //------------------------------------------
   parameter tilemap_length = 100; // In tiles
   //------------------------------------------
   // Inputs
   //------------------------------------------
   input clock;
   input [(tilemap_length / 15):0] x_location; // In tiles
   input [3:0]                     y_location;
   input                           enable;
   input                           resetn;
   input [2:0]                     memory_input;
   //------------------------------------------
   // Outputs
   //------------------------------------------
   output [14:0]                   memory_address;
   output                          left;
   output                          right;
   output                          up;
   output                          down;

   //------------------------------------------
   // Output Flipflops
   //------------------------------------------

   //------------------------------------------
   // Output collision detection
   //------------------------------------------
   
   //------------------------------------------
   // drawBackgroundCollision State Machine
   //------------------------------------------
   
   // Signals -- always reg
   reg                                   done_output;
   assign done = done_output;
   
   // drawBackgroundCollision state flipflops
   reg [2:0]                             dbc_Q, dbc_D;
   always @ (posedge clock or negedge resetn)
     begin: drawBackgroundCollision_state_FFs
	if (!resetn)
	  dbc_Q <= 3'b0;
	else
	  dbc_Q <= dbc_D;
     end
   
   // drawBackgroundCollision State Machine
   // Picks which tile to draw at which location by reading from a tilemap
   parameter WAIT_DBC = 0, READ_DBC = 1, DRAW_DBC = 2, CHECK_DBC = 4, INCREMENT_DBC = 5, DROP_DBC = 6; //states
   always @ (*)
     begin: drawBackgroundCollision_state_table
	case (dbc_Q)
 	  WAIT_DBC: if (enable) dbc_D <= READ_DBC;
 	  else dbc_D <= WAIT_DBC;
 	  READ_DBC: if (tile_code == 0) dbc_D <= DRAW_DBC_0;
 	  else /*(tile_code == 1)*/ dbc_D <= DRAW_DBC_1;
 	  DRAW_DBC_0: if (drawDone == 1) dbc_D <= CHECK_DBC;
 	  else dbc_D <= DRAW_DBC_0;
 	  DRAW_DBC_1: if (drawDone == 1) dbc_D <= CHECK_DBC;
 	  else dbc_D <= DRAW_DBC_1;
	  // Stop at 19, because we draw before we check
 	  CHECK_DBC: if (tile_x == 19) dbc_D <= DRODBC_DBC;
 	  else dbc_D <= INCREMENT_DBC;
 	  INCREMENT_DBC: dbc_D <= READ_DBC;
 	  DRODBC_DBC: if (tile_y == 15) dbc_D <= WAIT_DBC;
 	  else dbc_D <= READ_DBC;
	  default: dbc_D <= 'bx;
	endcase
     end
   
   // drawBackgroundCollision Datapath
   always @ (*)
     begin: drawBackgroundCollision_datapath
	case (dbc_D)
	  WAIT_DBC: 		begin done_output = 1'b1; tile_cnt_en_x = 1'b0; tile_cnt_en_y = 1'b0; tile_cnt_reset_x = 1'b1; tile_cnt_reset_y = 1'b1; draw = 1'b0; end
	  READ_DBC:		begin done_output = 1'b0; tile_cnt_en_x = 1'b0; tile_cnt_en_y = 1'b0; tile_cnt_reset_x = 1'b0; tile_cnt_reset_y = 1'b0; draw = 1'b0; end
	  DRAW_DBC: 		begin done_output = 1'b0; tile_cnt_en_x = 1'b0; tile_cnt_en_y = 1'b0; tile_cnt_reset_x = 1'b0; tile_cnt_reset_y = 1'b0; draw = 1'b1; end
	  CHECK_DBC: 		begin done_output = 1'b0; tile_cnt_en_x = 1'b0; tile_cnt_en_y = 1'b0; tile_cnt_reset_x = 1'b0; tile_cnt_reset_y = 1'b0; draw = 1'b0; end
	  INCREMENT_DBC:	begin done_output = 1'b0; tile_cnt_en_x = 1'b1; tile_cnt_en_y = 1'b0; tile_cnt_reset_x = 1'b0; tile_cnt_reset_y = 1'b0; draw = 1'b0; end
	  DRODBC_DBC:		begin done_output = 1'b0; tile_cnt_en_x = 1'b0; tile_cnt_en_y = 1'b1; tile_cnt_reset_x = 1'b1; tile_cnt_reset_y = 1'b0; draw = 1'b0; end
	  default: 		begin done_output = 1'bx; tile_cnt_en_x = 1'bx; tile_cnt_en_y = 1'bx; tile_cnt_reset_x = 1'bx; tile_cnt_reset_y = 1'bx; draw = 1'bx; end
	endcase
     end

endmodule // drawBackground
