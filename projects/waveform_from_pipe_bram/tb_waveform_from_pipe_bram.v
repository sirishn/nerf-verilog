`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:42:41 04/03/2012 
// Design Name: 
// Module Name:    tb_waveform_from_pipe_bram 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module tb_waveform_from_pipe_bram(
    );

reg reset;
reg pipe_clk;
reg pipe_in_write;
reg [15:0] pipe_in_data;
reg pop_clk;
wire [31:0] wave;
wire [10:0] pipe_addr;
wire [10:1] pop_addr;

initial
    begin 
        reset = 0;
        pipe_clk = 0;
        pipe_in_write = 0;
        pipe_in_data = 16'd0;
        pop_clk = 0;
        
        #2 reset = 1;
        #4 reset = 0;
        
        #4
        pipe_in_write = 1;
        pipe_in_data = 16'd0;
        #2
        pipe_in_data = 16'd1;
        #2 pipe_in_data = 16'd0;
        #2 pipe_in_data = 16'd2;
        #2 pipe_in_data = 16'd0;
        #2 pipe_in_data = 16'd3;
        #1 pipe_in_write = 0;
        
        #1 reset = 1;
        #2 reset = 0;
        
        
    end
    
always #1 pipe_clk = ~pipe_clk;
always #1 pop_clk = ~pop_clk;
    

    


 waveform_from_pipe_bram    generator(
                                .reset(reset),
                                .pipe_clk(pipe_clk),
                                .pipe_in_write(pipe_in_write),
                                .pipe_in_data(pipe_in_data),
                                .pop_clk(pop_clk),
                                .wave(wave),
                                
                                .pipe_addr(pipe_addr),
                                .pop_addr(pop_addr)
    );


endmodule
