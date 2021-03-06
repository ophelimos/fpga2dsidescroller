module NBitTristate (in, oe, out);
	parameter n = 3;
	input [n-1:0] in;		// input
	input oe;				// output enable
	output [n-1:0] out;		// output

	genvar i;
	generate
		for (i=0; i < n ; i=i+1)
		begin: tristate_buf
			Tristate tristate_buffer (in[i], oe, out[i]);
		end
	endgenerate

endmodule

module Tristate (in, oe, out);

    input   in, oe;
    output  out;
    tri     out;

    bufif1  b1(out, in, oe);

endmodule
