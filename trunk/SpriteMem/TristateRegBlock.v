module TristateRegBlock (inWidth, inHeight, inAnimSteps, outWidth, outHeight, outAnimSteps, oe);
	input oe;	// output enable
	input [5:0] inWidth, inHeight;
	input [2:0] inAnimSteps;
	output [5:0] outWidth, outHeight;
	output [2:0] outAnimSteps;

	NBitTristate TriWidth (inWidth, oe, outWidth);
	defparam TriWidth.n = 6;
	NBitTristate TriHeight (inHeight, oe, outHeight);
	defparam TriHeight.n = 6;
	NBitTristate TriAnimSteps (inAnimSteps, oe, outAnimSteps);
	defparam TriAnimSteps.n = 3;

endmodule
