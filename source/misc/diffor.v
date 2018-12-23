module diffor
(
		input wire [31:0] x,
        input wire [31:0] int_x,
		output wire [31:0] out // out = x*dt + int_x
);
	

	assign out = int_x_F0;
    //assign out = 32'h3f67b7cc;
endmodule
