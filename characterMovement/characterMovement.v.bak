module characterMovement(clock, resetn, enable, jump, left_blocked, right_blocked, up_blocked, down_blocked, x_position, y_position);
	//------------------------------------------
	// Inputs
	//------------------------------------------
	input clock;
	input enable;
	input resetn;
	input jump;
	input left_blocked;
	input right_blocked;
	input up_blocked;
	input down_blocked;
	//------------------------------------------
	// Outputs
	//------------------------------------------
	output [7:0] x_position; // Adjust location on-screen, in pixels
	output [6:0] y_position;
	
	// Character x position (probably fixed permanently)	
	assign x_position = 8'd72;	// Right around the center (in pixels)
	
	// Character y position
	//assign y_position = 7'd60;	// just below center on the screen (in pixels)
	
	// Position will simply be the output of a register
	// Should start at the top of the screen (0
	
	wire [6:0] y_position_in;
	
	register7b y_position_register (
	.clock(clock),
	.data(y_position_in),
	.sclr(~resetn),
	.q(y_position));
	
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
	
	counter6bdown jump_rate_counter (
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
			SLOW_DOWN: if (down_blocked) jumping_D <= HIT_GROUND;
			else if (jump_factor == 0) jumping_D <= WAIT;
			else jumping_D <= SLOW_DOWN;
			HIT_GROUND: jumping_D <= WAIT;
			default: jumping_D <= 2'bx;
		endcase
	end
	
	// Jumping Datapath
	always @ (*)
	begin: jumping_datapath
		case (jumping_D)
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

	assign y_position_in = 
	// Falling
	/*+*/( (~down_blocked) * 8 ) 
	// Jumping
	- ( (~up_blocked) * jump_factor );
	
endmodule
