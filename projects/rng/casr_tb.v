`timescale 1ns / 1ps

module casr_tb;

reg rng_clk;
reg reset;
wire [36:0] casr_out;
initial
    begin
    rng_clk = 0;
    reset = 0;
    #5 reset = 1;
    #5 reset = 0;
    end
    
always #1 rng_clk = ~rng_clk;


    casr casr_1(
      .clk(rng_clk),
      .reset(reset),
      .out(casr_out)
    );

endmodule
