module AddSubNbit (ADDSUB, A, B, S, Cout);
	parameter n = 5;
	
	input [n-1:0] A, B;
	input ADDSUB;	// 0 - add, 1 - subtract
	output reg [n-1:0] S;
	output reg Cout;
	
	reg [n:0] C;
	reg [n-1:0] X;	// xor-ed input B with addsub
	
	integer i;
	
	// invert B bits if we're subtracting
	always @*
		begin
		for (i=n-1; i>=0; i=i-1)
		begin
			X[i] <= B[i] ^ ADDSUB;
		end
	end
	
	// n bit ripple carry adder
//	integer i;
	always @(ADDSUB, A, X)
	begin
		C[0] = ADDSUB;
		for (i=0; i < n; i=i+1)
		begin
			S[i] = A[i] ^ X[i] ^ C[i];
			C[i+1] = (A[i] & X[i]) | (A[i] & C[i]) | (X[i] & C[i]);
		end
		Cout = C[n];
	end
	
endmodule
