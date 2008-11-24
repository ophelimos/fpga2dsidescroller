module detectBackgroundCollision(resetn, clock, enable, x_location, y_location, memory_input, memory_address, left, right, up, down, done);
   //------------------------------------------
   // Parameters
   //------------------------------------------
   parameter tilemap_length = 2000; // In tiles
   //------------------------------------------
   // Inputs
   //------------------------------------------
   input clock;
   input [10:0] x_location; // In tiles
   input [3:0]                     y_location;
   input                           enable;
   input                           resetn;
   input [3:0]                     memory_input;
   //------------------------------------------
   // Outputs
   //------------------------------------------
   output [14:0]                   memory_address;
   output                          left;
   output                          right;
   output                          up;
   output                          down;
output done;

   //------------------------------------------
   // Output Flipflops
   //------------------------------------------

reg collision;

reg left_out, left_enable;
assign left = left_out;

always @(posedge clock or negedge resetn)
	begin
		if (!resetn)
			left_out <= 0;
		else if (left_enable == 1)
			left_out <= collision;
		else
			left_out <= left_out;
	end

reg right_out, right_enable;
assign right = right_out;

always @(posedge clock or negedge resetn)
	begin
		if (!resetn)
			right_out <= 0;
		else if (right_enable == 1)
			right_out <= collision;
		else
			right_out <= right_out;
	end
	
reg up_out, up_enable;
assign up = up_out;

always @(posedge clock or negedge resetn)
	begin
		if (!resetn)
			up_out <= 0;
		else if (up_enable == 1)
			up_out <= collision;
		else
			up_out <= up_out;
	end
	
reg down_out, down_enable;
assign down = down_out;

always @(posedge clock or negedge resetn)
	begin
		if (!resetn)
			down_out <= 0;
		else if (down_enable == 1)
			down_out <= collision;
		else
			down_out <= down_out;
	end
		
   //------------------------------------------
   // Output collision detection
   //------------------------------------------

always @(*)
	begin
		if (memory_input == 4'b000)
			collision = 0;
		else
			collision = 1;
	end
   
   //------------------------------------------
   // detectBackgroundCollision State Machine
   //------------------------------------------
   
   // Signals -- always reg
   reg                                   done_output;
   assign done = done_output;
	reg [14:0] memory_address_output;
	assign memory_address = memory_address_output;
   
   // detectBackgroundCollision state flipflops
   reg [3:0]                             dbc_Q, dbc_D;
   always @ (posedge clock or negedge resetn)
     begin: detectBackgroundCollision_state_FFs
	if (!resetn)
	  dbc_Q <= 'b0;
	else
	  dbc_Q <= dbc_D;
     end
   
   // detectBackgroundCollision State Machine
   // Picks which tile to draw at which location by reading from a tilemap
   parameter WAIT_DBC = 4'd0, READ_LEFT_DBC = 4'd1, SET_LEFT_DBC = 4'd2, READ_RIGHT_DBC = 4'd3, SET_RIGHT_DBC = 4'd4, READ_UP_DBC = 4'd5, SET_UP_DBC = 4'd6, READ_DOWN_DBC = 4'd7, SET_DOWN_DBC = 4'd8, DONE_DBC = 4'd9; //states
   always @ (*)
     begin: detectBackgroundCollision_state_table
	case (dbc_Q)
 	  WAIT_DBC: if (enable) dbc_D <= READ_LEFT_DBC;
 	  else dbc_D <= WAIT_DBC;
 	  READ_LEFT_DBC: dbc_D <= SET_LEFT_DBC;
 	  SET_LEFT_DBC: dbc_D <= READ_RIGHT_DBC;
	  READ_RIGHT_DBC: dbc_D <= SET_RIGHT_DBC;
 	  SET_RIGHT_DBC: dbc_D <= READ_UP_DBC;
	  READ_UP_DBC: dbc_D <= SET_UP_DBC;
 	  SET_UP_DBC: dbc_D <= READ_DOWN_DBC;
	  READ_DOWN_DBC: dbc_D <= SET_DOWN_DBC;
 	  SET_DOWN_DBC: dbc_D <= DONE_DBC;
      DONE_DBC: if (~enable) dbc_D <= WAIT_DBC;
				else dbc_D <= DONE_DBC;
	  default: dbc_D <= 'bx;
	endcase
     end
   
   // detectBackgroundCollision Datapath
   always @ (*)
     begin: detectBackgroundCollision_datapath
	case (dbc_Q)
		WAIT_DBC: 			begin done_output = 1'b0; left_enable = 1'b0; right_enable = 1'b0; up_enable = 1'b0; down_enable = 1'b0; memory_address_output = 'bx; end
		READ_LEFT_DBC: 		begin done_output = 1'b0; left_enable = 1'b0; right_enable = 1'b0; up_enable = 1'b0; down_enable = 1'b0; memory_address_output = (x_location + 1'b1) + ( (y_location + 1'b0) * tilemap_length); end 
		SET_LEFT_DBC: 		begin done_output = 1'b0; left_enable = 1'b1; right_enable = 1'b0; up_enable = 1'b0; down_enable = 1'b0; memory_address_output = 'bx; end 
		READ_RIGHT_DBC: 	begin done_output = 1'b0; left_enable = 1'b0; right_enable = 1'b0; up_enable = 1'b0; down_enable = 1'b0; memory_address_output = (x_location - 1'b1) + ( (y_location + 1'b0) * tilemap_length); end 
		SET_RIGHT_DBC: 		begin done_output = 1'b0; left_enable = 1'b0; right_enable = 1'b1; up_enable = 1'b0; down_enable = 1'b0; memory_address_output = 'bx; end 
		READ_UP_DBC: 		begin done_output = 1'b0; left_enable = 1'b0; right_enable = 1'b0; up_enable = 1'b0; down_enable = 1'b0; memory_address_output = (x_location + 1'b0) + ( (y_location + 1'b1) * tilemap_length); end
		SET_UP_DBC: 		begin done_output = 1'b0; left_enable = 1'b0; right_enable = 1'b0; up_enable = 1'b1; down_enable = 1'b0; memory_address_output = 'bx; end
		READ_DOWN_DBC: 		begin done_output = 1'b0; left_enable = 1'b0; right_enable = 1'b0; up_enable = 1'b0; down_enable = 1'b0; memory_address_output = (x_location + 1'b0) + ( (y_location - 1'b1) * tilemap_length); end
		SET_DOWN_DBC: 		begin done_output = 1'b0; left_enable = 1'b0; right_enable = 1'b0; up_enable = 1'b0; down_enable = 1'b1; memory_address_output = 'bx; end
		DONE_DBC:			begin done_output = 1'b1; left_enable = 1'b0; right_enable = 1'b0; up_enable = 1'b0; down_enable = 1'b0; memory_address_output = 'bx; end
		default: 			begin done_output = 1'bx; left_enable = 1'bx; right_enable = 1'bx; up_enable = 1'bx; down_enable = 1'bx; memory_address_output = 'bx; end
	endcase
     end

endmodule // detectBackgroundCollision
