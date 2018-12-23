`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   10:38:28 04/09/2012
// Design Name:   izneuron
// Module Name:   /home/sirish/Documents/scratch/izneuron/tb.v
// Project Name:  izneuron
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: izneuron
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb;

	// Inputs
	reg clk;
	reg reset;
	reg [31:0] I;

	// Outputs
	wire [31:0] v;
    wire [31:0] u;
	wire spike;
    
    wire [31:0] bxvmu;
    wire [31:0] bxv;

	// Instantiate the Unit Under Test (UUT)
	izneuron uut (
		.clk(clk), 
		.reset(reset), 
		.I(I), 
		.v(v), 
        .u(u),
		.spike(spike),
        
        
        .bxv(bxv),
        .bxvmu(bxvmu)
	);

	initial begin
		// Initialize Inputs
		clk = 0;
		reset = 1;
		I = 0;

		#5;
        reset = 0;
        
		// Add stimulus here

	end
      
    always #1 clk = ~clk;
    
    
endmodule

