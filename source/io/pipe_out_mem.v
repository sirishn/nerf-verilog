`timescale 1ns / 1ps

module pipe_out_mem(	
	input  wire				  test_clk,
	input  wire            pipe_clk,
	input  wire            reset1,
	input  wire            pipe_out_read,
	input wire [31:0]	Ia_pps,
	input wire [31:0]	II_pps,
	output reg [15:0]     pipe_out_data,
	output reg [15:0]	pipe2_out_data,
	output reg          pipe_out_valid,
	output reg	    pipe_out_complete
    );
	 
	 //assign pipe_out_valid = 1;
	reg [31:0] mem [1023:0];
	reg [31:0] mem2 [1023:0];
	reg [10:0] index;

	always @ (posedge test_clk or posedge reset1)
	if (reset1)
		begin
		index <=0;
		pipe_out_valid <= 0;
		end
	else
		begin
		if (index <= 11'd1023)
			begin
			mem[index] <= Ia_pps;
			mem2[index] <= II_pps;
			if (index == 11'd1023) begin
				//index <= 0;
				index <= index + 1;
                pipe_out_valid <= 1;
				end
			else index <= index + 1;
			end
		end
		
	wire [31:0] pipe_data, pipe2_data;
	reg pipe_flag;
	reg [10:0] pipe_index;
	assign pipe_data = mem[pipe_index];
	assign pipe2_data = mem2[pipe_index];
	always @ (posedge pipe_clk or posedge reset1)
	begin
		if (reset1)
			begin
			pipe_index <= 0;
			pipe_flag <= 0;
			pipe_out_complete <= 0;
			end
		else if (pipe_out_read)
			begin
			if (pipe_index <= 11'd1023)
				begin
				if (~pipe_flag)
					begin
					pipe_out_data <= pipe_data[15:0];
					pipe2_out_data <= pipe2_data[15:0];
					pipe_flag <= ~pipe_flag;
					end
				else
					begin
					pipe_out_data <= pipe_data[31:16];
					pipe2_out_data <= pipe2_data[15:0];
					pipe_flag <= ~pipe_flag;
					if (pipe_index == 11'd1023) begin
						pipe_index <= 0;
						
                        pipe_out_complete <= 1;
						end
					else pipe_index <= pipe_index + 1; 
					end
				end
			end
	end
		
		

endmodule

