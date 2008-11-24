module characterMovement(clock, resetn, enable, y_position_in, jump, left_blocked, right_blocked, up_blocked, down_blocked, x_position, y_position, jumping_Q, jumping_D, jump_factor);
	//------------------------------------------
	// Inputs
	//------------------------------------------
	input clock;
	input enable;
	input resetn;
	input [7:0] y_position_in;
	input jump;
	input left_blocked;
	input right_blocked;
	input up_blocked;
	input down_blocked;
	//------------------------------------------
	// Outputs
	//------------------------------------------
	output [7:0] x_position; // Adjust location on-screen, in pixels
	output [7:0] y_position;
	output [1:0] jumping_Q, jumping_D;
	output [5:0] jump_factor;
	
	// Character x position (probably fixed permanently)	
	assign x_position = 8'd72;	// Right around the center (in pixels)
	
	//------------------------------------------
	// Jumping counter
	//------------------------------------------
	
	wire stop_jump;
	wire slow_jump;
	wire [5:0] jump_factor;
	reg jump_reset_out;
	wire jump_reset;
	assign jump_reset = jump_reset_out;
	
	always @(*)
		if (~resetn || stop_jump)
			jump_reset_out = 1;
		else
			jump_reset_out = 0;
	
	counter4bdown jump_rate_counter (
	.clock(clock),
	.cnt_en(slow_jump),
	.sclr(jump_reset),
	.sset(jump),
	.q(jump_factor));
	
	//------------------------------------------
	// Jumping State Machine
	//------------------------------------------
	
	// Signals -- always reg
	reg stop_jump_out;
	assign stop_jump = stop_jump_out;
	reg slow_jump_out;
	assign slow_jump = slow_jump_out;
	
	// Jumping State flipflops
	reg [1:0] jumping_Q, jumping_D; 
	always @ (posedge clock or negedge resetn)
	begin: jumping_state_FFs
		if (!resetn)
			jumping_Q <= 0;
		else
			jumping_Q <= jumping_D;
	end
	
	// Jumping State Machine
	parameter WAIT = 0, SLOW_DOWN = 1, HIT_GROUND = 2;//states
	always @ (*)
	begin: jumping_state_table
		case (jumping_Q)
			WAIT: if (jump == 1) jumping_D <= SLOW_DOWN;
			else jumping_D <= WAIT;
			SLOW_DOWN: if (down_blocked == 1) jumping_D <= HIT_GROUND;
			else if (jump_factor == 0) jumping_D <= WAIT;
			else jumping_D <= SLOW_DOWN;
			HIT_GROUND: jumping_D <= WAIT;
			default: jumping_D <= 2'bx;
		endcase
	end
	
	// Jumping Datapath
	always @ (*)
	begin: jumping_datapath
		case (jumping_Q)
			WAIT: 
				begin
					stop_jump_out = 0;
					slow_jump_out = 0;
				end
			SLOW_DOWN: 
				begin
					stop_jump_out = 0;
					slow_jump_out = 1;
				end
			HIT_GROUND: 
				begin
					stop_jump_out = 1;
					slow_jump_out = 0;
				end
			default:
				begin
					stop_jump_out = 1'bx;
					slow_jump_out = 1'bx;
				end
			endcase
	end
	
	//------------------------------------------
	// The big calculation
	//------------------------------------------

	// Remember, up = negative, down = positive
	parameter fall_speed = 2;
	
	reg [7:0] y_position_change;
	assign y_position = y_position_change;
	
	always @(*)
		if (up_blocked == 0 && down_blocked == 0)
			y_position_change = y_position_in + fall_speed - jump_factor;
		else if (up_blocked == 0 && down_blocked == 1)
			y_position_change = y_position_in - jump_factor;
		else if (up_blocked == 1 && down_blocked == 0)
			y_position_change = y_position_in + fall_speed;
		else
			y_position_change = y_position_in;

endmodule
