module characterMovement(clock, resetn, enable, y_position_in, jump, left_blocked, right_blocked, up_blocked, down_blocked, x_position, y_position, jumping_Q, jumping_D, jump_factor, done);
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
	output done;
	
	// Character x position (probably fixed permanently)	
	assign x_position = 8'd72;	// Right around the center (in pixels)
	
	//------------------------------------------
	// Y holding flipflop
	//------------------------------------------	
	
		// drawCharacter -> characterMovement -> normalizing logic -> drawCharacter
	// y_character_position -> characterMovement -> y_movement_position -> drawCharacter
	
	reg [7:0] y_movement_position;
	
	// Y normalizing logic
	always @(*)
		if (~resetn)
			y_movement_position = 0;
		else if (y_position_change_jumped >= 103 && y_position_change_jumped < 192)
			y_movement_position = 103; // 119-16
		else if (y_position_change_jumped >= 192 && y_position_change_jumped <= 255)
			y_movement_position = 0;
		else
			y_movement_position = y_position_change_jumped;
			
	wire [7:0] y_movement_position_reg;
	
	nBitRegister y_position_holder(
	.D(y_movement_position), 
	.Clock(clock), 
	.Q(y_position), 
	.Resetn(resetn), 
	.Enable(flipflop_update));
	defparam y_position_holder.n = 8;
	
	//------------------------------------------
	// Jumping Instantiation
	//------------------------------------------
	
	wire jumping_enable;
	wire jumping_done;
	wire [7:0] nowhere;
	
	jumpingCalc jumping_machine(
	.clock(clock), 
	.enable(jumping_enable), 
	.resetn(resetn), 
	.Yin(y_position_change),
	.up_blocked(up_blocked),
	.down_blocked(down_blocked),
	.Yout(nowhere/*y_position_change_jumped*/), 
	.done(jumping_done));
	
	assign y_position_change_jumped = y_position_change;
	//------------------------------------------
	// The big calculation
	//------------------------------------------

	// Remember, up = negative, down = positive
	parameter fall_speed = 1;
	
	reg [7:0] y_position_change;
	
	always @(*)
		if (down_blocked == 0)
			y_position_change = y_position_in + fall_speed;
		else
			y_position_change = y_position_in;

	//------------------------------------------
	// characterMovement State Machine
	//------------------------------------------
	
	// Signals -- always reg
	reg done;
	reg flipflop_update;
	
	// characterMovement State flipflops
	reg [1:0] characterMovement_Q, characterMovement_D; 
	always @ (posedge clock or negedge resetn)
	begin: characterMovement_state_FFs
		if (!resetn)
			characterMovement_Q <= 0;
		else
			characterMovement_Q <= characterMovement_D;
	end
	
	// characterMovement State Machine
	parameter WAIT_CM = 0, CALCULATE = 1, DONE = 2;//states
	always @ (*)
	begin: characterMovement_state_table
		case (characterMovement_Q)
			WAIT_CM: if (enable == 1) characterMovement_D <= CALCULATE;
			else characterMovement_D <= WAIT_CM;
			CALCULATE: characterMovement_D <= DONE;
			DONE: if (enable == 0) characterMovement_D <= WAIT_CM;
			else characterMovement_D <= DONE;
			default: characterMovement_D <= 2'bx;
		endcase
	end
	
	// characterMovement Datapath
	always @ (*)
	begin: characterMovement_datapath
		case (characterMovement_Q)
			WAIT_CM: 
				begin
					done = 0;
					flipflop_update = 0;
				end
			CALCULATE: 
				begin
					done = 0;
					flipflop_update = 1;
				end
			DONE: 
				begin
					done = 1;
					flipflop_update = 0;
				end
			default:
				begin
					done = 1'bx;
					flipflop_update = 1'bx;
				end
			endcase
	end

endmodule
